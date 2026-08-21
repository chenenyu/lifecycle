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
