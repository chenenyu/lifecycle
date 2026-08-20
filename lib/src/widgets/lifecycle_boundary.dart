import 'package:flutter/widgets.dart';

import '../core/lifecycle_event.dart';
import '../core/lifecycle_node_binding.dart';
import '../core/lifecycle_scope.dart';
import '../core/lifecycle_transition.dart';

/// Adds custom local visibility and activity restrictions to a subtree.
class LifecycleBoundary extends StatefulWidget {
  /// Creates a custom lifecycle boundary.
  const LifecycleBoundary({
    super.key,
    this.visible = true,
    this.active = true,
    this.visibleFraction = 1,
    this.cause = LifecycleCause.custom,
    this.onTransition,
    this.onEvent,
    required this.child,
  });

  /// Local visibility restriction.
  final bool visible;

  /// Local activity restriction.
  final bool active;

  /// Local visible fraction in the range 0–1.
  final double visibleFraction;

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
      visible: widget.visible,
      active: widget.active,
      visibleFraction: widget.visibleFraction,
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
    if (oldWidget.visible != widget.visible ||
        oldWidget.active != widget.active ||
        oldWidget.visibleFraction != widget.visibleFraction) {
      _node.update(
        visible: widget.visible,
        active: widget.active,
        visibleFraction: widget.visibleFraction,
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
      context: context,
      kind: LifecycleScopeKind.custom,
      child: widget.child,
    );
  }

  @override
  void dispose() {
    _node.dispose();
    super.dispose();
  }
}
