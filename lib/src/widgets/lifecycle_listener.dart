import 'package:flutter/widgets.dart';

import '../core/lifecycle_node_binding.dart';
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
  late final LifecycleNodeBinding _node;

  @override
  void initState() {
    super.initState();
    _node = LifecycleNodeBinding(
      debugLabel: 'LifecycleListener',
      onChanged: _handleChanged,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _node.syncParent(context);
  }

  void _handleChanged() {
    _node.dispatch(
      onTransition: widget.onTransition,
      onEvent: widget.onEvent,
    );
  }

  @override
  Widget build(BuildContext context) => widget.child;

  @override
  void dispose() {
    _node.dispose();
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
  late final LifecycleNodeBinding _node;

  @override
  void initState() {
    super.initState();
    _node = LifecycleNodeBinding(
      debugLabel: 'LifecycleBuilder',
      onChanged: _handleChanged,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _node.syncParent(context);
  }

  void _handleChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context, _node.value);
  }

  @override
  void dispose() {
    // 销毁时会先解除 rebuild 回调，避免在 dispose() 期间_handleChanged()触发无意义的 setState()
    _node.dispose(deliverTerminalTransition: false);
    super.dispose();
  }
}
