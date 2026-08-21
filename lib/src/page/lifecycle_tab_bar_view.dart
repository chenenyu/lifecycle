/*
 * 为 TabBarView 的每个 Tab 安装索引生命周期节点。
 *
 * 同时监听 TabController 与 animation，使用动画值计算相邻 Tab 的可见比例；只有
 * indexIsChanging 为 false 且 offset 归零时选中 Tab 才 active。Controller 替换时成对
 * 移除/添加两类监听，防止旧动画继续驱动新界面。
 */
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/lifecycle_constraint.dart';
import '../core/lifecycle_event.dart';
import 'indexed_lifecycle_scope.dart';

/// A TabBarView whose tabs inherit composable page lifecycle scopes.
class LifecycleTabBarView extends StatefulWidget {
  /// Creates a lifecycle-aware TabBarView.
  const LifecycleTabBarView({
    super.key,
    required this.controller,
    required this.children,
    this.onTabTransition,
    this.physics,
    this.clipBehavior = Clip.hardEdge,
  }) : assert(children.length == controller.length);

  /// Tab controller used for animation and lifecycle calculation.
  final TabController controller;

  /// Tab contents; length must equal [TabController.length].
  final List<Widget> children;

  /// Called for lifecycle transitions from instantiated tabs.
  final IndexedLifecycleTransitionCallback? onTabTransition;

  /// Scroll physics forwarded to Flutter's TabBarView.
  final ScrollPhysics? physics;

  /// Clipping behavior forwarded to Flutter's TabBarView.
  final Clip clipBehavior;

  @override
  State<LifecycleTabBarView> createState() => _LifecycleTabBarViewState();
}

/// 将 TabController 动画值转换为所有已实例化 Tab 的约束。
class _LifecycleTabBarViewState extends State<LifecycleTabBarView> {
  final IndexedLifecycleRegistry _registry = IndexedLifecycleRegistry();

  @override
  void initState() {
    super.initState();
    _registry.resolveConstraint = _constraintFor;
    _addControllerListener(widget.controller);
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncTabs());
  }

  @override
  void didUpdateWidget(LifecycleTabBarView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      _removeControllerListener(oldWidget.controller);
      _addControllerListener(widget.controller);
      WidgetsBinding.instance.addPostFrameCallback((_) => _syncTabs());
    }
  }

  void _addControllerListener(TabController controller) {
    controller.addListener(_syncTabs);
    controller.animation?.addListener(_syncTabs);
  }

  void _removeControllerListener(TabController controller) {
    controller.removeListener(_syncTabs);
    controller.animation?.removeListener(_syncTabs);
  }

  LifecycleConstraint _constraintFor(int index) {
    final value = widget.controller.animation?.value ??
        widget.controller.index.toDouble();
    final fraction = math.max(0.0, 1 - (value - index).abs());
    // 点击动画和手势 offset 都必须归零，选中 Tab 才能提升为 active。
    final settled = !widget.controller.indexIsChanging &&
        widget.controller.offset.abs() < 0.0001;
    if (fraction <= 0) return const LifecycleConstraint.hidden();
    if (settled && index == widget.controller.index) {
      return LifecycleConstraint.active(visibleFraction: fraction);
    }
    return LifecycleConstraint.visible(visibleFraction: fraction);
  }

  void _syncTabs() {
    if (!mounted) return;
    _registry.syncAll();
  }

  @override
  Widget build(BuildContext context) {
    return TabBarView(
      controller: widget.controller,
      physics: widget.physics,
      clipBehavior: widget.clipBehavior,
      children: [
        for (var index = 0; index < widget.children.length; index++)
          IndexedLifecycleScope(
            key: ValueKey(widget.children[index].key ?? index),
            index: index,
            registry: _registry,
            cause: LifecycleCause.pageSelection,
            onTransition: widget.onTabTransition,
            child: widget.children[index],
          ),
      ],
    );
  }

  @override
  void dispose() {
    _removeControllerListener(widget.controller);
    super.dispose();
  }
}
