/*
 * LifecyclePageView 与 LifecycleTabBarView 的 Widget 测试。
 *
 * 覆盖初始索引、拖动 settle、Controller 迁移、稳定 ID 重排、itemCount 收缩和嵌套页面，
 * 防止可见比例、选中状态与懒构建页面身份在动画或数据变化时错位。
 */
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifecycle/lifecycle.dart';

import 'test_support.dart';

void main() {
  group('LifecyclePageView', () {
    // 验证 PageView 的方向、reverse 和 padEnds 配置完整转发到底层 Flutter PageView。
    testWidgets('forwards layout configuration to PageView', (tester) async {
      final controller = PageController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        lifecycleTestApp(
          home: SizedBox(
            height: 400,
            child: LifecyclePageView(
              controller: controller,
              scrollDirection: Axis.vertical,
              reverse: true,
              padEnds: false,
              children: const [Text('Only page')],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final pageView = tester.widget<PageView>(find.byType(PageView));
      expect(pageView.scrollDirection, Axis.vertical);
      expect(pageView.reverse, isTrue);
      expect(pageView.padEnds, isFalse);
    });

    // 验证空数据源不会访问不存在的 page 或产生越界约束，便于异步列表加载前安全占位。
    testWidgets('supports an empty page collection', (tester) async {
      final controller = PageController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        lifecycleTestApp(
          home: Scaffold(
            body: LifecyclePageView(controller: controller, children: const []),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(PageView), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    // 验证 initialPage 决定初始活跃页，切换后只有最终选中页处于 active。
    testWidgets('honors initialPage and activates only the selected page', (
      tester,
    ) async {
      final log = LifecycleEventLog();
      final fixtureKey = GlobalKey<_PageFixtureState>();

      await tester.pumpWidget(
        lifecycleTestApp(
          home: Scaffold(
            body: _PageFixture(key: fixtureKey, initialPage: 1, log: log),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(log['page1'], createdAndActive);
      expect(log['page0'], isNot(contains(LifecycleEvent.activated)));
      log.clear();

      fixtureKey.currentState!.jumpToPage(0);
      await tester.pumpAndSettle();

      expect(log['page1'], contains(LifecycleEvent.deactivated));
      expect(log['page0'], contains(LifecycleEvent.activated));
    });

    // 验证滚动动画期间相邻页面可以可见但都不活跃，停止后才激活目标页。
    testWidgets('keeps pages visible but inactive while scrolling', (
      tester,
    ) async {
      final log = LifecycleEventLog();
      final fixtureKey = GlobalKey<_PageFixtureState>();

      await tester.pumpWidget(
        lifecycleTestApp(
          home: Scaffold(
            body: _PageFixture(key: fixtureKey, initialPage: 0, log: log),
          ),
        ),
      );
      await tester.pumpAndSettle();
      log.clear();

      fixtureKey.currentState!.animateToPage(1);
      await tester.pump(const Duration(milliseconds: 100));

      expect(log['page0'], contains(LifecycleEvent.deactivated));
      expect(log['page1'], isNot(contains(LifecycleEvent.activated)));

      await tester.pumpAndSettle();
      expect(log['page1'], contains(LifecycleEvent.activated));
      expect(log['page0'], contains(LifecycleEvent.disappeared));
    });

    // 验证 builder 模式按需创建 initialPage，并使用稳定 page ID 包装页面。
    testWidgets('supports builder construction and stable page IDs', (
      tester,
    ) async {
      final controller = PageController(initialPage: 2);
      addTearDown(controller.dispose);
      final builtIndexes = <int>[];
      final log = LifecycleEventLog();

      await tester.pumpWidget(
        lifecycleTestApp(
          home: Scaffold(
            body: LifecyclePageView.builder(
              controller: controller,
              itemCount: 3,
              pageIdBuilder: (index) => 'page-$index',
              itemBuilder: (context, index) {
                builtIndexes.add(index);
                return LifecycleProbe(
                  key: ValueKey('content-$index'),
                  name: 'builder$index',
                  log: log,
                  child: Text('Builder $index'),
                );
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(builtIndexes, contains(2));
      expect(log['builder2'], createdAndActive);
      expect(find.text('Builder 2'), findsOneWidget);
    });

    // 验证数据重排后通过稳定 ID 找回新索引，保留原页面 State 而非重新创建。
    testWidgets('preserves keyed builder pages when data is reordered', (
      tester,
    ) async {
      final fixtureKey = GlobalKey<_ReorderablePageFixtureState>();

      await tester.pumpWidget(
        lifecycleTestApp(
          home: Scaffold(body: _ReorderablePageFixture(key: fixtureKey)),
        ),
      );
      await tester.pumpAndSettle();

      final before =
          tester.widget<Text>(find.byKey(const ValueKey('identity-a'))).data;
      fixtureKey.currentState!.reorder();
      await tester.pumpAndSettle();
      fixtureKey.currentState!.showPage(1);
      await tester.pumpAndSettle();

      expect(
        tester.widget<Text>(find.byKey(const ValueKey('identity-a'))).data,
        before,
      );
    });

    // 验证 itemCount 缩小时选中索引会被修正，并激活仍然存在的页面。
    testWidgets('activates the remaining page when itemCount shrinks', (
      tester,
    ) async {
      final log = LifecycleEventLog();
      final fixtureKey = GlobalKey<_ShrinkingPageFixtureState>();

      await tester.pumpWidget(
        lifecycleTestApp(
          home: Scaffold(
            body: _ShrinkingPageFixture(key: fixtureKey, log: log),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(log['shrinking1'], createdAndActive);
      log.clear();

      fixtureKey.currentState!.removeSelectedPage();
      await tester.pumpAndSettle();

      expect(log['shrinking0'], contains(LifecycleEvent.activated));
    });

    // 验证替换 PageController 后会解绑旧监听、绑定新监听并继续正确切换生命周期。
    testWidgets('migrates listeners when PageController changes', (
      tester,
    ) async {
      final log = LifecycleEventLog();
      final fixtureKey = GlobalKey<_SwappablePageFixtureState>();

      await tester.pumpWidget(
        lifecycleTestApp(
          home: Scaffold(
            body: _SwappablePageFixture(key: fixtureKey, log: log),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(log['swap0'], contains(LifecycleEvent.activated));
      log.clear();

      fixtureKey.currentState!.swapController();
      await tester.pumpAndSettle();
      fixtureKey.currentState!.showSecondPage();
      await tester.pumpAndSettle();

      expect(log['swap1'], contains(LifecycleEvent.activated));
      expect(log['swap0'], contains(LifecycleEvent.deactivated));
    });

    // 验证 controller 替换和 itemCount 收缩同时发生时，索引会收敛且剩余页仍能 active。
    testWidgets('combines PageController replacement with item shrink', (
      tester,
    ) async {
      final fixtureKey = GlobalKey<_CombinedPageFixtureState>();
      final log = LifecycleEventLog();

      await tester.pumpWidget(
        lifecycleTestApp(
          home: Scaffold(
            body: _CombinedPageFixture(key: fixtureKey, log: log),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(log['combined1'], createdAndActive);
      log.clear();

      fixtureKey.currentState!.swapAndShrink();
      await tester.pumpAndSettle();

      expect(log['combined0'], contains(LifecycleEvent.activated));
      expect(find.text('Combined 0'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    // 验证 Dialog 下切换 Page 时目标页只能 visible，必须等 Route 恢复后才能 active。
    testWidgets('inherits inactive route state when changed behind a dialog', (
      tester,
    ) async {
      final navigation = NavigatorLifecycleController();
      addTearDown(navigation.dispose);
      final navigatorKey = GlobalKey<NavigatorState>();
      final fixtureKey = GlobalKey<_PageFixtureState>();
      final log = LifecycleEventLog();

      await tester.pumpWidget(
        lifecycleTestApp(
          navigation: navigation,
          navigatorKey: navigatorKey,
          home: Scaffold(
            body: _PageFixture(key: fixtureKey, initialPage: 0, log: log),
          ),
        ),
      );
      await tester.pumpAndSettle();

      showDialog<void>(
        context: navigatorKey.currentContext!,
        builder: (_) => const AlertDialog(content: Text('Dialog')),
      );
      await tester.pumpAndSettle();
      log.clear();

      fixtureKey.currentState!.jumpToPage(1);
      await tester.pumpAndSettle();

      expect(log['page1'], contains(LifecycleEvent.appeared));
      expect(log['page1'], isNot(contains(LifecycleEvent.activated)));
      log.clear();

      navigatorKey.currentState!.pop();
      await tester.pumpAndSettle();
      expect(log['page1'], [LifecycleEvent.activated]);
    });
  });

  group('LifecycleTabBarView', () {
    // 验证初始 Tab 和 TabController 切换会正确迁移 active 状态。
    testWidgets('honors initial index and follows TabController', (
      tester,
    ) async {
      final log = LifecycleEventLog();
      final fixtureKey = GlobalKey<_TabFixtureState>();

      await tester.pumpWidget(
        lifecycleTestApp(
          home: _TabFixture(key: fixtureKey, log: log),
        ),
      );
      await tester.pumpAndSettle();

      expect(log['tab1'], createdAndActive);
      expect(log['tab0'], isNot(contains(LifecycleEvent.activated)));
      log.clear();

      fixtureKey.currentState!.showFirstTab();
      await tester.pumpAndSettle();

      expect(log['tab1'], contains(LifecycleEvent.deactivated));
      expect(log['tab0'], contains(LifecycleEvent.activated));
    });

    // 验证 Tab 点击动画的中间帧只让相邻页 visible，目标页必须等动画 settle 后才 active。
    testWidgets('keeps adjacent tabs inactive during controller animation', (
      tester,
    ) async {
      final log = LifecycleEventLog();
      final fixtureKey = GlobalKey<_TabFixtureState>();

      await tester.pumpWidget(
        lifecycleTestApp(
          home: _TabFixture(key: fixtureKey, log: log),
        ),
      );
      await tester.pumpAndSettle();
      log.clear();

      fixtureKey.currentState!.showFirstTab();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(log['tab1'], contains(LifecycleEvent.deactivated));
      expect(log['tab0'], contains(LifecycleEvent.appeared));
      expect(log['tab0'], isNot(contains(LifecycleEvent.activated)));

      await tester.pumpAndSettle();
      expect(log['tab0'], contains(LifecycleEvent.activated));
    });

    // 验证替换 TabController 时动画和状态监听器随之迁移，不再响应旧 controller。
    testWidgets('migrates listeners when TabController changes', (
      tester,
    ) async {
      final log = LifecycleEventLog();
      final fixtureKey = GlobalKey<_SwappableTabFixtureState>();

      await tester.pumpWidget(
        lifecycleTestApp(
          home: _SwappableTabFixture(key: fixtureKey, log: log),
        ),
      );
      await tester.pumpAndSettle();
      expect(log['swapTab0'], contains(LifecycleEvent.activated));
      log.clear();

      fixtureKey.currentState!.swapController();
      await tester.pumpAndSettle();

      expect(log['swapTab0'], contains(LifecycleEvent.deactivated));
      expect(log['swapTab1'], contains(LifecycleEvent.activated));
    });
  });

  group('nested page scopes', () {
    // 验证外层 Page 隐藏时状态会继续向内层 PageView 传播，使当前内页同步失活。
    testWidgets('propagates outer page state into the inner PageView', (
      tester,
    ) async {
      final log = LifecycleEventLog();
      final fixtureKey = GlobalKey<_NestedPageFixtureState>();

      await tester.pumpWidget(
        lifecycleTestApp(
          home: Scaffold(
            body: _NestedPageFixture(key: fixtureKey, log: log),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(log['outer0'], createdAndActive);

      fixtureKey.currentState!.showNestedPage();
      await tester.pumpAndSettle();
      expect(log['outer1'], contains(LifecycleEvent.activated));
      expect(log['inner0'], contains(LifecycleEvent.activated));
      log.clear();

      fixtureKey.currentState!.showSecondInnerPage();
      await tester.pumpAndSettle();
      expect(log['inner0'], contains(LifecycleEvent.deactivated));
      expect(log['inner1'], contains(LifecycleEvent.activated));
      log.clear();

      fixtureKey.currentState!.showFirstOuterPage();
      await tester.pumpAndSettle();
      expect(log['outer1'], contains(LifecycleEvent.deactivated));
      expect(log['inner1'], contains(LifecycleEvent.deactivated));
    });
  });
}

/// 暴露 PageController 操作并记录各 index 事件的基础夹具。
class _PageFixture extends StatefulWidget {
  const _PageFixture({super.key, required this.initialPage, required this.log});

  final int initialPage;
  final LifecycleEventLog log;

  @override
  State<_PageFixture> createState() => _PageFixtureState();
}

class _PageFixtureState extends State<_PageFixture> {
  late final PageController _controller;

  @override
  void initState() {
    super.initState();
    _controller = PageController(initialPage: widget.initialPage);
  }

  void jumpToPage(int page) => _controller.jumpToPage(page);

  void animateToPage(int page) {
    _controller.animateToPage(
      page,
      duration: const Duration(seconds: 1),
      curve: Curves.linear,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LifecyclePageView(
      controller: _controller,
      onPageTransition: (index, transition) {
        for (final event in transition.events) {
          widget.log.add('page$index', event);
        }
      },
      children: const [
        Center(child: Text('Page 0')),
        Center(child: Text('Page 1')),
      ],
    );
  }
}

/// 使用稳定 ID 反转页面顺序的重排夹具。
class _ReorderablePageFixture extends StatefulWidget {
  const _ReorderablePageFixture({super.key});

  @override
  State<_ReorderablePageFixture> createState() =>
      _ReorderablePageFixtureState();
}

class _ReorderablePageFixtureState extends State<_ReorderablePageFixture> {
  final PageController _controller = PageController();
  List<String> _ids = ['a', 'b'];

  void reorder() => setState(() => _ids = _ids.reversed.toList());

  void showPage(int index) => _controller.jumpToPage(index);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LifecyclePageView.builder(
      controller: _controller,
      itemCount: _ids.length,
      pageIdBuilder: (index) => _ids[index],
      findPageIndex: (id) => _ids.indexOf(id as String),
      itemBuilder: (context, index) {
        final id = _ids[index];
        return _IdentityPage(key: ValueKey(id), id: id);
      },
    );
  }
}

/// 带 KeepAlive 和本地 State 的页面，用于检测身份错配。
class _IdentityPage extends StatefulWidget {
  const _IdentityPage({super.key, required this.id});

  final String id;

  @override
  State<_IdentityPage> createState() => _IdentityPageState();
}

class _IdentityPageState extends State<_IdentityPage>
    with AutomaticKeepAliveClientMixin {
  final Object _identity = Object();

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Text(
      '${widget.id}:${identityHashCode(_identity)}',
      key: ValueKey('identity-${widget.id}'),
    );
  }
}

/// 动态缩小 itemCount，验证选中索引会被安全收敛。
class _ShrinkingPageFixture extends StatefulWidget {
  const _ShrinkingPageFixture({super.key, required this.log});

  final LifecycleEventLog log;

  @override
  State<_ShrinkingPageFixture> createState() => _ShrinkingPageFixtureState();
}

class _ShrinkingPageFixtureState extends State<_ShrinkingPageFixture> {
  final PageController _controller = PageController(initialPage: 1);
  int _itemCount = 2;

  void removeSelectedPage() => setState(() => _itemCount = 1);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LifecyclePageView.builder(
      controller: _controller,
      itemCount: _itemCount,
      onPageTransition: (index, transition) {
        for (final event in transition.events) {
          widget.log.add('shrinking$index', event);
        }
      },
      itemBuilder: (context, index) => Text('Shrinking $index'),
    );
  }
}

/// 在运行时替换 PageController，验证监听器迁移。
class _SwappablePageFixture extends StatefulWidget {
  const _SwappablePageFixture({super.key, required this.log});

  final LifecycleEventLog log;

  @override
  State<_SwappablePageFixture> createState() => _SwappablePageFixtureState();
}

class _SwappablePageFixtureState extends State<_SwappablePageFixture> {
  PageController _controller = PageController(keepPage: false);

  void swapController() {
    final oldController = _controller;
    setState(
      () => _controller = PageController(initialPage: 1, keepPage: false),
    );
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => oldController.dispose(),
    );
  }

  void showSecondPage() => _controller.jumpToPage(1);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LifecyclePageView(
      controller: _controller,
      onPageTransition: (index, transition) {
        for (final event in transition.events) {
          widget.log.add('swap$index', event);
        }
      },
      children: const [Text('Swap 0'), Text('Swap 1')],
    );
  }
}

/// 同时替换 PageController 和数据长度，覆盖 didUpdateWidget 的组合更新路径。
class _CombinedPageFixture extends StatefulWidget {
  const _CombinedPageFixture({super.key, required this.log});

  final LifecycleEventLog log;

  @override
  State<_CombinedPageFixture> createState() => _CombinedPageFixtureState();
}

class _CombinedPageFixtureState extends State<_CombinedPageFixture> {
  PageController _controller = PageController(initialPage: 1);
  int _itemCount = 2;

  void swapAndShrink() {
    final oldController = _controller;
    setState(() {
      _controller = PageController(initialPage: 0, keepPage: false);
      _itemCount = 1;
    });
    WidgetsBinding.instance
        .addPostFrameCallback((_) => oldController.dispose());
  }

  @override
  Widget build(BuildContext context) {
    return LifecyclePageView.builder(
      controller: _controller,
      itemCount: _itemCount,
      onPageTransition: (index, transition) {
        for (final event in transition.events) {
          widget.log.add('combined$index', event);
        }
      },
      itemBuilder: (context, index) => Text('Combined $index'),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

/// 持有 TabController 并暴露动画切换操作的基础夹具。
class _TabFixture extends StatefulWidget {
  const _TabFixture({super.key, required this.log});

  final LifecycleEventLog log;

  @override
  State<_TabFixture> createState() => _TabFixtureState();
}

class _TabFixtureState extends State<_TabFixture>
    with SingleTickerProviderStateMixin {
  late final TabController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TabController(length: 2, initialIndex: 1, vsync: this);
  }

  void showFirstTab() => _controller.animateTo(0);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        bottom: TabBar(
          controller: _controller,
          tabs: const [
            Tab(text: 'Zero'),
            Tab(text: 'One'),
          ],
        ),
      ),
      body: LifecycleTabBarView(
        controller: _controller,
        onTabTransition: (index, transition) {
          for (final event in transition.events) {
            widget.log.add('tab$index', event);
          }
        },
        children: const [Text('Tab 0'), Text('Tab 1')],
      ),
    );
  }
}

/// 替换 TabController 后检测旧动画是否仍然产生回调。
class _SwappableTabFixture extends StatefulWidget {
  const _SwappableTabFixture({super.key, required this.log});

  final LifecycleEventLog log;

  @override
  State<_SwappableTabFixture> createState() => _SwappableTabFixtureState();
}

class _SwappableTabFixtureState extends State<_SwappableTabFixture>
    with TickerProviderStateMixin {
  late TabController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TabController(length: 2, vsync: this);
  }

  void swapController() {
    final oldController = _controller;
    setState(() {
      _controller = TabController(length: 2, initialIndex: 1, vsync: this);
    });
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => oldController.dispose(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LifecycleTabBarView(
      controller: _controller,
      onTabTransition: (index, transition) {
        for (final event in transition.events) {
          widget.log.add('swapTab$index', event);
        }
      },
      children: const [Text('Swap tab 0'), Text('Swap tab 1')],
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

/// 外层 PageView 中嵌套内层 PageView 的组合传播夹具。
class _NestedPageFixture extends StatefulWidget {
  const _NestedPageFixture({super.key, required this.log});

  final LifecycleEventLog log;

  @override
  State<_NestedPageFixture> createState() => _NestedPageFixtureState();
}

class _NestedPageFixtureState extends State<_NestedPageFixture> {
  final PageController _outer = PageController();
  final PageController _inner = PageController();

  void showNestedPage() => _outer.jumpToPage(1);
  void showSecondInnerPage() => _inner.jumpToPage(1);
  void showFirstOuterPage() => _outer.jumpToPage(0);

  @override
  void dispose() {
    _outer.dispose();
    _inner.dispose();
    super.dispose();
  }

  void _record(String name, LifecycleTransition transition) {
    for (final event in transition.events) {
      widget.log.add(name, event);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LifecyclePageView(
      controller: _outer,
      onPageTransition: (index, transition) =>
          _record('outer$index', transition),
      children: [
        const Text('Outer 0'),
        LifecyclePageView(
          controller: _inner,
          onPageTransition: (index, transition) =>
              _record('inner$index', transition),
          children: const [Text('Inner 0'), Text('Inner 1')],
        ),
      ],
    );
  }
}
