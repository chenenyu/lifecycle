import 'package:flutter/widgets.dart';

import '../core/lifecycle_controller.dart';
import '../core/lifecycle_event.dart';
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
  late final LifecycleController _controller;

  @override
  void initState() {
    super.initState();
    _controller = LifecycleController(
      visible: widget.visible,
      active: widget.active,
      visibleFraction: widget.visibleFraction,
      debugLabel: 'LifecycleBoundary',
    )..addTransitionListener(_handleTransition);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final parent = resolveLifecycleParent(context);
    if (_controller.isAttached) {
      _controller.reparent(parent);
    } else {
      _controller.attach(parent: parent);
    }
  }

  @override
  void didUpdateWidget(LifecycleBoundary oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.visible != widget.visible ||
        oldWidget.active != widget.active ||
        oldWidget.visibleFraction != widget.visibleFraction) {
      _controller.updateLocal(
        visible: widget.visible,
        active: widget.active,
        visibleFraction: widget.visibleFraction,
        cause: widget.cause,
      );
    }
  }

  void _handleTransition(LifecycleTransition transition) {
    widget.onTransition?.call(transition);
    final onEvent = widget.onEvent;
    if (onEvent != null) {
      for (final event in transition.events) {
        onEvent(event, transition);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return LifecycleScope(
      controller: _controller,
      kind: LifecycleScopeKind.custom,
      route: ModalRoute.of(context),
      child: widget.child,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
