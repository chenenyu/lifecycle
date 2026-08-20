import 'package:flutter/widgets.dart';

import '../core/lifecycle_event.dart';
import '../core/lifecycle_node_binding.dart';
import '../core/lifecycle_snapshot.dart';
import '../core/lifecycle_transition.dart';

/// Adds composable lifecycle callbacks to a Flutter [State].
mixin LifecycleStateMixin<T extends StatefulWidget> on State<T> {
  late final LifecycleNodeBinding _lifecycleNode;

  /// The latest effective lifecycle state of this [State].
  LifecycleSnapshot get lifecycle => _lifecycleNode.value;

  @override
  void initState() {
    super.initState();
    _lifecycleNode = LifecycleNodeBinding(
      debugLabel: '$runtimeType',
      onChanged: _dispatchLifecycleTransition,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _lifecycleNode.syncParent(context);
  }

  void _dispatchLifecycleTransition() {
    final transition = _lifecycleNode.lastTransition;
    if (transition == null) return;
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
    _lifecycleNode.dispose();
    super.dispose();
  }
}
