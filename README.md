[![Pub Version](https://img.shields.io/pub/v/lifecycle)](https://pub.dev/packages/lifecycle)
[![pub points](https://img.shields.io/pub/points/lifecycle)](https://pub.dev/packages/lifecycle)
[![likes](https://img.shields.io/pub/likes/lifecycle)](https://pub.dev/packages/lifecycle)

English | [简体中文](README_CN.md)

# lifecycle

Composable lifecycle state for Flutter widgets.

`lifecycle` combines app state, Navigator routes, paged containers, and scroll
viewports into one immutable `LifecycleSnapshot`. A descendant can only be
active when every containing scope is active:

```text
App → Navigator route → Page/Tab → Viewport item → Widget
```

There is no global observer and no event bus. Each Navigator owns an explicit
controller, nested scopes compose automatically, and callbacks receive both
the resulting snapshot and the cause of the transition.

## Lifecycle model

The current state is represented by:

```dart
LifecycleSnapshot(
  phase: LifecyclePhase.active,
  visibleFraction: 1,
  appState: AppLifecycleState.resumed,
)
```

Phases are `detached`, `hidden`, `visible`, `active`, and `disposed`. A single
phase is the single source of truth; `attached`, `visible`, and `active` are
derived getters. A single state change produces events in deterministic order:

```text
created → appeared → activated → deactivated → disappeared → disposed
```

Only events that apply to a transition are emitted. For example, hiding an
active widget emits `deactivated` and then `disappeared`.

`LifecycleTransition.cause` identifies whether the change came from the app,
a route, a back gesture, page selection, a viewport, the widget tree, or a
custom boundary.

## Installation

```yaml
dependencies:
  lifecycle: ^1.0.0
```

```dart
import 'package:lifecycle/lifecycle.dart';
```

## App and Navigator setup

Create one `NavigatorLifecycleController` per Navigator. The controller owns
its observer; dispose the controller where you create it.

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

Use a separate controller, observer, and scope for each nested Navigator. Both
imperative routes and the Navigator `pages` API are supported. Opaque routes
hide the route below; non-opaque routes such as dialogs keep it visible but
inactive. Interactive back gestures expose the previous route as visible.

Routes can also be inspected or removed through the controller:

```dart
final entry = navigation.routeNamed('/checkout');
final routes = navigation.routes;

if (entry != null) {
  navigation.removeRoute(entry.route);
}
```

## Listen from a widget

For a stateless subtree, use `LifecycleListener`:

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

For a `State`, use `LifecycleStateMixin`:

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

`LifecycleBuilder` rebuilds when any snapshot field changes, including
`visibleFraction`:

```dart
LifecycleBuilder(
  builder: (context, lifecycle) {
    return Text(lifecycle.phase.name);
  },
)
```

## Custom boundaries

Use `LifecycleBoundary` to compose domain state with the surrounding scope.
It can restrict a descendant, but it cannot make a descendant more active than
its parent.

```dart
LifecycleBoundary(
  visible: panelIsOpen,
  active: panelHasFocus,
  visibleFraction: animation.value,
  child: const Panel(),
)
```

## PageView

`LifecyclePageView` owns page scopes and forwards the usual PageView options.
The selected page becomes active only after scrolling settles. During a drag,
visible pages expose a fractional visibility and remain inactive.

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

The builder constructor supports large and reorderable data sets. Supply a
stable ID and its reverse lookup when order can change:

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

The widget deliberately does not change Flutter's keep-alive policy. A lazy
page that is disposed emits `disposed`; wrap page content with
`AutomaticKeepAliveClientMixin` when its State must survive off-screen.

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

`LifecycleTabBarView` follows both animated taps and horizontal swipes. A tab
is active only when the `TabController` is settled.

## ListView, GridView, and CustomScrollView

Place `ViewportLifecycleItem` below the nearest `Scrollable`. Visibility is
calculated from the item's two-dimensional area inside that viewport, so
vertical lists, horizontal lists, grids, and slivers share the same behavior.

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

An item is visible when its fraction reaches `visibleThreshold` and active
when it reaches `activeThreshold`. If `activeThreshold` is omitted, it uses the
visible threshold. The containing app, route, and page states still apply.

## Direct controller use

Most apps only need widgets, but `LifecycleController` is public for custom
containers. Child state is composed with its parent, listeners are safe to
add/remove during delivery, and reentrant updates are queued deterministically.

```dart
final parent = LifecycleController()..attach();
final child = LifecycleController(visible: false)
  ..attach(parent: parent);

child.updateLocal(
  visible: true,
  active: true,
  cause: LifecycleCause.custom,
);
```

See the [example application](https://github.com/chenenyu/lifecycle/tree/main/example)
and the tests for complete runnable compositions.

## 1.0 migration

Version 1.0 is a deliberate API redesign. The global
`defaultLifecycleObserver`, legacy wrapper classes, and dispatch/subscribe
mixins were removed. Replace them with explicit `LifecycleApp` and
`NavigatorLifecycleController` setup, then use `LifecycleListener`,
`LifecycleStateMixin`, `LifecyclePageView`, `LifecycleTabBarView`, and
`ViewportLifecycleItem`.
