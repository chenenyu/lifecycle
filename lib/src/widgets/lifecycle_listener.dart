import 'package:flutter/widgets.dart';

import '../core/lifecycle_controller.dart';
import '../core/lifecycle_scope.dart';
import '../core/lifecycle_snapshot.dart';
import '../core/lifecycle_transition.dart';

/// Delivers effective lifecycle transitions for a widget subtree.
class LifecycleListener extends StatefulWidget {
  /// Creates a lifecycle listener.
  const LifecycleListener({
    super.key,
    this.onTransition,
    this.onEvent,
    required this.child,
  });

  /// Called once for every changed snapshot.
  final LifecycleTransitionCallback? onTransition;

  /// Called for every semantic event in a transition.
  final LifecycleEventCallback? onEvent;

  /// Widget below the listener.
  final Widget child;

  @override
  State<LifecycleListener> createState() => _LifecycleListenerState();
}

class _LifecycleListenerState extends State<LifecycleListener> {
  late final LifecycleController _controller;

  @override
  void initState() {
    super.initState();
    _controller = LifecycleController(debugLabel: 'LifecycleListener')
      ..addTransitionListener(_handleTransition);
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
  Widget build(BuildContext context) => widget.child;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

/// Rebuilds from the effective lifecycle snapshot.
class LifecycleBuilder extends StatefulWidget {
  /// Creates a lifecycle builder.
  const LifecycleBuilder({super.key, required this.builder});

  /// Builds a widget from the latest effective lifecycle state.
  final Widget Function(BuildContext context, LifecycleSnapshot lifecycle)
      builder;

  @override
  State<LifecycleBuilder> createState() => _LifecycleBuilderState();
}

class _LifecycleBuilderState extends State<LifecycleBuilder> {
  late final LifecycleController _controller;

  @override
  void initState() {
    super.initState();
    _controller = LifecycleController(debugLabel: 'LifecycleBuilder')
      ..addListener(_handleChanged);
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

  void _handleChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context, _controller.value);
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_handleChanged)
      ..dispose();
    super.dispose();
  }
}
