/*
 * 将 Flutter 的 AppLifecycleState 转换为生命周期树的根约束。
 *
 * Controller 通过 WidgetsBindingObserver 接收平台状态，再原子更新 appState 与
 * LifecycleConstraint：resumed 为 active，inactive 为 visible，其余状态为 hidden。
 * 这种单一映射入口可避免应用状态与可见/活跃状态分别更新造成短暂矛盾。
 */
import 'package:flutter/widgets.dart';

import '../core/lifecycle_constraint.dart';
import '../core/lifecycle_controller.dart';
import '../core/lifecycle_event.dart';

/// Root controller that maps [AppLifecycleState] into lifecycle snapshots.
class AppLifecycleController extends LifecycleController
    with WidgetsBindingObserver {
  /// Creates and registers an application lifecycle observer.
  AppLifecycleController({String? debugLabel})
      : super(
          appState: WidgetsBinding.instance.lifecycleState ??
              AppLifecycleState.resumed,
          debugLabel: debugLabel ?? 'AppLifecycleController',
        ) {
    WidgetsBinding.instance.addObserver(this);
    final state =
        WidgetsBinding.instance.lifecycleState ?? AppLifecycleState.resumed;
    _applyAppState(state);
    attach(cause: LifecycleCause.app);
  }

  /// The most recent application lifecycle state.
  AppLifecycleState get appState => value.appState ?? AppLifecycleState.resumed;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _applyAppState(state);
  }

  void _applyAppState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        updateLocal(
          constraint: const LifecycleConstraint.active(),
          appState: state,
          cause: LifecycleCause.app,
        );
        return;
      case AppLifecycleState.inactive:
        updateLocal(
          constraint: const LifecycleConstraint.visible(),
          appState: state,
          cause: LifecycleCause.app,
        );
        return;
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        updateLocal(
          constraint: const LifecycleConstraint.hidden(),
          appState: state,
          cause: LifecycleCause.app,
        );
        return;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
