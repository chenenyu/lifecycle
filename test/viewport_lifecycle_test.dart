/*
 * ViewportLifecycleItem 的几何、调度和快速滚动回归测试。
 *
 * 覆盖 List/Grid/Sliver、阈值、Page 继承、非滚动布局、逐帧 fling、两种激活策略、
 * fraction 稳定化与大量 KeepAlive item，重点防止漏测、激活风暴和 parked 节点恢复失败。
 */
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifecycle/lifecycle.dart';

import 'test_support.dart';

void main() {
  group('ViewportLifecycleItem', () {
    // 验证阈值、激活阈值关系和比例粒度只接受规范区间，尽早阻止无意义配置。
    test('rejects invalid threshold and granularity configurations', () {
      expect(
        () => ViewportLifecycleItem(
          visibleThreshold: -0.1,
          child: SizedBox.shrink(),
        ),
        throwsAssertionError,
      );
      expect(
        () => ViewportLifecycleItem(
          visibleThreshold: 0.8,
          activeThreshold: 0.5,
          child: SizedBox.shrink(),
        ),
        throwsAssertionError,
      );
      expect(
        () => ViewportLifecycleItem(
          visibleFractionGranularity: 1.1,
          child: SizedBox.shrink(),
        ),
        throwsAssertionError,
      );
    });

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

    // 验证默认策略在持续 fling 的每一帧都只保持 visible，滚动停止后才允许 item 激活。
    testWidgets('defers activation until a fling settles', (tester) async {
      await _setSurface(tester, const Size(400, 400));
      final controller = ScrollController();
      addTearDown(controller.dispose);
      final snapshots = <int, LifecycleSnapshot>{};
      var activationsDuringScroll = 0;

      await tester.pumpWidget(
        lifecycleTestApp(
          home: Scaffold(
            body: ListView.builder(
              controller: controller,
              itemExtent: 100,
              itemCount: 100,
              itemBuilder: (context, index) => _KeepAlive(
                child: ViewportLifecycleItem(
                  onTransition: (transition) {
                    snapshots[index] = transition.current;
                    if (transition.contains(LifecycleEvent.activated) &&
                        controller.position.isScrollingNotifier.value) {
                      activationsDuringScroll++;
                    }
                  },
                  child: Text('Fling item $index'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.fling(
        find.byType(ListView),
        const Offset(0, -1600),
        5000,
      );
      var observedScrollingFrame = false;
      for (var frame = 0; frame < 120; frame++) {
        await tester.pump(const Duration(milliseconds: 16));
        if (!controller.position.isScrollingNotifier.value) break;
        observedScrollingFrame = true;
        expect(
          snapshots.values.where((snapshot) => snapshot.visible),
          everyElement(
            isA<LifecycleSnapshot>().having(
              (snapshot) => snapshot.active,
              'active',
              isFalse,
            ),
          ),
        );
      }

      expect(observedScrollingFrame, isTrue);
      expect(activationsDuringScroll, 0);
      expect(snapshots.length, greaterThan(10));
      await tester.pumpAndSettle();
      expect(snapshots.values.any((snapshot) => snapshot.active), isTrue);
    });

    // 验证 immediate 策略保留旧行为，允许快速滑入视口的 item 在滚动中直接激活。
    testWidgets('can activate immediately during a fling', (tester) async {
      await _setSurface(tester, const Size(400, 400));
      final controller = ScrollController();
      addTearDown(controller.dispose);
      var activationsDuringScroll = 0;

      await tester.pumpWidget(
        lifecycleTestApp(
          home: Scaffold(
            body: ListView.builder(
              controller: controller,
              itemExtent: 100,
              itemCount: 40,
              itemBuilder: (context, index) => ViewportLifecycleItem(
                activationPolicy: ViewportLifecycleActivationPolicy.immediate,
                onTransition: (transition) {
                  if (transition.contains(LifecycleEvent.activated) &&
                      controller.position.isScrollingNotifier.value) {
                    activationsDuringScroll++;
                  }
                },
                child: Text('Immediate item $index'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.fling(
        find.byType(ListView),
        const Offset(0, -1000),
        4000,
      );
      for (var frame = 0; frame < 30; frame++) {
        await tester.pump(const Duration(milliseconds: 16));
        if (!controller.position.isScrollingNotifier.value) break;
      }

      expect(activationsDuringScroll, greaterThan(0));
    });

    // 验证真实滚动导致 KeepAlive item 离屏时会在当前测量帧隐藏，不再额外等待零比例确认。
    testWidgets('hides a kept-alive item in the first post-scroll frame', (
      tester,
    ) async {
      await _setSurface(tester, const Size(400, 400));
      final log = LifecycleEventLog();
      final fixtureKey = GlobalKey<_ScrollableFixtureState>();
      await tester.pumpWidget(
        lifecycleTestApp(
          home: Scaffold(
            body: _ScrollableFixture(
              key: fixtureKey,
              kind: _ScrollKind.list,
              log: log,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      log.clear();

      fixtureKey.currentState!.jumpTo(720);
      await tester.pump();

      expect(log['item0'], hiddenFromActive);
    });

    // 验证微小比例抖动会被默认 1% 粒度吸收，而有意义的比例变化仍会派发 transition。
    testWidgets('stabilizes visible fraction changes by granularity', (
      tester,
    ) async {
      await _setSurface(tester, const Size(400, 50));
      final controller = ScrollController();
      addTearDown(controller.dispose);
      final transitions = <LifecycleTransition>[];
      await tester.pumpWidget(
        lifecycleTestApp(
          home: ListView(
            controller: controller,
            children: [
              const SizedBox(height: 25),
              SizedBox(
                height: 100,
                child: ViewportLifecycleItem(
                  onTransition: transitions.add,
                  child: const Text('Granularity item'),
                ),
              ),
              const SizedBox(height: 500),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();
      transitions.clear();

      controller.jumpTo(0.2);
      await tester.pumpAndSettle();
      expect(transitions, isEmpty);

      controller.jumpTo(2);
      await tester.pumpAndSettle();
      expect(transitions, hasLength(1));
      expect(transitions.single.current.visibleFraction, 0.27);
      expect(transitions.single.events, isEmpty);
    });

    // 验证粒度设为零时保留真实测量比例，适合需要精确曝光进度的调用方。
    testWidgets('reports exact visible fractions when granularity is zero', (
      tester,
    ) async {
      await _setSurface(tester, const Size(400, 50));
      final transitions = <LifecycleTransition>[];

      await tester.pumpWidget(
        lifecycleTestApp(
          home: ListView(
            children: [
              const SizedBox(height: 25),
              SizedBox(
                height: 100,
                child: ViewportLifecycleItem(
                  visibleFractionGranularity: 0,
                  onTransition: transitions.add,
                  child: const Text('Exact fraction item'),
                ),
              ),
              const SizedBox(height: 500),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(transitions.last.current.visibleFraction, closeTo(0.25, 0.0001));
    });

    // 验证零面积 item 不会发生除零或错误激活，只保持 created 后的 hidden 状态。
    testWidgets('keeps zero-area items hidden without throwing', (
      tester,
    ) async {
      final events = <LifecycleEvent>[];
      await tester.pumpWidget(
        lifecycleTestApp(
          home: ListView(
            children: [
              ViewportLifecycleItem(
                onEvent: (event, transition) => events.add(event),
                child: const SizedBox(height: 0),
              ),
              const SizedBox(height: 600),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(events, [LifecycleEvent.created]);
      expect(tester.takeException(), isNull);
    });

    // 验证同一个 Scrollable 更换 ScrollController/ScrollPosition 后会解绑旧位置并重新测量。
    testWidgets('migrates measurement when ScrollPosition changes', (
      tester,
    ) async {
      await _setSurface(tester, const Size(400, 400));
      final log = LifecycleEventLog();
      final fixtureKey = GlobalKey<_SwappableScrollFixtureState>();

      await tester.pumpWidget(
        lifecycleTestApp(
          home: Scaffold(
            body: _SwappableScrollFixture(key: fixtureKey, log: log),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(log['swapItem0'], createdAndActive);
      log.clear();

      fixtureKey.currentState!.swapToScrolledController();
      await tester.pumpAndSettle();

      expect(fixtureKey.currentState!.offset, 600);
      expect(log['swapItem0'], hiddenFromActive);
      expect(log['swapItem5'], contains(LifecycleEvent.activated));
      expect(tester.takeException(), isNull);
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

/// 复用同一组断言的四种 Scrollable 布局。
enum _ScrollKind { list, horizontal, grid, custom }

/// 构造指定 Scrollable，并保留 item0 以测试 KeepAlive 离屏与恢复。
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

/// 强制 child 在 Sliver keep-alive bucket 中保持挂载。
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

/// 在保留同一个 ListView 元素的同时替换 ScrollController，触发 ScrollPosition 迁移。
class _SwappableScrollFixture extends StatefulWidget {
  const _SwappableScrollFixture({super.key, required this.log});

  final LifecycleEventLog log;

  @override
  State<_SwappableScrollFixture> createState() =>
      _SwappableScrollFixtureState();
}

class _SwappableScrollFixtureState extends State<_SwappableScrollFixture> {
  ScrollController _controller = ScrollController(keepScrollOffset: false);

  double get offset => _controller.offset;

  void swapToScrolledController() {
    final oldController = _controller;
    setState(() {
      _controller = ScrollController(keepScrollOffset: false);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.jumpTo(600);
      oldController.dispose();
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: _controller,
      itemExtent: 120,
      itemCount: 20,
      itemBuilder: (context, index) {
        final item = ViewportLifecycleItem(
          onEvent: (event, transition) =>
              widget.log.add('swapItem$index', event),
          child: Text('Swap item $index'),
        );
        return index == 0 ? _KeepAlive(child: item) : item;
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

/// 不改变 ScrollPosition，只通过前置空白移动 item 的布局夹具。
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

/// 把 Viewport item 放入 PageView，验证外层约束优先于局部几何。
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
