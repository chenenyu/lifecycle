import 'package:flutter/widgets.dart';

import '../core/lifecycle_event.dart';
import '../core/lifecycle_node_binding.dart';
import '../core/lifecycle_transition.dart';

/// Receives a lifecycle transition for a page or tab at [index].
typedef IndexedLifecycleTransitionCallback = void Function(
    int index, LifecycleTransition transition);

class IndexedLifecycleSignal {
  const IndexedLifecycleSignal({
    required this.visibleFraction,
    required this.active,
  });

  final double visibleFraction;
  final bool active;
}

class IndexedLifecycleRegistry {
  IndexedLifecycleSignal Function(int index)? resolveSignal;
  final Set<IndexedLifecycleScopeState> _hosts = {};

  void register(IndexedLifecycleScopeState host) {
    _hosts.add(host);
    syncHost(host);
  }

  void unregister(IndexedLifecycleScopeState host) {
    _hosts.remove(host);
  }

  void syncHost(IndexedLifecycleScopeState host) {
    final signal = resolveSignal?.call(host.widget.index);
    if (signal != null) host.applySignal(signal);
  }

  void syncAll() {
    for (final host in List<IndexedLifecycleScopeState>.of(_hosts)) {
      syncHost(host);
    }
  }
}

class IndexedLifecycleScope extends StatefulWidget {
  const IndexedLifecycleScope({
    super.key,
    required this.index,
    required this.registry,
    required this.cause,
    this.onTransition,
    required this.child,
  });

  final int index;
  final IndexedLifecycleRegistry registry;
  final LifecycleCause cause;
  final IndexedLifecycleTransitionCallback? onTransition;
  final Widget child;

  @override
  State<IndexedLifecycleScope> createState() => IndexedLifecycleScopeState();
}

class IndexedLifecycleScopeState extends State<IndexedLifecycleScope> {
  late final LifecycleNodeBinding _node;

  @override
  void initState() {
    super.initState();
    _node = LifecycleNodeBinding(
      visible: false,
      active: false,
      visibleFraction: 0,
      debugLabel: 'IndexedLifecycleScope(${widget.index})',
      onChanged: _handleChanged,
    );
    widget.registry.register(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _node.syncParent(context, cause: widget.cause);
  }

  @override
  void didUpdateWidget(IndexedLifecycleScope oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.registry != widget.registry) {
      oldWidget.registry.unregister(this);
      widget.registry.register(this);
    } else if (oldWidget.index != widget.index) {
      widget.registry.syncHost(this);
    }
  }

  void applySignal(IndexedLifecycleSignal signal) {
    _node.update(
      visible: signal.visibleFraction > 0,
      active: signal.active,
      visibleFraction: signal.visibleFraction,
      cause: widget.cause,
    );
  }

  void _handleChanged() {
    final transition = _node.lastTransition;
    if (transition == null) return;
    widget.onTransition?.call(widget.index, transition);
  }

  @override
  Widget build(BuildContext context) {
    return _node.buildScope(
      child: widget.child,
    );
  }

  @override
  void dispose() {
    widget.registry.unregister(this);
    _node.dispose();
    super.dispose();
  }
}
