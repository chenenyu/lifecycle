import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifecycle/lifecycle.dart';

import 'test_support.dart';

void main() {
  group('ViewportLifecycleItem', () {
    // 验证垂直 ListView 双向跳转时，离屏 item 隐藏、进入视口的 item 激活并传播给子节点。
    testWidgets('tracks ListView items after jumpTo in both directions', (
      tester,
    ) async {
      await _setSurface(tester, const Size(400, 400));
      final log = LifecycleEventLog();
      final fractions = <double>[];
      final fixtureKey = GlobalKey<_ScrollableFixtureState>();

      await tester.pumpWidget(
        lifecycleTestApp(
          home: Scaffold(
            body: _ScrollableFixture(
              key: fixtureKey,
              kind: _ScrollKind.list,
              log: log,
              onItemZeroTransition: (transition) {
                fractions.add(transition.current.visibleFraction);
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(log['item0'], createdAndActive);
      expect(log['child0'], createdAndActive);
      expect(fractions.last, 1);
      log.clear();

      fixtureKey.currentState!.jumpTo(720);
      await tester.pumpAndSettle();

      expect(log['item0'], hiddenFromActive);
      expect(log['child0'], hiddenFromActive);
      expect(log['item6'], contains(LifecycleEvent.activated));
      log.clear();

      fixtureKey.currentState!.jumpTo(0);
      await tester.pumpAndSettle();

      expect(log['item0'], [LifecycleEvent.appeared, LifecycleEvent.activated]);
      expect(log['child0'], [
        LifecycleEvent.appeared,
        LifecycleEvent.activated,
      ]);
    });

    // 验证二维矩形交集算法同样适用于水平滚动的 ListView。
    testWidgets('supports horizontal ListView', (tester) async {
      await _verifyScrollableKind(
        tester,
        kind: _ScrollKind.horizontal,
        offset: 600,
        expectedVisibleItem: 5,
        size: const Size(400, 300),
      );
    });

    // 验证网格滚动后能按 item 实际矩形位置更新可见性和活跃状态。
    testWidgets('supports GridView', (tester) async {
      await _verifyScrollableKind(
        tester,
        kind: _ScrollKind.grid,
        offset: 600,
        expectedVisibleItem: 10,
      );
    });

    // 验证位于 Sliver 中的 item 也能从最近的 CustomScrollView 正确测量可见性。
    testWidgets('supports CustomScrollView', (tester) async {
      await _verifyScrollableKind(
        tester,
        kind: _ScrollKind.custom,
        offset: 600,
        expectedVisibleItem: 5,
      );
    });

    // 验证部分可见 item 分别跨过 visibleThreshold 和 activeThreshold 时才显示、激活。
    testWidgets('applies visible and active thresholds to partial items', (
      tester,
    ) async {
      await _setSurface(tester, const Size(400, 400));
      final controller = ScrollController();
      addTearDown(controller.dispose);
      final transitions = <LifecycleTransition>[];

      await tester.pumpWidget(
        lifecycleTestApp(
          home: Scaffold(
            body: ListView(
              controller: controller,
              children: [
                const SizedBox(height: 350),
                SizedBox(
                  height: 100,
                  child: ViewportLifecycleItem(
                    visibleThreshold: 0.6,
                    activeThreshold: 0.8,
                    onTransition: transitions.add,
                    child: const Text('Threshold item'),
                  ),
                ),
                const SizedBox(height: 500),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(transitions.expand((item) => item.events), [
        LifecycleEvent.created,
      ]);

      controller.jumpTo(20);
      await tester.pumpAndSettle();
      expect(transitions.expand((item) => item.events), [
        LifecycleEvent.created,
        LifecycleEvent.appeared,
      ]);

      controller.jumpTo(40);
      await tester.pumpAndSettle();
      expect(transitions.expand((item) => item.events), [
        LifecycleEvent.created,
        LifecycleEvent.appeared,
        LifecycleEvent.activated,
      ]);
    });

    // 验证视口 item 会与外层 PageView 状态合成，页面离开时即使几何可见也会隐藏。
    testWidgets('inherits page visibility from a containing PageView', (
      tester,
    ) async {
      await _setSurface(tester, const Size(400, 400));
      final fixtureKey = GlobalKey<_ViewportInPageFixtureState>();
      final log = LifecycleEventLog();

      await tester.pumpWidget(
        lifecycleTestApp(
          home: Scaffold(
            body: _ViewportInPageFixture(key: fixtureKey, log: log),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(log['nestedItem'], createdAndActive);
      log.clear();

      fixtureKey.currentState!.showSecondPage();
      await tester.pumpAndSettle();
      expect(log['nestedItem'], hiddenFromActive);
      log.clear();

      fixtureKey.currentState!.showFirstPage();
      await tester.pumpAndSettle();
      expect(log['nestedItem'], [
        LifecycleEvent.appeared,
        LifecycleEvent.activated,
      ]);
    });

    // 验证没有滚动事件的布局变化也会触发重新测量，并发现 item 已移出视口。
    testWidgets('remeasures items after a non-scroll layout change', (
      tester,
    ) async {
      await _setSurface(tester, const Size(400, 400));
      final fixtureKey = GlobalKey<_LayoutChangeFixtureState>();
      final log = LifecycleEventLog();

      await tester.pumpWidget(
        lifecycleTestApp(
          home: Scaffold(
            body: _LayoutChangeFixture(key: fixtureKey, log: log),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(log['layoutItem'], createdAndActive);
      log.clear();

      fixtureKey.currentState!.moveItemOutsideViewport();
      await tester.pumpAndSettle();

      expect(log['layoutItem'], hiddenFromActive);
    });

    // 验证缺少 Scrollable 祖先时主动抛出可理解的 FlutterError，而非静默给出错误状态。
    testWidgets('requires a Scrollable ancestor', (tester) async {
      await tester.pumpWidget(
        lifecycleTestApp(
          home: const ViewportLifecycleItem(child: Text('Invalid')),
        ),
      );

      final exception = tester.takeException();
      expect(exception, isA<FlutterError>());
      expect(exception.toString(), contains('descendant of a Scrollable'));
    });
  });
}

Future<void> _verifyScrollableKind(
  WidgetTester tester, {
  required _ScrollKind kind,
  required double offset,
  required int expectedVisibleItem,
  Size size = const Size(400, 400),
}) async {
  await _setSurface(tester, size);
  final log = LifecycleEventLog();
  final fixtureKey = GlobalKey<_ScrollableFixtureState>();

  await tester.pumpWidget(
    lifecycleTestApp(
      home: Scaffold(
        body: _ScrollableFixture(key: fixtureKey, kind: kind, log: log),
      ),
    ),
  );
  await tester.pumpAndSettle();
  expect(log['item0'], createdAndActive);
  log.clear();

  fixtureKey.currentState!.jumpTo(offset);
  await tester.pumpAndSettle();

  expect(log['item0'], hiddenFromActive);
  expect(log['item$expectedVisibleItem'], contains(LifecycleEvent.activated));
}

Future<void> _setSurface(WidgetTester tester, Size size) async {
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));
}

enum _ScrollKind { list, horizontal, grid, custom }

class _ScrollableFixture extends StatefulWidget {
  const _ScrollableFixture({
    super.key,
    required this.kind,
    required this.log,
    this.onItemZeroTransition,
  });

  final _ScrollKind kind;
  final LifecycleEventLog log;
  final LifecycleTransitionCallback? onItemZeroTransition;

  @override
  State<_ScrollableFixture> createState() => _ScrollableFixtureState();
}

class _ScrollableFixtureState extends State<_ScrollableFixture> {
  final ScrollController _controller = ScrollController();

  void jumpTo(double offset) => _controller.jumpTo(offset);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    switch (widget.kind) {
      case _ScrollKind.list:
        return ListView.builder(
          controller: _controller,
          itemExtent: 120,
          itemCount: 20,
          itemBuilder: _buildItem,
        );
      case _ScrollKind.horizontal:
        return ListView.builder(
          controller: _controller,
          scrollDirection: Axis.horizontal,
          itemExtent: 120,
          itemCount: 20,
          itemBuilder: _buildItem,
        );
      case _ScrollKind.grid:
        return GridView.builder(
          controller: _controller,
          itemCount: 20,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisExtent: 120,
          ),
          itemBuilder: _buildItem,
        );
      case _ScrollKind.custom:
        return CustomScrollView(
          controller: _controller,
          slivers: [
            SliverFixedExtentList(
              itemExtent: 120,
              delegate: SliverChildBuilderDelegate(_buildItem, childCount: 20),
            ),
          ],
        );
    }
  }

  Widget _buildItem(BuildContext context, int index) {
    final item = ViewportLifecycleItem(
      onTransition: index == 0 ? widget.onItemZeroTransition : null,
      onEvent: (event, _) => widget.log.add('item$index', event),
      child: index == 0
          ? LifecycleProbe(
              name: 'child0',
              log: widget.log,
              child: const Center(child: Text('Item 0')),
            )
          : Center(child: Text('Item $index')),
    );
    if (index == 0) {
      return _KeepAlive(child: item);
    }
    return item;
  }
}

class _KeepAlive extends StatefulWidget {
  const _KeepAlive({required this.child});

  final Widget child;

  @override
  State<_KeepAlive> createState() => _KeepAliveState();
}

class _KeepAliveState extends State<_KeepAlive>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}

class _LayoutChangeFixture extends StatefulWidget {
  const _LayoutChangeFixture({super.key, required this.log});

  final LifecycleEventLog log;

  @override
  State<_LayoutChangeFixture> createState() => _LayoutChangeFixtureState();
}

class _LayoutChangeFixtureState extends State<_LayoutChangeFixture> {
  double _leadingSpace = 20;

  void moveItemOutsideViewport() => setState(() => _leadingSpace = 500);

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        SizedBox(height: _leadingSpace),
        SizedBox(
          height: 100,
          child: ViewportLifecycleItem(
            onEvent: (event, _) => widget.log.add('layoutItem', event),
            child: const Text('Layout item'),
          ),
        ),
        const SizedBox(height: 600),
      ],
    );
  }
}

class _ViewportInPageFixture extends StatefulWidget {
  const _ViewportInPageFixture({super.key, required this.log});

  final LifecycleEventLog log;

  @override
  State<_ViewportInPageFixture> createState() => _ViewportInPageFixtureState();
}

class _ViewportInPageFixtureState extends State<_ViewportInPageFixture> {
  final PageController _controller = PageController();

  void showSecondPage() => _controller.jumpToPage(1);
  void showFirstPage() => _controller.jumpToPage(0);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LifecyclePageView(
      controller: _controller,
      children: [
        _KeepAlive(
          child: ListView(
            children: [
              SizedBox(
                height: 120,
                child: ViewportLifecycleItem(
                  onEvent: (event, _) => widget.log.add('nestedItem', event),
                  child: const Text('Nested item'),
                ),
              ),
              const SizedBox(height: 800),
            ],
          ),
        ),
        const Text('Second page'),
      ],
    );
  }
}
