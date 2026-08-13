import 'package:flutter/widgets.dart';

import '../core/lifecycle_controller.dart';
import '../core/lifecycle_event.dart';
import '../core/lifecycle_scope.dart';
import '../core/lifecycle_snapshot.dart';
import '../core/lifecycle_transition.dart';

/// Adds composable lifecycle callbacks to a Flutter [State].
mixin LifecycleStateMixin<T extends StatefulWidget> on State<T> {
  late final LifecycleController _lifecycleController;

  /// The latest effective lifecycle state of this [State].
  LifecycleSnapshot get lifecycle => _lifecycleController.value;

  @override
  void initState() {
    super.initState();
    _lifecycleController = LifecycleController(debugLabel: '$runtimeType')
      ..addTransitionListener(_dispatchLifecycleTransition);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final parent = resolveLifecycleParent(context);
    if (_lifecycleController.isAttached) {
      _lifecycleController.reparent(parent);
    } else {
      _lifecycleController.attach(parent: parent);
    }
  }

  void _dispatchLifecycleTransition(LifecycleTransition transition) {
    onLifecycleTransition(transition);
    for (final event in transition.events) {
      onLifecycleEvent(event, transition);
    }
  }

  /// Called once for each changed lifecycle snapshot.
  @protected
  void onLifecycleTransition(LifecycleTransition transition) {}

  /// Called for each ordered semantic event in [transition].
  @protected
  void onLifecycleEvent(LifecycleEvent event, LifecycleTransition transition) {}

  @override
  void dispose() {
    _lifecycleController.dispose();
    super.dispose();
  }
}
