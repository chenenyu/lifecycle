import 'package:example/logging/demo_log.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifecycle/lifecycle.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // 验证结构化日志不会丢弃 events 为空、仅 visibleFraction 变化的 transition。
  test('records snapshot-only transitions', () {
    final log = DemoLog();
    addTearDown(log.dispose);
    final transition = LifecycleTransition(
      previous: const LifecycleSnapshot(
        phase: LifecyclePhase.visible,
        visibleFraction: 0.8,
        appState: AppLifecycleState.resumed,
      ),
      current: const LifecycleSnapshot(
        phase: LifecyclePhase.visible,
        visibleFraction: 0.4,
        appState: AppLifecycleState.resumed,
      ),
      cause: LifecycleCause.viewport,
      events: const [],
    );

    log.record('item', transition);

    expect(log.entries, hasLength(1));
    expect(log.entries.single.eventSummary, 'snapshot changed');
    expect(log.entries.single.copyText, contains('fraction 0.80 → 0.40'));
  });

  // 验证 terminal transition 的结构化日志文本包含最终保留的 App 状态。
  test('retains terminal app state in structured entries', () {
    final parent = LifecycleController(appState: AppLifecycleState.inactive)
      ..attach();
    final child = LifecycleController()..attach(parent: parent);
    late LifecycleTransition terminal;
    child.addListener(() => terminal = child.lastTransition!);

    child.dispose();
    final log = DemoLog()..record('dialog', terminal);
    addTearDown(log.dispose);
    addTearDown(parent.dispose);

    expect(log.entries.single.current.appState, AppLifecycleState.inactive);
  });
}
