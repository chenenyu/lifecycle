/*
 * 在真实 Flutter Engine 上串联验证 example 的主要交互流程。
 *
 * 用例跨越命名路由、非透明 Dialog、快速滚动、PageView 手势和日志面板，补足 Widget
 * test 无法完全覆盖的平台帧调度与原生 Navigator 动画；断言聚焦关键结果以降低时序抖动。
 */
import 'package:example/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // 验证真实 Engine 中的路由、Dialog、PageView 手势和生命周期日志可以连续工作。
  testWidgets('runs the main interactive lifecycle flow', (tester) async {
    await tester.pumpWidget(const LifecycleExampleApp());
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('open-dialog-demo')),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byKey(const ValueKey('open-dialog-demo')));
    await tester.pumpAndSettle();
    expect(find.text('Non-opaque route'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('close-dialog')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('lifecycle-log-toggle')));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('dialog route').first);
    await tester.pumpAndSettle();
    expect(find.textContaining('app: resumed'), findsWidgets);
    expect(find.textContaining('app: unknown'), findsNothing);
    await tester.tap(find.byKey(const ValueKey('lifecycle-log-toggle')));
    await tester.pumpAndSettle();

    await tester.fling(
      find.byType(ListView).first,
      const Offset(0, 1600),
      3000,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('open-page-demo')));
    await tester.pumpAndSettle();

    await tester.fling(find.byType(PageView), const Offset(-600, 0), 1000);
    await tester.pumpAndSettle();

    expect(find.text('Page 1'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('lifecycle-log-toggle')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('lifecycle-log-list')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('lifecycle-log-toggle')));
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('open-viewport-demo')),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byKey(const ValueKey('open-viewport-demo')));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Activate while scrolling'));
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
    expect(tester.takeException(), isNull);
  });
}
