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
