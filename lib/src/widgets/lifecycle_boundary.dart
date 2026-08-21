import 'package:flutter/widgets.dart';

import '../core/lifecycle_constraint.dart';
import '../core/lifecycle_event.dart';
import '../core/lifecycle_node_binding.dart';
import '../core/lifecycle_transition.dart';

/// Adds custom local visibility and activity restrictions to a subtree.
class LifecycleBoundary extends StatefulWidget {
  /// Creates a custom lifecycle boundary.
  const LifecycleBoundary({
    super.key,
    this.constraint = const LifecycleConstraint.active(),
    this.cause = LifecycleCause.custom,
    this.onTransition,
    this.onEvent,
    required this.child,
  });

  /// Normalized local restriction composed with the parent lifecycle.
  final LifecycleConstraint constraint;

  /// Cause reported for boundary updates.
  final LifecycleCause cause;

  /// Called once for every boundary transition.
  final LifecycleTransitionCallback? onTransition;

  /// Called for every semantic event emitted by the boundary.
  final LifecycleEventCallback? onEvent;

  /// Subtree restricted by the boundary.
  final Widget child;

  @override
  State<LifecycleBoundary> createState() => _LifecycleBoundaryState();
}

class _LifecycleBoundaryState extends State<LifecycleBoundary> {
  late final LifecycleNodeBinding _node;

  @override
  void initState() {
    super.initState();
    _node = LifecycleNodeBinding(
      constraint: widget.constraint,
      debugLabel: 'LifecycleBoundary',
      onChanged: _handleChanged,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _node.syncParent(context);
  }

  @override
  void didUpdateWidget(LifecycleBoundary oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.constraint != widget.constraint) {
      _node.update(
        constraint: widget.constraint,
        cause: widget.cause,
      );
    }
  }

  void _handleChanged() {
    _node.dispatch(
      onTransition: widget.onTransition,
      onEvent: widget.onEvent,
    );
  }

  @override
  Widget build(BuildContext context) {
    return _node.buildScope(
      child: widget.child,
    );
  }

  @override
  void dispose() {
    _node.dispose();
    super.dispose();
  }
}
