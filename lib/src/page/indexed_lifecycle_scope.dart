/*
 * PageView 与 TabBarView 共用的索引节点注册表和作用域。
 *
 * Registry 只保存已实例化页面，容器通过 resolveConstraint 按 index 提供最新约束；
 * 页面 State 保持自己的 Controller 身份，重排或懒加载时不会因 rebuild 丢失生命周期。
 * 集中同步还能避免两个分页组件分别维护相同的 host 列表。
 */
import 'package:flutter/widgets.dart';

import '../core/lifecycle_constraint.dart';
import '../core/lifecycle_event.dart';
import '../core/lifecycle_node_binding.dart';
import '../core/lifecycle_transition.dart';

/// Receives a lifecycle transition for a page or tab at [index].
typedef IndexedLifecycleTransitionCallback = void Function(
    int index, LifecycleTransition transition);

/// 已实例化索引节点的轻量注册表；不会主动创建离屏页面。
class IndexedLifecycleRegistry {
  LifecycleConstraint Function(int index)? resolveConstraint;
  final Set<IndexedLifecycleScopeState> _hosts = {};

  void register(IndexedLifecycleScopeState host) {
    _hosts.add(host);
    syncHost(host);
  }

  void unregister(IndexedLifecycleScopeState host) {
    _hosts.remove(host);
  }

  void syncHost(IndexedLifecycleScopeState host) {
    final constraint = resolveConstraint?.call(host.widget.index);
    if (constraint != null) host.applyConstraint(constraint);
  }

  void syncAll() {
    for (final host in List<IndexedLifecycleScopeState>.of(_hosts)) {
      syncHost(host);
    }
  }
}

/// 为单个 index 安装稳定生命周期节点。
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

/// 在 registry 变化或 index 重排时迁移注册关系，并保留 Controller 身份。
class IndexedLifecycleScopeState extends State<IndexedLifecycleScope> {
  late final LifecycleNodeBinding _node;

  @override
  void initState() {
    super.initState();
    _node = LifecycleNodeBinding(
      constraint: const LifecycleConstraint.hidden(),
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

  void applyConstraint(LifecycleConstraint constraint) {
    _node.update(
      constraint: constraint,
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
