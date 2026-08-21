/*
 * LifecycleController、Snapshot、Transition 和 Navigator 查询 API 的状态机测试。
 *
 * 除确定性边界 case 外，还使用固定 seed 的独立参考模型执行随机约束、App 状态和
 * reparent 操作，验证快照合成、事件顺序、重入通知、异常隔离与终止销毁始终连续。
 */
import 'dart:math' as math;

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
      controller.updateLocal(constraint: const LifecycleConstraint.visible());
      expect(events, [LifecycleEvent.deactivated]);
      expect(controller.value.phase, LifecyclePhase.visible);

      controller.updateLocal(constraint: const LifecycleConstraint.hidden());
      expect(events, [LifecycleEvent.deactivated, LifecycleEvent.disappeared]);
      expect(controller.value.phase, LifecyclePhase.hidden);

      events.clear();
      controller.updateLocal(constraint: const LifecycleConstraint.visible());
      controller.updateLocal(constraint: const LifecycleConstraint.active());
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
        constraint: const LifecycleConstraint.active(visibleFraction: 0.8),
        appState: AppLifecycleState.resumed,
      )..attach();
      final child = LifecycleController(
        constraint: const LifecycleConstraint.active(visibleFraction: 0.5),
      )..attach(parent: parent);

      expect(child.value.active, isTrue);
      expect(child.value.visibleFraction, 0.5);
      expect(child.value.appState, AppLifecycleState.resumed);
      expect(child.parent, same(parent));

      parent.updateLocal(
        constraint: const LifecycleConstraint.visible(visibleFraction: 0.25),
        appState: AppLifecycleState.inactive,
        cause: LifecycleCause.app,
      );

      expect(child.value.visible, isTrue);
      expect(child.value.active, isFalse);
      expect(child.value.visibleFraction, 0.25);
      expect(child.value.appState, AppLifecycleState.inactive);

      parent.updateLocal(constraint: const LifecycleConstraint.hidden());
      expect(child.value.phase, LifecyclePhase.hidden);

      child.updateLocal(clearAppState: true);
      expect(child.value.appState, AppLifecycleState.inactive);

      child.dispose();
      parent.dispose();
    });

    // 验证本地 App 状态会覆盖父节点，clearAppState 后重新继承父状态，并保留父更新的 cause。
    test('overrides and clears inherited app state deterministically', () {
      final parent = LifecycleController(
        appState: AppLifecycleState.inactive,
      )..attach();
      final child = LifecycleController(
        appState: AppLifecycleState.paused,
      )..attach(parent: parent);
      final transitions = <LifecycleTransition>[];
      listenToTransitions(child, transitions.add);

      expect(child.value.appState, AppLifecycleState.paused);

      child.updateLocal(
        appState: AppLifecycleState.resumed,
        clearAppState: true,
      );
      expect(child.value.appState, AppLifecycleState.inactive);

      parent.updateLocal(
        appState: AppLifecycleState.resumed,
        cause: LifecycleCause.app,
      );
      expect(child.value.appState, AppLifecycleState.resumed);
      expect(transitions.last.cause, LifecycleCause.app);

      child.dispose();
      parent.dispose();
    });

    // 验证父节点销毁会让仍挂接的子节点隐藏，子节点随后仍可安全脱离并恢复本地状态。
    test('keeps children valid when their parent is disposed first', () {
      final parent = LifecycleController(
        appState: AppLifecycleState.resumed,
      )..attach();
      final child = LifecycleController()..attach(parent: parent);
      final transitions = <LifecycleTransition>[];
      listenToTransitions(child, transitions.add);

      parent.disposeWithCause(LifecycleCause.custom);

      expect(child.value.phase, LifecyclePhase.hidden);
      expect(child.value.appState, AppLifecycleState.resumed);
      expect(transitions.last.cause, LifecycleCause.custom);
      expect(transitions.last.events, [
        LifecycleEvent.deactivated,
        LifecycleEvent.disappeared,
      ]);

      child.reparent(null);
      expect(child.value.phase, LifecyclePhase.active);
      expect(child.value.appState, isNull);
      child.dispose();
    });

    // 验证从未 attach 的节点销毁时只派发 disposed，且重复销毁不会产生第二个终止事件。
    test('disposes a detached controller exactly once', () {
      final controller = LifecycleController(
        appState: AppLifecycleState.paused,
      );
      final transitions = <LifecycleTransition>[];
      listenToTransitions(controller, transitions.add);

      controller.disposeWithCause(LifecycleCause.custom);
      controller.disposeWithCause(LifecycleCause.route);

      expect(transitions, hasLength(1));
      expect(transitions.single.previous.phase, LifecyclePhase.detached);
      expect(transitions.single.current.phase, LifecyclePhase.disposed);
      expect(transitions.single.current.appState, AppLifecycleState.paused);
      expect(transitions.single.events, [LifecycleEvent.disposed]);
      expect(transitions.single.cause, LifecycleCause.custom);
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
      final hiddenParent = LifecycleController(
        constraint: const LifecycleConstraint.hidden(),
      )..attach();
      final child = LifecycleController()..attach(parent: hiddenParent);

      expect(child.value.phase, LifecyclePhase.hidden);
      child.reparent(visibleParent);
      expect(child.value.phase, LifecyclePhase.active);

      hiddenParent.updateLocal(
        constraint: const LifecycleConstraint.active(),
      );
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

      expect(
        identical(controller.value, const LifecycleSnapshot.active()),
        isTrue,
      );
      controller.updateLocal(constraint: const LifecycleConstraint.active());
      controller.updateLocal(appState: null);
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
          controller.updateLocal(
            constraint: const LifecycleConstraint.hidden(),
          );
        }
      });

      controller.updateLocal(constraint: const LifecycleConstraint.visible());

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

      controller.updateLocal(constraint: const LifecycleConstraint.visible());
      expect(selfRemovingCalls, 1);
      expect(lateListenerCalls, 0);

      controller.updateLocal(constraint: const LifecycleConstraint.active());
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

      controller.updateLocal(constraint: const LifecycleConstraint.visible());

      expect(reportedErrors, hasLength(1));
      expect(reportedErrors.single.exception, isA<StateError>());
      expect(controller.value.phase, LifecyclePhase.visible);
      expect(transitions.single.events, [LifecycleEvent.deactivated]);

      transitions.clear();
      controller.updateLocal(constraint: const LifecycleConstraint.active());

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

      controller.updateLocal(constraint: const LifecycleConstraint.visible());

      expect(events, [
        LifecycleEvent.deactivated,
        LifecycleEvent.disappeared,
        LifecycleEvent.disposed,
      ]);
      expect(controller.isDisposed, isTrue);
      expect(transitions.last.current.appState, AppLifecycleState.resumed);
      parent.dispose();
    });

    // 验证约束只能表达 hidden、visible、active 三种规范状态，并拒绝非法比例。
    test('constraint rejects invalid visible fractions', () {
      expect(const LifecycleConstraint.hidden().visibleFraction, 0);
      expect(
        () => LifecycleConstraint.visible(visibleFraction: double.nan),
        throwsAssertionError,
      );
      expect(
        () => LifecycleConstraint.visible(visibleFraction: 0),
        throwsAssertionError,
      );
      expect(
        () => LifecycleConstraint.active(visibleFraction: 2),
        throwsAssertionError,
      );
    });

    // 验证规范化约束按 phase 和比例进行值比较，并能从 controller 读取当前本地约束。
    test('constraint implements value equality and diagnostics', () {
      final first = LifecycleConstraint.visible(visibleFraction: 0.5);
      final same = LifecycleConstraint.visible(visibleFraction: 0.5);
      final differentFraction =
          LifecycleConstraint.visible(visibleFraction: 0.75);
      final differentPhase = LifecycleConstraint.active(visibleFraction: 0.5);
      final controller = LifecycleController(constraint: first)..attach();

      expect(first, same);
      expect(first.hashCode, same.hashCode);
      expect(first, isNot(differentFraction));
      expect(first, isNot(differentPhase));
      expect(first, isNot('visible'));
      expect(first.toString(), contains('visibleFraction: 0.5'));
      expect(controller.localConstraint, first);

      controller.updateLocal(constraint: differentPhase);
      expect(controller.localConstraint, differentPhase);
      controller.dispose();
    });

    // 验证 controller 销毁后不允许更新、重新挂接或新增监听器。
    test('rejects updates after disposal', () {
      final controller = LifecycleController()..attach();
      controller.dispose();

      expect(
        () => controller.updateLocal(
          constraint: const LifecycleConstraint.hidden(),
        ),
        throwsStateError,
      );
      expect(() => controller.attach(), throwsStateError);
      expect(() => controller.addListener(() {}), throwsFlutterError);
    });

    // 验证快照按字段进行值比较，并在诊断字符串中输出关键状态。
    test('snapshot implements value equality and diagnostics', () {
      const first = LifecycleSnapshot.visible(
        visibleFraction: 0.5,
      );
      const second = LifecycleSnapshot.visible(
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
        LifecyclePhase.hidden: LifecycleSnapshot.hidden(),
        LifecyclePhase.visible: LifecycleSnapshot.visible(
          visibleFraction: 0.5,
        ),
        LifecyclePhase.active: LifecycleSnapshot.active(),
        LifecyclePhase.disposed: LifecycleSnapshot.disposed(),
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

    // 验证命名构造器固定 phase，并拒绝 visible/active 的非法可见比例。
    test('snapshot named constructors enforce their phase invariants', () {
      expect(
        () => LifecycleSnapshot.visible(visibleFraction: 0),
        throwsAssertionError,
      );
      expect(
        () => LifecycleSnapshot.active(visibleFraction: double.nan),
        throwsAssertionError,
      );
      expect(const LifecycleSnapshot.hidden().phase, LifecyclePhase.hidden);
      expect(
        const LifecycleSnapshot.disposed().phase,
        LifecyclePhase.disposed,
      );
    });

    // 验证 transition 会复制并冻结事件列表，同时提供事件查询和诊断信息。
    test('transition exposes immutable events and diagnostics', () {
      final events = <LifecycleEvent>[LifecycleEvent.appeared];
      final transition = LifecycleTransition(
        previous: const LifecycleSnapshot.detached(),
        current: const LifecycleSnapshot.visible(
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

    // 使用固定 seed 随机组合约束、App 状态和 reparent，验证实现始终符合独立参考模型且 transition 连续。
    test('matches the lifecycle model across randomized state changes', () {
      const seed = 0x1C1EC0DE;
      final random = math.Random(seed);
      final firstRoot = LifecycleController(
        appState: AppLifecycleState.resumed,
      )..attach();
      final secondRoot = LifecycleController(
        constraint: const LifecycleConstraint.visible(visibleFraction: 0.7),
        appState: AppLifecycleState.inactive,
      )..attach();
      final child = LifecycleController()..attach(parent: firstRoot);
      final controllers = [firstRoot, secondRoot, child];
      final constraints = <LifecycleController, LifecycleConstraint>{
        firstRoot: const LifecycleConstraint.active(),
        secondRoot: const LifecycleConstraint.visible(visibleFraction: 0.7),
        child: const LifecycleConstraint.active(),
      };
      final appStates = <LifecycleController, AppLifecycleState?>{
        firstRoot: AppLifecycleState.resumed,
        secondRoot: AppLifecycleState.inactive,
        child: null,
      };
      final parents = <LifecycleController, LifecycleController?>{
        firstRoot: null,
        secondRoot: null,
        child: firstRoot,
      };
      final lastSnapshots = <LifecycleController, LifecycleSnapshot>{
        for (final controller in controllers) controller: controller.value,
      };

      LifecycleSnapshot modelFor(LifecycleController controller) {
        final parent = parents[controller];
        final parentSnapshot = parent == null ? null : modelFor(parent);
        final constraint = constraints[controller]!;
        final fraction = math.min(
          constraint.visibleFraction,
          parentSnapshot?.visibleFraction ?? 1,
        );
        final visible = constraint.visible &&
            (parentSnapshot?.visible ?? true) &&
            fraction > 0;
        final active =
            visible && constraint.active && (parentSnapshot?.active ?? true);
        final appState = appStates[controller] ?? parentSnapshot?.appState;
        if (active) {
          return LifecycleSnapshot.active(
            visibleFraction: fraction,
            appState: appState,
          );
        }
        if (visible) {
          return LifecycleSnapshot.visible(
            visibleFraction: fraction,
            appState: appState,
          );
        }
        return LifecycleSnapshot.hidden(appState: appState);
      }

      for (final controller in controllers) {
        controller.addListener(() {
          final transition = controller.lastTransition!;
          expect(transition.previous, lastSnapshots[controller]);
          expect(
            transition.events,
            lifecycleEventsBetween(transition.previous, transition.current),
          );
          expect(transition.current, controller.value);
          lastSnapshots[controller] = transition.current;
        });
      }

      LifecycleConstraint randomConstraint() {
        final fraction = (random.nextInt(100) + 1) / 100;
        return switch (random.nextInt(3)) {
          0 => const LifecycleConstraint.hidden(),
          1 => LifecycleConstraint.visible(visibleFraction: fraction),
          _ => LifecycleConstraint.active(visibleFraction: fraction),
        };
      }

      const appStateValues = AppLifecycleState.values;
      for (var iteration = 0; iteration < 1000; iteration++) {
        switch (random.nextInt(4)) {
          case 0:
          case 1:
            final target = controllers[random.nextInt(controllers.length)];
            final constraint = randomConstraint();
            constraints[target] = constraint;
            target.updateLocal(
              constraint: constraint,
              cause: LifecycleCause.custom,
            );
          case 2:
            final target = controllers[random.nextInt(controllers.length)];
            final state = appStateValues[random.nextInt(appStateValues.length)];
            appStates[target] = state;
            target.updateLocal(
              appState: state,
              cause: LifecycleCause.app,
            );
          case 3:
            final nextParent = [null, firstRoot, secondRoot][random.nextInt(3)];
            parents[child] = nextParent;
            child.reparent(nextParent, cause: LifecycleCause.widgetTree);
        }

        for (final controller in controllers) {
          expect(
            controller.value,
            modelFor(controller),
            reason: 'seed=$seed iteration=$iteration '
                'controller=${controller.debugLabel ?? controllers.indexOf(controller)}',
          );
          expect(controller.value.visibleFraction, inInclusiveRange(0, 1));
        }
      }

      child.dispose();
      firstRoot.dispose();
      secondRoot.dispose();
    });
  });

  // 验证 observer 在 Scope 挂载前仍会记录 Route，并通过只读查询 API 暴露隐藏状态。
  test('NavigatorLifecycleController exposes read-only route state', () {
    final navigation = NavigatorLifecycleController();
    final route = PageRouteBuilder<void>(
      settings: const RouteSettings(name: '/unit'),
      pageBuilder: (context, animation, secondaryAnimation) =>
          const SizedBox.shrink(),
    );

    navigation.observer.didPush(route, null);
    expect(navigation.lifecycleFor(route)!.phase, LifecyclePhase.hidden);
    expect(navigation.routes, [route]);
    expect(navigation.routeNamed('/unit'), same(route));
    expect(() => navigation.routes.clear(), throwsUnsupportedError);

    navigation.dispose();
  });

  // 验证 didReplace 重复传入历史中已有 Route 时不会创建重复 entry 或破坏栈顺序。
  test('ignores replacement with an already tracked route', () {
    final navigation = NavigatorLifecycleController();
    final first = PageRouteBuilder<void>(
      settings: const RouteSettings(name: '/first'),
      pageBuilder: (context, animation, secondaryAnimation) =>
          const SizedBox.shrink(),
    );
    final second = PageRouteBuilder<void>(
      settings: const RouteSettings(name: '/second'),
      pageBuilder: (context, animation, secondaryAnimation) =>
          const SizedBox.shrink(),
    );

    navigation.observer
      ..didPush(first, null)
      ..didPush(second, first);
    navigation.observer.didReplace(newRoute: first, oldRoute: second);

    expect(navigation.routes, [first, second]);
    expect(navigation.lifecycleFor(first), isNotNull);
    expect(navigation.lifecycleFor(second), isNotNull);
    navigation.dispose();
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

    navigation.observer
      ..didPush(first, null)
      ..didPush(second, first)
      ..didChangeTop(first, second);
    expect(navigation.routes.last, same(first));

    navigation.observer.didStartUserGesture(first, second);
    navigation.observer.didRemove(second, first);
    navigation.observer.didStopUserGesture();
    expect(navigation.lifecycleFor(second), isNull);

    navigation.dispose();
    expect(() => navigation.observer.didPush(first, null), throwsStateError);
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

List<LifecycleEvent> lifecycleEventsBetween(
  LifecycleSnapshot previous,
  LifecycleSnapshot current,
) {
  return [
    if (!previous.attached && current.attached) LifecycleEvent.created,
    if (previous.active && !current.active) LifecycleEvent.deactivated,
    if (previous.visible && !current.visible) LifecycleEvent.disappeared,
    if (!previous.visible && current.visible) LifecycleEvent.appeared,
    if (!previous.active && current.active) LifecycleEvent.activated,
    if (previous.phase != LifecyclePhase.disposed &&
        current.phase == LifecyclePhase.disposed)
      LifecycleEvent.disposed,
  ];
}
