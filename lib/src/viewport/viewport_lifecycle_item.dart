/*
 * 测量 Scrollable 内元素的二维可见比例，并转换为生命周期约束。
 *
 * 同一 Scrollable 的 item 共用 Coordinator：滚动与布局信号按帧合并、viewport 几何只
 * 读取一次，再批量计算候选节点。滚动中默认禁止 active，比例按粒度稳定；Sliver
 * KeepAlive bucket 使用 parked 快速路径，既避免激活风暴和浮点抖动，也控制快速 fling
 * 时 getTransformTo 的成本。非滚动瞬时零几何会二次确认，真实滚动离屏则立即隐藏。
 */
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import '../core/lifecycle_constraint.dart';
import '../core/lifecycle_event.dart';
import '../core/lifecycle_node_binding.dart';
import '../core/lifecycle_transition.dart';

/// Controls whether a viewport item may become active during scrolling.
enum ViewportLifecycleActivationPolicy {
  /// Keep visible items inactive until their Scrollable has settled.
  whenScrollSettles,

  /// Allow items to become active as soon as they cross the active threshold.
  immediate,
}

/// Tracks the visible area of a child inside its nearest Scrollable.
class ViewportLifecycleItem extends StatefulWidget {
  /// Creates a viewport lifecycle item.
  const ViewportLifecycleItem({
    super.key,
    this.visibleThreshold = 0,
    this.activeThreshold,
    this.activationPolicy = ViewportLifecycleActivationPolicy.whenScrollSettles,
    this.visibleFractionGranularity = 0.01,
    this.onTransition,
    this.onEvent,
    required this.child,
  })  : assert(visibleThreshold >= 0 && visibleThreshold <= 1),
        assert(
          visibleFractionGranularity >= 0 && visibleFractionGranularity <= 1,
        ),
        assert(
          activeThreshold == null ||
              (activeThreshold >= visibleThreshold && activeThreshold <= 1),
        );

  /// Minimum visible fraction required for the item to be visible.
  final double visibleThreshold;

  /// Minimum visible fraction required for the item to be active.
  final double? activeThreshold;

  /// Whether threshold-qualified items can become active while scrolling.
  final ViewportLifecycleActivationPolicy activationPolicy;

  /// Step used to stabilize reported visible fractions and reduce churn.
  ///
  /// The default reports changes in one-percent increments. Set this to zero
  /// to report the exact measured fraction.
  final double visibleFractionGranularity;

  /// Called once for every changed viewport snapshot.
  final LifecycleTransitionCallback? onTransition;

  /// Called for each semantic event in a viewport transition.
  final LifecycleEventCallback? onEvent;

  /// Item whose rectangular area is measured against the viewport.
  final Widget child;

  @override
  State<ViewportLifecycleItem> createState() => _ViewportLifecycleItemState();
}

/// 保存单个 item 的稳定比例、零比例确认状态和 Coordinator 注册关系。
class _ViewportLifecycleItemState extends State<ViewportLifecycleItem> {
  late final LifecycleNodeBinding _node;
  _ViewportMeasurementCoordinator? _coordinator;
  bool _zeroFractionPending = false;
  double _appliedFraction = 0;

  @override
  void initState() {
    super.initState();
    _node = LifecycleNodeBinding(
      constraint: const LifecycleConstraint.hidden(),
      debugLabel: 'ViewportLifecycleItem',
      onChanged: _handleChanged,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _node.syncParent(context, cause: LifecycleCause.viewport);

    final scrollable = Scrollable.maybeOf(context);
    if (scrollable == null) {
      throw FlutterError(
        'ViewportLifecycleItem must be a descendant of a Scrollable widget.',
      );
    }
    final coordinator = _coordinatorFor(scrollable);
    if (_coordinator != coordinator) {
      _coordinator?.unregister(this);
      _coordinator = coordinator..register(this);
    } else {
      coordinator.scheduleMeasurement();
    }
  }

  @override
  void didUpdateWidget(ViewportLifecycleItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    _scheduleMeasurement();
  }

  void _scheduleMeasurement() {
    _coordinator?.scheduleItemMeasurement(this);
  }

  void _measureVisibility(
    _ViewportMeasurementCoordinator coordinator,
    RenderBox? viewportRenderObject,
    Rect viewportRect,
  ) {
    if (!mounted || _coordinator != coordinator) return;

    final itemRenderObject = context.findRenderObject();
    var fraction = 0.0;

    if (_isKeptAlive) {
      coordinator.didPark(this);
    } else {
      coordinator.didUnpark(this);
      if (itemRenderObject is RenderBox &&
          viewportRenderObject != null &&
          itemRenderObject.attached &&
          itemRenderObject.hasSize) {
        try {
          final transform =
              itemRenderObject.getTransformTo(viewportRenderObject);
          final itemRect = MatrixUtils.transformRect(
            transform,
            Offset.zero & itemRenderObject.size,
          );
          final intersection = itemRect.intersect(viewportRect);
          final itemArea = itemRect.width * itemRect.height;
          if (!intersection.isEmpty && itemArea > 0) {
            fraction = (intersection.width * intersection.height / itemArea)
                .clamp(0.0, 1.0)
                .toDouble();
          }
        } on FlutterError {
          fraction = 0;
        }
      }
    }

    final activeThreshold = widget.activeThreshold ?? widget.visibleThreshold;
    final visible = fraction > 0 && fraction >= widget.visibleThreshold;
    final activeWhileScrolling =
        widget.activationPolicy == ViewportLifecycleActivationPolicy.immediate;
    final active = fraction > 0 &&
        fraction >= activeThreshold &&
        (activeWhileScrolling || !coordinator.isScrolling);

    // A kept-alive scrollable can briefly report zero geometry while an outer
    // PageView reattaches it. Confirm a complete disappearance on the next
    // frame so consumers do not receive a false inactive/active pair.
    if (fraction == 0 &&
        _appliedFraction > 0 &&
        !_zeroFractionPending &&
        !coordinator.positionChangedSinceLastMeasurement) {
      _zeroFractionPending = true;
      _scheduleMeasurement();
      WidgetsBinding.instance.ensureVisualUpdate();
      return;
    }
    _zeroFractionPending = false;
    _appliedFraction = _stabilizeFraction(fraction);
    coordinator.didMeasure(this, geometricallyVisible: fraction > 0);
    final constraint = !visible
        ? const LifecycleConstraint.hidden()
        : active
            ? LifecycleConstraint.active(
                visibleFraction: _appliedFraction,
              )
            : LifecycleConstraint.visible(
                visibleFraction: _appliedFraction,
              );
    _node.update(
      constraint: constraint,
      cause: LifecycleCause.viewport,
    );
  }

  bool get _isKeptAlive {
    // KeepAlive 标记位于 Sliver 直接子节点的 ParentData；当前 RenderBox 可能被多层
    // Padding/RepaintBoundary 包裹，因此沿 RenderObject 父链查找。
    RenderObject? renderObject = context.findRenderObject();
    while (renderObject != null) {
      final parentData = renderObject.parentData;
      if (parentData is SliverMultiBoxAdaptorParentData &&
          parentData.keptAlive) {
        return true;
      }
      renderObject = renderObject.parent;
    }
    return false;
  }

  double _stabilizeFraction(double fraction) {
    if (fraction <= 0) return 0;
    final granularity = widget.visibleFractionGranularity;
    if (granularity == 0) return fraction;
    // 量化只影响对外 Snapshot；visible/active 阈值始终使用未经量化的真实 fraction。
    final quantized =
        ((fraction / granularity).round() * granularity).clamp(0.0, 1.0);
    return quantized > 0 ? quantized : granularity;
  }

  void _handleChanged() {
    _node.dispatch(
      onTransition: widget.onTransition,
      onEvent: widget.onEvent,
    );
  }

  @override
  Widget build(BuildContext context) {
    return _ViewportLayoutObserver(
      onMeasurementNeeded: _scheduleMeasurement,
      child: _node.buildScope(
        child: widget.child,
      ),
    );
  }

  @override
  void dispose() {
    _coordinator?.unregister(this);
    _coordinator = null;
    _node.dispose();
    super.dispose();
  }
}

final Map<ScrollableState, _ViewportMeasurementCoordinator>
    _viewportCoordinators = {};

_ViewportMeasurementCoordinator _coordinatorFor(ScrollableState scrollable) {
  return _viewportCoordinators.putIfAbsent(
    scrollable,
    () => _ViewportMeasurementCoordinator(scrollable),
  );
}

/// Coalesces scroll and layout invalidations for every item in one Scrollable.
class _ViewportMeasurementCoordinator {
  _ViewportMeasurementCoordinator(this.scrollable);

  final ScrollableState scrollable;
  final Set<_ViewportLifecycleItemState> _items = {};
  final Set<_ViewportLifecycleItemState> _geometricallyVisibleItems = {};
  final Set<_ViewportLifecycleItemState> _dirtyItems = {};
  final Set<_ViewportLifecycleItemState> _parkedItems = {};
  ScrollPosition? _position;
  bool _measurementScheduled = false;
  bool _positionChanged = false;

  bool get isScrolling => _position?.isScrollingNotifier.value ?? false;

  bool get positionChangedSinceLastMeasurement => _positionChanged;

  void register(_ViewportLifecycleItemState item) {
    if (!_items.add(item)) return;
    _dirtyItems.add(item);
    _syncPosition();
    scheduleMeasurement();
  }

  void unregister(_ViewportLifecycleItemState item) {
    if (!_items.remove(item)) return;
    _dirtyItems.remove(item);
    _geometricallyVisibleItems.remove(item);
    _parkedItems.remove(item);
    if (_items.isNotEmpty) return;
    _position?.removeListener(_handlePositionChanged);
    _position?.isScrollingNotifier.removeListener(_handleScrollingChanged);
    _position = null;
    _viewportCoordinators.remove(scrollable);
  }

  void _syncPosition() {
    final nextPosition = scrollable.position;
    if (_position == nextPosition) return;
    _position?.removeListener(_handlePositionChanged);
    _position?.isScrollingNotifier.removeListener(_handleScrollingChanged);
    _position = nextPosition..addListener(_handlePositionChanged);
    nextPosition.isScrollingNotifier.addListener(_handleScrollingChanged);
  }

  void _handlePositionChanged() {
    // 标记本批由真实滚动触发，使离屏 item 跳过非滚动场景的二次零确认。
    _positionChanged = true;
    scheduleMeasurement();
  }

  void _handleScrollingChanged() {
    scheduleMeasurement();
  }

  void scheduleItemMeasurement(_ViewportLifecycleItemState item) {
    if (!_items.contains(item)) return;
    _dirtyItems.add(item);
    scheduleMeasurement();
  }

  void didMeasure(
    _ViewportLifecycleItemState item, {
    required bool geometricallyVisible,
  }) {
    if (geometricallyVisible) {
      _geometricallyVisibleItems.add(item);
    } else {
      _geometricallyVisibleItems.remove(item);
    }
  }

  void didPark(_ViewportLifecycleItemState item) {
    // KeepAlive bucket 中的 RenderBox 仍 attached，但其变换可能陈旧；park 后不再执行
    // 昂贵的 getTransformTo，只在滚动批次廉价探测它是否恢复。
    _parkedItems.add(item);
    _geometricallyVisibleItems.remove(item);
  }

  void didUnpark(_ViewportLifecycleItemState item) {
    _parkedItems.remove(item);
  }

  void scheduleMeasurement() {
    if (_items.isEmpty || _measurementScheduled) return;
    _measurementScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _measurementScheduled = false;
      if (_items.isEmpty) return;
      _syncPosition();
      // 可见节点持续跟踪；layout/paint 标记的脏节点用于发现新进入视口的 item。
      final candidates = <_ViewportLifecycleItemState>{
        ..._geometricallyVisibleItems,
        ..._dirtyItems,
      };
      if (_positionChanged || isScrolling) {
        // 普通候选执行完整几何测量；parked 节点只检查 ParentData，恢复后再重新测量。
        candidates.addAll(_items.where((item) => !_parkedItems.contains(item)));
        for (final item in List<_ViewportLifecycleItemState>.of(_parkedItems)) {
          if (!item._isKeptAlive) {
            _parkedItems.remove(item);
            candidates.add(item);
          }
        }
      }
      _dirtyItems.clear();
      final renderObject = scrollable.context.findRenderObject();
      final viewport = renderObject is RenderBox &&
              renderObject.attached &&
              renderObject.hasSize
          ? renderObject
          : null;
      final viewportRect =
          viewport == null ? Rect.zero : Offset.zero & viewport.size;
      for (final item in candidates) {
        if (!_items.contains(item)) continue;
        item._measureVisibility(this, viewport, viewportRect);
      }
      _positionChanged = false;
    });
  }
}

/// 在布局或实际绘制发生时，把 item 标记为下一批测量候选。
class _ViewportLayoutObserver extends SingleChildRenderObjectWidget {
  const _ViewportLayoutObserver({
    required this.onMeasurementNeeded,
    required super.child,
  });

  final VoidCallback onMeasurementNeeded;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _RenderViewportLayoutObserver(onMeasurementNeeded);
  }

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderViewportLayoutObserver renderObject,
  ) {
    renderObject.onMeasurementNeeded = onMeasurementNeeded;
  }
}

/// 不改变布局/绘制结果，只观察 RenderObject 生命周期中的几何失效信号。
class _RenderViewportLayoutObserver extends RenderProxyBox {
  _RenderViewportLayoutObserver(this.onMeasurementNeeded);

  VoidCallback onMeasurementNeeded;

  @override
  void performLayout() {
    super.performLayout();
    onMeasurementNeeded();
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    super.paint(context, offset);
    onMeasurementNeeded();
  }
}
