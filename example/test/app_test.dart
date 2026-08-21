/*
 * example 的端到端 Widget 测试集合。
 *
 * 测试通过真实点击、路由、Dialog、分页重排和视口交互验证 demo 接线，而不是重复框架
 * 单元测试；每个 case 同时防止示例 Key、日志文案和页面导航在重构中失效。
 */
import 'package:example/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // 验证首页可以进入 PageView 演示，并显示页面与视口组合后的实时状态。
  testWidgets('navigates to the page and viewport demo', (tester) async {
    await _pumpApp(tester);

    await tester.tap(find.byKey(const ValueKey('open-page-demo')));
    await tester.pumpAndSettle();

    expect(find.text('Page lifecycle'), findsOneWidget);
    expect(find.text('Page 0 / item 0'), findsOneWidget);
    expect(find.byKey(const ValueKey('lifecycle-log-toggle')), findsOneWidget);
  });

  // 验证关闭 non-opaque Dialog 后，disposed 日志保留 resumed 而不是显示 unknown。
  testWidgets('keeps app state in the disposed dialog log', (tester) async {
    await _pumpApp(tester);
    await _scrollHomeTo(tester, find.byKey(const ValueKey('open-dialog-demo')));
    await tester.tap(find.byKey(const ValueKey('open-dialog-demo')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('close-dialog')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('lifecycle-log-toggle')));
    await tester.pumpAndSettle();

    await tester.tap(find.textContaining('dialog route').first);
    await tester.pumpAndSettle();

    expect(find.textContaining('app: resumed'), findsWidgets);
    expect(find.textContaining('app: unknown'), findsNothing);
  });

  // 验证 PageView.builder 重排数据后保留通过稳定 ID 绑定的页面局部 State。
  testWidgets('preserves page State while reversing stable IDs', (
    tester,
  ) async {
    await _pumpApp(tester);
    await _scrollHomeTo(
      tester,
      find.byKey(const ValueKey('open-reorder-demo')),
    );
    await tester.tap(find.byKey(const ValueKey('open-reorder-demo')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('increment-alpha')));
    await tester.pump();
    expect(find.text('alpha: 1'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('reverse-pages')));
    await tester.pumpAndSettle();
    expect(find.text('alpha: 1'), findsOneWidget);
  });

  // 验证独立 Viewport demo 可切换滚动激活策略、快速滚动并把网格 transition 写入日志。
  testWidgets('runs the configurable viewport demo', (tester) async {
    await _pumpApp(tester);
    await _scrollHomeTo(
      tester,
      find.byKey(const ValueKey('open-viewport-demo')),
    );
    await tester.tap(find.byKey(const ValueKey('open-viewport-demo')));
    await tester.pumpAndSettle();

    expect(find.text('Viewport lifecycle'), findsOneWidget);
    await tester.tap(find.text('Activate while scrolling'));
    await tester.pump();
    expect(
      tester
          .widget<SwitchListTile>(
            find.widgetWithText(SwitchListTile, 'Activate while scrolling'),
          )
          .value,
      isTrue,
    );

    await tester.fling(
      find.byKey(const ValueKey('viewport-grid')),
      const Offset(0, -900),
      3000,
    );
    await tester.pumpAndSettle();
    expect(
      tester
          .state<ScrollableState>(find.byType(Scrollable).last)
          .position
          .pixels,
      greaterThan(0),
    );

    await tester.tap(find.byKey(const ValueKey('lifecycle-log-toggle')));
    await tester.pumpAndSettle();
    expect(find.textContaining('grid item'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  // 验证嵌套 Navigator 的 push/pop 只切换内层内容，返回后仍停留在同一个专项 demo。
  testWidgets('runs the nested navigator demo flow', (tester) async {
    await _pumpApp(tester);
    await _scrollHomeTo(
      tester,
      find.byKey(const ValueKey('open-nested-navigator-demo')),
    );
    await tester.tap(find.byKey(const ValueKey('open-nested-navigator-demo')));
    await tester.pumpAndSettle();

    expect(find.text('Nested home'), findsWidgets);
    await tester.tap(find.byKey(const ValueKey('nested-push')));
    await tester.pumpAndSettle();
    expect(find.text('Nested details'), findsWidgets);

    await tester.tap(find.byKey(const ValueKey('nested-pop')));
    await tester.pumpAndSettle();
    expect(find.text('Nested home'), findsWidgets);
    expect(find.text('Nested Navigator'), findsOneWidget);
  });

  // 验证 Navigator.pages demo 的列表增删能真实创建和移除 details 页面。
  testWidgets('runs the declarative Navigator pages flow', (tester) async {
    await _pumpApp(tester);
    await _scrollHomeTo(
      tester,
      find.byKey(const ValueKey('open-pages-api-demo')),
    );
    await tester.tap(find.byKey(const ValueKey('open-pages-api-demo')));
    await tester.pumpAndSettle();

    expect(find.textContaining('Declarative home'), findsWidgets);
    await tester.tap(find.byKey(const ValueKey('add-declarative-page')));
    await tester.pumpAndSettle();
    expect(find.textContaining('Declarative details'), findsWidgets);

    await tester.tap(find.byKey(const ValueKey('remove-declarative-page')));
    await tester.pumpAndSettle();
    expect(find.textContaining('Declarative details'), findsNothing);
    expect(find.textContaining('Declarative home'), findsWidgets);
  });

  // 验证 Controller 实验页修改父约束后，子节点有效状态也按父子交集同步隐藏。
  testWidgets('composes parent changes in the controller lab', (tester) async {
    await _pumpApp(tester);
    await _scrollHomeTo(
      tester,
      find.byKey(const ValueKey('open-controller-lab')),
    );
    await tester.tap(find.byKey(const ValueKey('open-controller-lab')));
    await tester.pumpAndSettle();

    expect(find.text('Parent effective: active'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilterChip, 'visible').first);
    await tester.pump();

    expect(find.text('Parent effective: hidden'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.textContaining('Child effective:'),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();
    expect(find.text('Child effective: hidden'), findsOneWidget);
  });

  // 验证普通命名路由和 Tab 专项入口均已正确接入 demo 根 Navigator 与生命周期组件。
  testWidgets('runs the route and tab demo entries', (tester) async {
    await _pumpApp(tester);
    await tester.tap(find.byKey(const ValueKey('open-route-demo')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('status-Details route')), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    await _scrollHomeTo(tester, find.byKey(const ValueKey('open-tab-demo')));
    await tester.tap(find.byKey(const ValueKey('open-tab-demo')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('SECOND'));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('status-Tab 1')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  // 验证首页自定义 Boundary 关闭 visible 时，其后代状态卡同步进入 hidden。
  testWidgets('updates the custom boundary demo', (tester) async {
    await _pumpApp(tester);
    final visibleSwitch = find.byKey(const ValueKey('boundary-visible-switch'));
    await _scrollHomeTo(tester, visibleSwitch);
    await tester.tap(visibleSwitch);
    await tester.pump();

    final boundaryCard = find.byKey(const ValueKey('status-Boundary child'));
    expect(
      find.descendant(of: boundaryCard, matching: find.text('hidden')),
      findsOneWidget,
    );
  });
}

Future<void> _pumpApp(WidgetTester tester) async {
  await tester.pumpWidget(const LifecycleExampleApp());
  await tester.pumpAndSettle();
  expect(find.text('Composable lifecycle scopes'), findsOneWidget);
}

Future<void> _scrollHomeTo(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(
    finder,
    300,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
}
