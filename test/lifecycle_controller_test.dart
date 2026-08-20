import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifecycle/lifecycle.dart';

void main() {
  group('LifecycleController', () {
    // 验证节点从创建、显示、激活到隐藏和销毁时，会按确定顺序派发语义事件。
    test('derives a deterministic event sequence', () {
      final controller = LifecycleController();
      final events = <LifecycleEvent>[];
      listenToTransitions(controller, events.addAllFromTransition);
      expect(controller.lastTransition, isNull);

      controller.attach();
      expect(events, [
        LifecycleEvent.created,
        LifecycleEvent.appeared,
        LifecycleEvent.activated,
      ]);
      expect(controller.lastTransition!.current, controller.value);
      expect(controller.value.phase, LifecyclePhase.active);

      events.clear();
      controller.updateLocal(active: false);
      expect(events, [LifecycleEvent.deactivated]);
      expect(controller.value.phase, LifecyclePhase.visible);

      controller.updateLocal(visible: false);
      expect(events, [LifecycleEvent.deactivated, LifecycleEvent.disappeared]);
      expect(controller.value.phase, LifecyclePhase.hidden);

      events.clear();
      controller.updateLocal(visible: true);
      controller.updateLocal(active: true);
      expect(events, [LifecycleEvent.appeared, LifecycleEvent.activated]);

      events.clear();
      controller.dispose();
      expect(events, [
        LifecycleEvent.deactivated,
        LifecycleEvent.disappeared,
        LifecycleEvent.disposed,
      ]);
      expect(controller.value.phase, LifecyclePhase.disposed);
    });

    // 验证子节点会继承父节点的可见性、活跃状态和 App 状态，并取较小的可见比例。
    test('composes parent state and visible fractions', () {
      final parent = LifecycleController(
        visibleFraction: 0.8,
        appState: AppLifecycleState.resumed,
      )..attach();
      final child = LifecycleController(visibleFraction: 0.5)
        ..attach(parent: parent);

      expect(child.value.active, isTrue);
      expect(child.value.visibleFraction, 0.5);
      expect(child.value.appState, AppLifecycleState.resumed);
      expect(child.parent, same(parent));

      parent.updateLocal(
        active: false,
        visibleFraction: 0.25,
        appState: AppLifecycleState.inactive,
        cause: LifecycleCause.app,
      );

      expect(child.value.visible, isTrue);
      expect(child.value.active, isFalse);
      expect(child.value.visibleFraction, 0.25);
      expect(child.value.appState, AppLifecycleState.inactive);

      parent.updateLocal(visible: false, visibleFraction: 0);
      expect(child.value.phase, LifecyclePhase.hidden);

      child.updateLocal(clearAppState: true);
      expect(child.value.appState, AppLifecycleState.inactive);

      child.dispose();
      parent.dispose();
    });

    // 验证继承的 App 状态会保留在最终 disposed 快照中，即使父节点已先解除绑定。
    test('preserves inherited app state in the terminal snapshot', () {
      final parent = LifecycleController(
        appState: AppLifecycleState.inactive,
      )..attach();
      final child = LifecycleController()..attach(parent: parent);
      final transitions = <LifecycleTransition>[];
      listenToTransitions(child, transitions.add);

      child.disposeWithCause(LifecycleCause.route);

      final terminal = transitions.single;
      expect(terminal.previous.appState, AppLifecycleState.inactive);
      expect(terminal.current.phase, LifecyclePhase.disposed);
      expect(terminal.current.appState, AppLifecycleState.inactive);
      expect(terminal.cause, LifecycleCause.route);
      expect(child.parent, isNull);
      parent.dispose();
    });

    // 验证节点换父级后立即采用新父级状态，且不再响应旧父级的后续变化。
    test('reparents without retaining the old parent', () {
      final visibleParent = LifecycleController()..attach();
      final hiddenParent = LifecycleController(visible: false)..attach();
      final child = LifecycleController()..attach(parent: hiddenParent);

      expect(child.value.phase, LifecyclePhase.hidden);
      child.reparent(visibleParent);
      expect(child.value.phase, LifecyclePhase.active);

      hiddenParent.updateLocal(visible: true);
      expect(child.value.phase, LifecyclePhase.active);

      child.dispose();
      hiddenParent.dispose();
      visibleParent.dispose();
    });

    // 验证 controller 拒绝以自身或后代为父节点，且失败后保持原父子关系不变。
    test('rejects parent cycles without mutating the tree', () {
      final root = LifecycleController()..attach();
      final child = LifecycleController()..attach(parent: root);
      final grandchild = LifecycleController()..attach(parent: child);
      final detached = LifecycleController();
      final disposedParent = LifecycleController()..attach();
      disposedParent.dispose();

      expect(() => detached.attach(parent: detached), throwsArgumentError);
      expect(detached.isAttached, isFalse);
      expect(detached.parent, isNull);

      expect(() => root.reparent(grandchild), throwsArgumentError);
      expect(root.parent, isNull);
      expect(child.parent, same(root));
      expect(grandchild.parent, same(child));

      expect(() => child.reparent(disposedParent), throwsStateError);
      expect(child.parent, same(root));
      expect(child.value.phase, LifecyclePhase.active);

      detached.dispose();
      grandchild.dispose();
      child.dispose();
      root.dispose();
    });

    // 验证重复提交相同状态或相同父节点不会产生多余 transition。
    test('is idempotent for unchanged inputs', () {
      final controller = LifecycleController()..attach();
      var transitionCount = 0;
      listenToTransitions(controller, (_) => transitionCount++);

      controller.updateLocal(visible: true, active: true, visibleFraction: 1);
      controller.reparent(null);

      expect(transitionCount, 0);
      controller.dispose();
    });

    // 验证 transition 回调内再次更新状态时会排队执行，不会递归破坏事件顺序。
    test('queues reentrant updates safely', () {
      final controller = LifecycleController()..attach();
      final events = <LifecycleEvent>[];
      listenToTransitions(controller, (transition) {
        events.addAll(transition.events);
        if (transition.contains(LifecycleEvent.deactivated)) {
          controller.updateLocal(visible: false);
        }
      });

      controller.updateLocal(active: false);

      expect(events, [LifecycleEvent.deactivated, LifecycleEvent.disappeared]);
      expect(controller.value.phase, LifecyclePhase.hidden);
      controller.dispose();
    });

    // 验证派发期间可以安全地移除自身并添加新监听器，新监听器不会收到当前旧事件。
    test('allows listeners to mutate the listener set during delivery', () {
      final controller = LifecycleController()..attach();
      var selfRemovingCalls = 0;
      var lateListenerCalls = 0;

      late VoidCallback selfRemoving;
      void lateListener() {
        lateListenerCalls++;
      }

      selfRemoving = () {
        selfRemovingCalls++;
        controller
          ..removeListener(selfRemoving)
          ..addListener(lateListener);
      };
      controller.addListener(selfRemoving);

      controller.updateLocal(active: false);
      expect(selfRemovingCalls, 1);
      expect(lateListenerCalls, 0);

      controller.updateLocal(active: true);
      expect(selfRemovingCalls, 1);
      expect(lateListenerCalls, 1);
      controller.dispose();
    });

    // 验证单个用户回调异常会被报告，但不会中断其他监听器或后续状态更新。
    test('isolates and reports ChangeNotifier listener errors', () {
      final controller = LifecycleController()..attach();
      final reportedErrors = <FlutterErrorDetails>[];
      final previousErrorHandler = FlutterError.onError;
      FlutterError.onError = reportedErrors.add;
      addTearDown(() => FlutterError.onError = previousErrorHandler);

      controller.addListener(() {
        throw StateError('listener failed');
      });
      final transitions = <LifecycleTransition>[];
      listenToTransitions(controller, transitions.add);

      controller.updateLocal(active: false);

      expect(reportedErrors, hasLength(1));
      expect(reportedErrors.single.exception, isA<StateError>());
      expect(controller.value.phase, LifecyclePhase.visible);
      expect(transitions.single.events, [LifecycleEvent.deactivated]);

      transitions.clear();
      controller.updateLocal(active: true);

      expect(transitions, hasLength(1));
      expect(transitions.single.events, [LifecycleEvent.activated]);
      expect(reportedErrors, hasLength(2));
      controller.dispose();
    });

    // 验证 terminal transition 回调异常被报告时，dispose 仍会完成并保留最终快照。
    test('finalizes disposal when a terminal listener throws', () {
      final reportedErrors = <FlutterErrorDetails>[];
      final previousErrorHandler = FlutterError.onError;
      FlutterError.onError = reportedErrors.add;
      addTearDown(() => FlutterError.onError = previousErrorHandler);
      final parent = LifecycleController(
        appState: AppLifecycleState.paused,
      )..attach();
      final controller = LifecycleController()..attach(parent: parent);
      controller.addListener(() {
        final transition = controller.lastTransition!;
        if (transition.current.phase == LifecyclePhase.disposed) {
          throw StateError('terminal listener failed');
        }
      });

      controller.dispose();
      expect(reportedErrors, hasLength(1));
      expect(reportedErrors.single.exception, isA<StateError>());
      expect(controller.isDisposed, isTrue);
      expect(controller.parent, isNull);
      expect(controller.value.phase, LifecyclePhase.disposed);
      expect(controller.value.appState, AppLifecycleState.paused);
      expect(() => controller.addListener(() {}), throwsFlutterError);
      parent.dispose();
    });

    // 验证可以在 transition 回调中销毁 controller，并完整派发隐藏和销毁事件。
    test('can be disposed from a transition callback', () {
      final parent = LifecycleController(
        appState: AppLifecycleState.resumed,
      )..attach();
      final controller = LifecycleController()..attach(parent: parent);
      final events = <LifecycleEvent>[];
      final transitions = <LifecycleTransition>[];
      listenToTransitions(controller, (transition) {
        transitions.add(transition);
        events.addAll(transition.events);
        if (transition.contains(LifecycleEvent.deactivated)) {
          controller.disposeWithCause(LifecycleCause.custom);
        }
      });

      controller.updateLocal(active: false);

      expect(events, [
        LifecycleEvent.deactivated,
        LifecycleEvent.disappeared,
        LifecycleEvent.disposed,
      ]);
      expect(controller.isDisposed, isTrue);
      expect(transitions.last.current.appState, AppLifecycleState.resumed);
      parent.dispose();
    });

    // 验证 NaN、超上限和低于零的可见比例会被规范化到 0～1。
    test('normalizes invalid visible fractions', () {
      final controller = LifecycleController(visibleFraction: double.nan)
        ..attach();
      expect(controller.value.visibleFraction, 0);

      controller.updateLocal(visibleFraction: 2);
      expect(controller.value.visibleFraction, 1);

      controller.updateLocal(visibleFraction: -1);
      expect(controller.value.visibleFraction, 0);
      controller.dispose();
    });

    // 验证 controller 销毁后不允许更新、重新挂接或新增监听器。
    test('rejects updates after disposal', () {
      final controller = LifecycleController()..attach();
      controller.dispose();

      expect(() => controller.updateLocal(visible: false), throwsStateError);
      expect(() => controller.attach(), throwsStateError);
      expect(() => controller.addListener(() {}), throwsFlutterError);
    });

    // 验证快照按字段进行值比较，并在诊断字符串中输出关键状态。
    test('snapshot implements value equality and diagnostics', () {
      const first = LifecycleSnapshot(
        phase: LifecyclePhase.visible,
        visibleFraction: 0.5,
      );
      const second = LifecycleSnapshot(
        phase: LifecyclePhase.visible,
        visibleFraction: 0.5,
      );

      expect(first, second);
      expect(first.hashCode, second.hashCode);
      expect(first.attached, isTrue);
      expect(first.visible, isTrue);
      expect(first.active, isFalse);
      expect(first.toString(), contains('visibleFraction: 0.5'));
    });

    // 验证 attached、visible 和 active 完全由 phase 推导，不再形成重复状态源。
    test('snapshot derives state flags from its phase', () {
      const snapshots = {
        LifecyclePhase.detached: LifecycleSnapshot.detached(),
        LifecyclePhase.hidden: LifecycleSnapshot(
          phase: LifecyclePhase.hidden,
          visibleFraction: 0,
        ),
        LifecyclePhase.visible: LifecycleSnapshot(
          phase: LifecyclePhase.visible,
          visibleFraction: 0.5,
        ),
        LifecyclePhase.active: LifecycleSnapshot(
          phase: LifecyclePhase.active,
          visibleFraction: 1,
        ),
        LifecyclePhase.disposed: LifecycleSnapshot(
          phase: LifecyclePhase.disposed,
          visibleFraction: 0,
        ),
      };

      expect(snapshots[LifecyclePhase.detached]!.attached, isFalse);
      expect(snapshots[LifecyclePhase.hidden]!.attached, isTrue);
      expect(snapshots[LifecyclePhase.visible]!.attached, isTrue);
      expect(snapshots[LifecyclePhase.active]!.attached, isTrue);
      expect(snapshots[LifecyclePhase.disposed]!.attached, isFalse);
      expect(snapshots[LifecyclePhase.hidden]!.visible, isFalse);
      expect(snapshots[LifecyclePhase.visible]!.visible, isTrue);
      expect(snapshots[LifecyclePhase.active]!.active, isTrue);
    });

    // 验证构造器拒绝与 phase 矛盾的可见比例和 detached App 状态。
    test('snapshot rejects states that contradict their phase', () {
      expect(
        () => LifecycleSnapshot(
          phase: LifecyclePhase.hidden,
          visibleFraction: 0.5,
        ),
        throwsAssertionError,
      );
      expect(
        () => LifecycleSnapshot(
          phase: LifecyclePhase.active,
          visibleFraction: 0,
        ),
        throwsAssertionError,
      );
      expect(
        () => LifecycleSnapshot(
          phase: LifecyclePhase.detached,
          visibleFraction: 0,
          appState: AppLifecycleState.resumed,
        ),
        throwsAssertionError,
      );
    });

    // 验证 transition 会复制并冻结事件列表，同时提供事件查询和诊断信息。
    test('transition exposes immutable events and diagnostics', () {
      final events = <LifecycleEvent>[LifecycleEvent.appeared];
      final transition = LifecycleTransition(
        previous: const LifecycleSnapshot.detached(),
        current: const LifecycleSnapshot(
          phase: LifecyclePhase.visible,
          visibleFraction: 0.5,
        ),
        cause: LifecycleCause.custom,
        events: events,
      );
      events.clear();

      expect(transition.contains(LifecycleEvent.appeared), isTrue);
      expect(transition.events, [LifecycleEvent.appeared]);
      expect(
        () => transition.events.add(LifecycleEvent.activated),
        throwsUnsupportedError,
      );
      expect(transition.toString(), contains('LifecycleCause.custom'));
    });
  });

  // 验证 Navigator 暂时脱离和重新挂接时，已有 Route 会隐藏并恢复活跃，而不会丢失。
  test('NavigatorLifecycleController detaches and reattaches its routes', () {
    final app = LifecycleController()..attach();
    final navigation = NavigatorLifecycleController()..attach(app);
    final route = PageRouteBuilder<void>(
      pageBuilder: (context, animation, secondaryAnimation) =>
          const SizedBox.shrink(),
    );

    navigation.handlePush(route, null);
    expect(navigation.entryFor(route)!.lifecycle.phase, LifecyclePhase.active);

    navigation.detach();
    expect(navigation.entryFor(route)!.lifecycle.phase, LifecyclePhase.hidden);

    navigation.attach(app);
    expect(navigation.entryFor(route)!.lifecycle.phase, LifecyclePhase.active);

    navigation.dispose();
    app.dispose();
  });

  // 验证未挂载或已销毁 Navigator 的非法操作会报错，并覆盖置顶、手势和移除边界场景。
  test('NavigatorLifecycleController validates unsupported operations', () {
    final navigation = NavigatorLifecycleController();
    final first = PageRouteBuilder<void>(
      pageBuilder: (context, animation, secondaryAnimation) =>
          const SizedBox.shrink(),
    );
    final second = PageRouteBuilder<void>(
      pageBuilder: (context, animation, secondaryAnimation) =>
          const SizedBox.shrink(),
    );

    expect(() => navigation.removeRoute(first), throwsStateError);

    navigation
      ..attach(null)
      ..handlePush(first, null)
      ..handlePush(second, first)
      ..handleTopChanged(first, second);
    expect(navigation.routes.last.route, same(first));

    navigation.observer.didStartUserGesture(first, second);
    navigation.handleRemove(second, first);
    navigation.observer.didStopUserGesture();
    expect(navigation.entryFor(second), isNull);

    navigation.dispose();
    expect(() => navigation.attach(null), throwsStateError);
    navigation.dispose();
  });
}

VoidCallback listenToTransitions(
  LifecycleController controller,
  LifecycleTransitionCallback callback,
) {
  void listener() => callback(controller.lastTransition!);
  controller.addListener(listener);
  return listener;
}

extension on List<LifecycleEvent> {
  void addAllFromTransition(LifecycleTransition transition) {
    addAll(transition.events);
  }
}
