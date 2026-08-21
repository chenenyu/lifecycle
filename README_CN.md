[![Pub Version](https://img.shields.io/pub/v/lifecycle)](https://pub.dev/packages/lifecycle)
[![pub points](https://img.shields.io/pub/points/lifecycle)](https://pub.dev/packages/lifecycle)
[![likes](https://img.shields.io/pub/likes/lifecycle)](https://pub.dev/packages/lifecycle)

[English](README.md) | 简体中文

# lifecycle

为 Flutter Widget 提供可组合的生命周期状态。

`lifecycle` 将应用状态、Navigator 路由、分页容器和滚动视口组合为一个不可变的
`LifecycleSnapshot`。只有当所有上层作用域都处于活跃状态时，后代节点才会活跃：

```text
应用 → Navigator 路由 → Page/Tab → 视口元素 → Widget
```

该库不使用全局观察者或事件总线。每个 Navigator 都拥有显式控制器，嵌套作用域会
自动组合，回调可以同时获得最终状态快照以及引发本次转换的原因。

## 生命周期模型

当前状态由以下对象表示：

```dart
LifecycleSnapshot.active(
  visibleFraction: 1,
  appState: AppLifecycleState.resumed,
)
```

生命周期阶段包括 `detached`、`hidden`、`visible`、`active` 和 `disposed`。
`phase` 是唯一状态源，`attached`、`visible` 和 `active` 均为派生 getter。
一次状态变化会按照确定的顺序产生事件：

```text
created → appeared → activated → deactivated → disappeared → disposed
```

每次转换只会发送适用的事件。例如，隐藏一个活跃 Widget 时，会先发送
`deactivated`，然后发送 `disappeared`。

`LifecycleTransition.cause` 用于标识状态变化来自应用、路由、返回手势、页面选择、
视口、Widget 树，还是自定义边界。

## 安装

```yaml
dependencies:
  lifecycle: ^1.0.0
```

```dart
import 'package:lifecycle/lifecycle.dart';
```

## 配置 App 和 Navigator

为每个 Navigator 创建一个 `NavigatorLifecycleController`。控制器拥有与之配套的
observer，并且应该在创建控制器的位置进行释放。

```dart
class AppState extends State<App> {
  final navigation = NavigatorLifecycleController();

  @override
  Widget build(BuildContext context) {
    return LifecycleApp(
      child: MaterialApp(
        navigatorObservers: [navigation.observer],
        builder: (context, child) => NavigatorLifecycleScope(
          controller: navigation,
          child: child!,
        ),
        home: const HomeScreen(),
      ),
    );
  }

  @override
  void dispose() {
    navigation.dispose();
    super.dispose();
  }
}
```

每个嵌套 Navigator 都需要独立的 controller、observer 和 scope。该库同时支持命令式
路由和 Navigator `pages` API。不透明路由会隐藏其下方的路由；Dialog 等非透明路由
会让下方路由保持可见，但不再活跃。交互式返回手势执行期间，前一个路由会变为可见。

还可以通过控制器检查或删除路由：

```dart
final route = navigation.routeNamed('/checkout');
final routes = navigation.routes;

if (route != null) {
  final lifecycle = navigation.lifecycleFor(route);
  debugPrint('checkout: ${lifecycle?.phase}');
  navigation.removeRoute(route);
}
```

## 在 Widget 中监听

对于无状态子树，可以使用 `LifecycleListener`：

```dart
LifecycleListener(
  onTransition: (transition) {
    debugPrint('${transition.previous.phase} → ${transition.current.phase}');
  },
  onEvent: (event, transition) {
    debugPrint('${event.name} (${transition.cause.name})');
  },
  child: const Content(),
)
```

对于 `State`，可以使用 `LifecycleStateMixin`：

```dart
class ArticleState extends State<Article> with LifecycleStateMixin<Article> {
  @override
  void onLifecycleEvent(
    LifecycleEvent event,
    LifecycleTransition transition,
  ) {
    if (event == LifecycleEvent.activated) {
      refreshArticle();
    }
  }

  @override
  Widget build(BuildContext context) => const ArticleView();
}
```

当状态快照中的任意字段发生变化时，`LifecycleBuilder` 都会重新构建，其中也包括
`visibleFraction`：

```dart
LifecycleBuilder(
  builder: (context, lifecycle) {
    return Text(lifecycle.phase.name);
  },
)
```

## 自定义生命周期边界

使用 `LifecycleBoundary` 可以将业务状态与上层生命周期作用域组合。它可以限制后代
节点的状态，但不能让后代节点比父节点更加活跃。

```dart
LifecycleBoundary(
  constraint: !panelIsOpen || animation.value <= 0
      ? const LifecycleConstraint.hidden()
      : panelHasFocus
          ? LifecycleConstraint.active(visibleFraction: animation.value)
          : LifecycleConstraint.visible(visibleFraction: animation.value),
  child: const Panel(),
)
```

## PageView

`LifecyclePageView` 负责管理页面作用域，并转发常用的 PageView 配置。只有滚动完全
停止后，选中的页面才会进入活跃状态。拖动期间，可见页面会提供分数形式的可见比例，
但保持非活跃状态。

```dart
final controller = PageController(initialPage: 1);

LifecyclePageView(
  controller: controller,
  onPageTransition: (index, transition) {
    debugPrint('page $index: ${transition.events}');
  },
  children: const [
    FeedPage(key: ValueKey('feed')),
    SearchPage(key: ValueKey('search')),
  ],
)
```

builder 构造函数适用于大型或可重新排序的数据集。当数据顺序可能变化时，需要同时
提供稳定 ID 以及从 ID 反查当前索引的方法：

```dart
LifecyclePageView.builder(
  controller: controller,
  itemCount: items.length,
  pageIdBuilder: (index) => items[index].id,
  findPageIndex: (id) => items.indexWhere((item) => item.id == id),
  itemBuilder: (context, index) => ItemPage(
    key: ValueKey(items[index].id),
    item: items[index],
  ),
)
```

该组件不会改变 Flutter 原有的 keep-alive 策略。被释放的懒加载页面会发送
`disposed`。如果页面 State 必须在离开屏幕后继续保留，请在页面内容中使用
`AutomaticKeepAliveClientMixin`。

## TabBarView

```dart
LifecycleTabBarView(
  controller: tabController,
  onTabTransition: (index, transition) {
    debugPrint('tab $index: ${transition.events}');
  },
  children: const [OverviewTab(), ActivityTab()],
)
```

`LifecycleTabBarView` 同时支持点击产生的切换动画和水平滑动。只有当
`TabController` 完全停止后，对应 Tab 才会活跃。

## ListView、GridView 和 CustomScrollView

将 `ViewportLifecycleItem` 放置在距离它最近的 `Scrollable` 之下。可见性根据元素
在视口内的二维面积计算，因此垂直列表、水平列表、网格和 Sliver 使用相同的行为模型。

```dart
ListView.builder(
  itemCount: items.length,
  itemBuilder: (context, index) => ViewportLifecycleItem(
    visibleThreshold: 0.25,
    activeThreshold: 0.8,
    onTransition: (transition) {
      debugPrint('item $index: ${transition.current.visibleFraction}');
    },
    child: ItemTile(item: items[index]),
  ),
)
```

元素的可见比例达到 `visibleThreshold` 时会变为可见，达到 `activeThreshold` 时会
变为活跃。如果没有指定 `activeThreshold`，则使用可见阈值。外层应用、路由和页面
的生命周期状态仍然会参与最终状态计算。

## 直接使用控制器

大多数应用只需要使用 Widget API，但该库也公开了 `LifecycleController`，用于实现
自定义容器。子节点状态会与父节点组合；事件发送期间可以安全地增加或删除监听器；
重入更新会按照确定的顺序排队执行。

```dart
final parent = LifecycleController()..attach();
final child = LifecycleController(
  constraint: const LifecycleConstraint.hidden(),
);

void onChildChanged() {
  final transition = child.lastTransition!;
  debugPrint('${transition.previous.phase} -> ${transition.current.phase}');
}

child
  ..addListener(onChildChanged)
  ..attach(parent: parent);

child.updateLocal(
  constraint: const LifecycleConstraint.active(),
  cause: LifecycleCause.custom,
);

final subtree = LifecycleScope(
  controller: child,
  child: const CustomContainerContent(),
);
```

`LifecycleController` 使用标准 `ChangeNotifier` 通道统一发送快照和 transition
变化。在监听回调中，`value` 是最新快照，`lastTransition` 描述产生该快照的原子
变化。如果监听器可能比 controller 存活更久，请及时调用 `removeListener`。

可以查看[示例应用](https://github.com/chenenyu/lifecycle/tree/main/example)和测试代码，
了解完整且可运行的组合方式。

## 1.0 迁移说明

1.0 是一次有意进行的 API 重新设计。全局 `defaultLifecycleObserver`、旧 wrapper 类，
以及 dispatch/subscribe mixin 均已移除。请改为显式配置 `LifecycleApp` 和
`NavigatorLifecycleController`，并使用 `LifecycleListener`、
`LifecycleStateMixin`、`LifecyclePageView`、`LifecycleTabBarView` 和
`ViewportLifecycleItem`。
