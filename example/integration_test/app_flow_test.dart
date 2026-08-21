/*
 * 在真实 Flutter Engine 上验证 example 的关键跨页面交互。
 *
 * 每个 smoke case 都从全新的应用树开始，避免前一个路由、日志或 ScrollPosition 污染后续
 * 断言；Widget/unit test 负责细粒度状态机，这里专注原生帧调度、真实手势、页面栈清理和
 * 稳定 Finder。仓库验证在 macOS 执行，Android 运行按仓库约定跳过。
 */
import 'package:example/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // 验证真实 Engine 中 non-opaque Dialog 关闭后仍保留 resumed App 状态和完整 terminal 事件。
  testWidgets('preserves dialog lifecycle state in the native route flow', (
    tester,
  ) async {
    await _pumpExample(tester);
    await _scrollHomeTo(tester, find.byKey(const ValueKey('open-dialog-demo')));
    await tester.tap(find.byKey(const ValueKey('open-dialog-demo')));
    await tester.pumpAndSettle();
    expect(find.text('Non-opaque route'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('close-dialog')));
    await tester.pumpAndSettle();
    await _openLog(tester);

    await tester.tap(find.textContaining('dialog route').first);
    await tester.pump();
    expect(find.textContaining('events: disposed'), findsOneWidget);
    expect(find.textContaining('app: resumed'), findsOneWidget);
    expect(find.textContaining('app: unknown'), findsNothing);
    expect(find.textContaining('· route'), findsWidgets);
  });

  // 验证真实 PageView 手势最终激活目标页，并能从日志中看到 pageSelection cause。
  testWidgets('settles a PageView gesture with lifecycle events', (
    tester,
  ) async {
    await _pumpExample(tester);
    await _scrollHomeTo(tester, find.byKey(const ValueKey('open-page-demo')));
    await tester.tap(find.byKey(const ValueKey('open-page-demo')));
    await tester.pumpAndSettle();

    final pageView = find.byKey(const ValueKey('page-lifecycle-view'));
    expect(
      find.byKey(const ValueKey('status-Page 0 / item 0')),
      findsOneWidget,
    );
    await tester.fling(pageView, const Offset(-600, 0), 1000);
    await tester.pump(const Duration(milliseconds: 80));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('status-Page 1')), findsOneWidget);
    await _openLog(tester);
    await tester.tap(find.textContaining('page 1').first);
    await tester.pump();
    expect(find.textContaining('activated'), findsWidgets);
    expect(find.textContaining('pageSelection'), findsWidgets);

    await _closeLog(tester);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('home-scroll')), findsOneWidget);
  });

  // 验证真实 GridView fling 能滚动到新位置，并且 demo 的默认 settled 和 immediate 开关可用。
  testWidgets('runs the viewport fling on the native engine', (tester) async {
    await _pumpExample(tester);
    await _scrollHomeTo(
      tester,
      find.byKey(const ValueKey('open-viewport-demo')),
    );
    await tester.tap(find.byKey(const ValueKey('open-viewport-demo')));
    await tester.pumpAndSettle();

    final activationSwitch = find.widgetWithText(
      SwitchListTile,
      'Activate while scrolling',
    );
    expect(tester.widget<SwitchListTile>(activationSwitch).value, isFalse);
    final grid = find.byKey(const ValueKey('viewport-grid'));

    await tester.fling(grid, const Offset(0, -900), 3000);
    await tester.pumpAndSettle();
    expect(
      tester
          .state<ScrollableState>(
            find.descendant(of: grid, matching: find.byType(Scrollable)),
          )
          .position
          .pixels,
      greaterThan(0),
    );

    await tester.tap(find.text('Activate while scrolling'));
    await tester.pump();
    expect(tester.widget<SwitchListTile>(activationSwitch).value, isTrue);
    await tester.fling(grid, const Offset(0, -500), 3000);
    await tester.pumpAndSettle();
    await _openLog(tester);
    expect(find.byKey(const ValueKey('lifecycle-log-list')), findsOneWidget);
    expect(find.textContaining('grid item'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  // 验证嵌套 Navigator push/pop 和 Navigator.pages 增删在真实页面栈中都能完成清理。
  testWidgets('runs nested and declarative Navigator smoke flows', (
    tester,
  ) async {
    await _pumpExample(tester);
    await _scrollHomeTo(
      tester,
      find.byKey(const ValueKey('open-nested-navigator-demo')),
    );
    await tester.tap(find.byKey(const ValueKey('open-nested-navigator-demo')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('nested-push')));
    await tester.pumpAndSettle();
    expect(find.text('Nested details'), findsWidgets);
    await tester.tap(find.byKey(const ValueKey('nested-pop')));
    await tester.pumpAndSettle();
    expect(find.text('Nested home'), findsWidgets);

    await tester.pageBack();
    await tester.pumpAndSettle();
    await _scrollHomeTo(
      tester,
      find.byKey(const ValueKey('open-pages-api-demo')),
    );
    await tester.tap(find.byKey(const ValueKey('open-pages-api-demo')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('add-declarative-page')));
    await tester.pumpAndSettle();
    expect(find.textContaining('Declarative details'), findsWidgets);
    await tester.tap(find.byKey(const ValueKey('remove-declarative-page')));
    await tester.pumpAndSettle();
    expect(find.textContaining('Declarative details'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}

Future<void> _pumpExample(WidgetTester tester) async {
  await tester.pumpWidget(const LifecycleExampleApp());
  await tester.pumpAndSettle();
  expect(find.text('Composable lifecycle scopes'), findsOneWidget);
}

Future<void> _scrollHomeTo(WidgetTester tester, Finder target) async {
  final homeScroll = find.descendant(
    of: find.byKey(const ValueKey('home-scroll')),
    matching: find.byType(Scrollable),
  );
  await tester.scrollUntilVisible(target, 300, scrollable: homeScroll);
  await tester.pumpAndSettle();
}

Future<void> _openLog(WidgetTester tester) async {
  final toggle = find.byKey(const ValueKey('lifecycle-log-toggle'));
  if (toggle.evaluate().isNotEmpty) {
    await tester.tap(toggle);
    await tester.pumpAndSettle();
  }
}

Future<void> _closeLog(WidgetTester tester) async {
  final toggle = find.byKey(const ValueKey('lifecycle-log-toggle'));
  if (toggle.evaluate().isNotEmpty) {
    await tester.tap(toggle);
    await tester.pumpAndSettle();
  }
}
