import 'package:flutter/widgets.dart';

import '../core/lifecycle_controller.dart';
import '../core/lifecycle_event.dart';
import '../core/lifecycle_scope.dart';
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
  late final LifecycleController _controller;

  @override
  void initState() {
    super.initState();
    _controller = LifecycleController(
      visible: false,
      active: false,
      visibleFraction: 0,
      debugLabel: 'IndexedLifecycleScope(${widget.index})',
    )..addListener(_handleChanged);
    widget.registry.register(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final parent = resolveLifecycleParent(context);
    if (_controller.isAttached) {
      _controller.reparent(parent);
    } else {
      _controller.attach(parent: parent, cause: widget.cause);
    }
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
    _controller.updateLocal(
      visible: signal.visibleFraction > 0,
      active: signal.active,
      visibleFraction: signal.visibleFraction,
      cause: widget.cause,
    );
  }

  void _handleChanged() {
    final transition = _controller.lastTransition;
    if (transition == null) return;
    widget.onTransition?.call(widget.index, transition);
  }

  @override
  Widget build(BuildContext context) {
    return LifecycleScope(
      controller: _controller,
      kind: LifecycleScopeKind.page,
      route: ModalRoute.of(context),
      child: widget.child,
    );
  }

  @override
  void dispose() {
    widget.registry.unregister(this);
    _controller.dispose();
    super.dispose();
  }
}
