/*
 * 为 Flutter PageView 的每个已实例化页面安装可组合生命周期节点。
 *
 * PageController.page 决定相邻页面的可见比例；拖动中页面保持 visible，滚动结束且命中
 * selectedIndex 后才 active。稳定 page ID 与 findChildIndex 配对，规避列表重排时
 * State 和生命周期身份错配；Controller 替换时会迁移监听并重新同步初始页。
 */
// ignore_for_file: prefer_initializing_formals

import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../core/lifecycle_constraint.dart';
import '../core/lifecycle_event.dart';
import 'indexed_lifecycle_scope.dart';

/// Produces a stable identity for a lazily built page.
typedef LifecyclePageIdBuilder = Object Function(int index);

/// Resolves the current index of a stable page identity after reordering.
typedef LifecyclePageIndexResolver = int? Function(Object pageId);

class _LifecyclePageKey extends ValueKey<Object> {
  const _LifecyclePageKey(super.value);
}

/// A PageView whose children inherit composable page lifecycle scopes.
class LifecyclePageView extends StatefulWidget {
  /// Creates a lifecycle PageView from a fixed list of [children].
  const LifecyclePageView({
    super.key,
    required this.controller,
    required List<Widget> children,
    this.pageIdBuilder,
    this.findPageIndex,
    this.onPageChanged,
    this.onPageTransition,
    this.scrollDirection = Axis.horizontal,
    this.reverse = false,
    this.physics,
    this.pageSnapping = true,
    this.allowImplicitScrolling = false,
    this.padEnds = true,
  })  : children = children,
        itemBuilder = null,
        itemCount = children.length;

  /// Creates a lazy lifecycle PageView.
  const LifecyclePageView.builder({
    super.key,
    required this.controller,
    required this.itemCount,
    required IndexedWidgetBuilder this.itemBuilder,
    this.pageIdBuilder,
    this.findPageIndex,
    this.onPageChanged,
    this.onPageTransition,
    this.scrollDirection = Axis.horizontal,
    this.reverse = false,
    this.physics,
    this.pageSnapping = true,
    this.allowImplicitScrolling = false,
    this.padEnds = true,
  })  : assert(itemCount >= 0),
        children = null;

  /// Page controller used by both scrolling and lifecycle calculation.
  final PageController controller;

  /// Fixed child list, or null for the builder constructor.
  final List<Widget>? children;

  /// Lazy item builder, or null for the fixed-list constructor.
  final IndexedWidgetBuilder? itemBuilder;

  /// Number of pages available to the view.
  final int itemCount;

  /// Optional stable ID builder for lazy or reorderable pages.
  final LifecyclePageIdBuilder? pageIdBuilder;

  /// Reverse lookup paired with [pageIdBuilder] when order can change.
  final LifecyclePageIndexResolver? findPageIndex;

  /// Called when the centered page changes.
  final ValueChanged<int>? onPageChanged;

  /// Called for lifecycle transitions from instantiated pages.
  final IndexedLifecycleTransitionCallback? onPageTransition;

  /// Axis along which pages scroll.
  final Axis scrollDirection;

  /// Whether the page order is reversed along [scrollDirection].
  final bool reverse;

  /// Scroll physics forwarded to Flutter's PageView.
  final ScrollPhysics? physics;

  /// Whether scrolling settles on page boundaries.
  final bool pageSnapping;

  /// Whether accessibility focus may implicitly scroll to a page.
  final bool allowImplicitScrolling;

  /// Whether the first and last pages are centered in the viewport.
  final bool padEnds;

  @override
  State<LifecyclePageView> createState() => _LifecyclePageViewState();
}

class _LifecyclePageViewState extends State<LifecyclePageView> {
  final IndexedLifecycleRegistry _registry = IndexedLifecycleRegistry();
  late int _selectedIndex;
  bool _scrolling = false;

  @override
  void initState() {
    super.initState();
    _selectedIndex = _clampIndex(widget.controller.initialPage);
    _registry.resolveConstraint = _constraintFor;
    widget.controller.addListener(_syncPages);
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncPages());
  }

  @override
  void didUpdateWidget(LifecyclePageView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_syncPages);
      _selectedIndex = _clampIndex(widget.controller.initialPage);
      _scrolling = false;
      widget.controller.addListener(_syncPages);
      final controller = widget.controller;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !identical(controller, widget.controller)) return;
        if (controller.hasClients) {
          _selectedIndex = _clampIndex(
            (controller.page ?? controller.initialPage.toDouble()).round(),
          );
        }
        _syncPages();
      });
    }
    if (oldWidget.itemCount != widget.itemCount) {
      _selectedIndex = _clampIndex(_selectedIndex);
      WidgetsBinding.instance.addPostFrameCallback((_) => _syncPages());
    }
  }

  double get _page {
    // Controller 尚未 attach 时 page 为 null，回退 initialPage 可让首帧约束保持确定。
    if (widget.itemCount == 0) return 0;
    final rawPage = !widget.controller.hasClients
        ? widget.controller.initialPage.toDouble()
        : widget.controller.page ?? widget.controller.initialPage.toDouble();
    return rawPage.clamp(0.0, (widget.itemCount - 1).toDouble()).toDouble();
  }

  int _clampIndex(int index) {
    if (widget.itemCount == 0) return 0;
    return index.clamp(0, widget.itemCount - 1);
  }

  Object _pageId(int index, Widget child) {
    return widget.pageIdBuilder?.call(index) ?? child.key ?? index;
  }

  int? _findChildIndex(Key key) {
    if (key is! _LifecyclePageKey) return null;
    final resolver = widget.findPageIndex;
    if (resolver != null) {
      final index = resolver(key.value);
      if (index == null || index < 0 || index >= widget.itemCount) return null;
      return index;
    }

    final children = widget.children;
    if (children == null) return null;
    for (var index = 0; index < children.length; index++) {
      if (_pageId(index, children[index]) == key.value) return index;
    }
    return null;
  }

  LifecycleConstraint _constraintFor(int index) {
    // 相邻页按到当前浮点 page 的距离线性计算比例；滚动期间所有页面保持 inactive。
    final fraction = math.max(0.0, 1 - (_page - index).abs());
    if (fraction <= 0) return const LifecycleConstraint.hidden();
    if (!_scrolling && index == _selectedIndex) {
      return LifecycleConstraint.active(visibleFraction: fraction);
    }
    return LifecycleConstraint.visible(visibleFraction: fraction);
  }

  void _syncPages() {
    if (!mounted) return;
    _registry.syncAll();
  }

  bool _handleScrollNotification(ScrollNotification notification) {
    // 只处理本 PageView 的 PageMetrics，忽略页面内部嵌套 Scrollable 的通知。
    final metrics = notification.metrics;
    if (notification.depth != 0 || metrics is! PageMetrics) {
      return false;
    }
    if (notification is ScrollStartNotification) {
      _scrolling = true;
    } else if (notification is ScrollEndNotification) {
      _scrolling = false;
      _selectedIndex = _clampIndex(metrics.page?.round() ?? _selectedIndex);
    }
    _syncPages();
    return false;
  }

  void _handlePageChanged(int index) {
    _selectedIndex = _clampIndex(index);
    widget.onPageChanged?.call(index);
    _syncPages();
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: _handleScrollNotification,
      child: PageView.builder(
        controller: widget.controller,
        itemCount: widget.itemCount,
        scrollDirection: widget.scrollDirection,
        reverse: widget.reverse,
        physics: widget.physics,
        pageSnapping: widget.pageSnapping,
        allowImplicitScrolling: widget.allowImplicitScrolling,
        padEnds: widget.padEnds,
        onPageChanged: _handlePageChanged,
        findChildIndexCallback: _findChildIndex,
        itemBuilder: (context, index) {
          final child = widget.children?[index] ??
              widget.itemBuilder!.call(context, index);
          final id = _pageId(index, child);
          return IndexedLifecycleScope(
            key: _LifecyclePageKey(id),
            index: index,
            registry: _registry,
            cause: LifecycleCause.pageSelection,
            onTransition: widget.onPageTransition,
            child: child,
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    widget.controller.removeListener(_syncPages);
    super.dispose();
  }
}
