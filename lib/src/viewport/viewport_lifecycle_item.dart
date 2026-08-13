import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import '../core/lifecycle_controller.dart';
import '../core/lifecycle_event.dart';
import '../core/lifecycle_scope.dart';
import '../core/lifecycle_transition.dart';

/// Tracks the visible area of a child inside its nearest Scrollable.
class ViewportLifecycleItem extends StatefulWidget {
  /// Creates a viewport lifecycle item.
  const ViewportLifecycleItem({
    super.key,
    this.visibleThreshold = 0,
    this.activeThreshold,
    this.onTransition,
    this.onEvent,
    required this.child,
  })  : assert(visibleThreshold >= 0 && visibleThreshold <= 1),
        assert(
          activeThreshold == null ||
              (activeThreshold >= visibleThreshold && activeThreshold <= 1),
        );

  /// Minimum visible fraction required for the item to be visible.
  final double visibleThreshold;

  /// Minimum visible fraction required for the item to be active.
  final double? activeThreshold;

  /// Called once for every changed viewport snapshot.
  final LifecycleTransitionCallback? onTransition;

  /// Called for each semantic event in a viewport transition.
  final LifecycleEventCallback? onEvent;

  /// Item whose rectangular area is measured against the viewport.
  final Widget child;

  @override
  State<ViewportLifecycleItem> createState() => _ViewportLifecycleItemState();
}

class _ViewportLifecycleItemState extends State<ViewportLifecycleItem> {
  late final LifecycleController _controller;
  ScrollPosition? _position;
  ScrollableState? _scrollable;
  bool _measurementScheduled = false;
  bool _zeroFractionPending = false;
  double _appliedFraction = 0;

  @override
  void initState() {
    super.initState();
    _controller = LifecycleController(
      visible: false,
      active: false,
      visibleFraction: 0,
      debugLabel: 'ViewportLifecycleItem',
    )..addTransitionListener(_handleTransition);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final parent = resolveLifecycleParent(context);
    if (_controller.isAttached) {
      _controller.reparent(parent);
    } else {
      _controller.attach(parent: parent, cause: LifecycleCause.viewport);
    }

    final scrollable = Scrollable.maybeOf(context);
    if (scrollable == null) {
      throw FlutterError(
        'ViewportLifecycleItem must be a descendant of a Scrollable widget.',
      );
    }
    _scrollable = scrollable;
    final position = scrollable.position;
    if (_position != position) {
      _position?.removeListener(_scheduleMeasurement);
      _position = position..addListener(_scheduleMeasurement);
    }
    _scheduleMeasurement();
  }

  @override
  void didUpdateWidget(ViewportLifecycleItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    _scheduleMeasurement();
  }

  void _scheduleMeasurement() {
    if (_measurementScheduled) return;
    _measurementScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _measurementScheduled = false;
      if (mounted) _measureVisibility();
    });
  }

  void _measureVisibility() {
    final scrollable = _scrollable;
    if (!mounted || scrollable == null) return;

    final itemRenderObject = context.findRenderObject();
    final viewportRenderObject = scrollable.context.findRenderObject();
    var fraction = 0.0;

    if (itemRenderObject is RenderBox &&
        viewportRenderObject is RenderBox &&
        itemRenderObject.attached &&
        viewportRenderObject.attached &&
        itemRenderObject.hasSize &&
        viewportRenderObject.hasSize) {
      try {
        final transform = itemRenderObject.getTransformTo(viewportRenderObject);
        final itemRect = MatrixUtils.transformRect(
          transform,
          Offset.zero & itemRenderObject.size,
        );
        final viewportRect = Offset.zero & viewportRenderObject.size;
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

    final activeThreshold = widget.activeThreshold ?? widget.visibleThreshold;
    final visible = fraction > 0 && fraction >= widget.visibleThreshold;
    final active = fraction > 0 && fraction >= activeThreshold;

    // A kept-alive scrollable can briefly report zero geometry while an outer
    // PageView reattaches it. Confirm a complete disappearance on the next
    // frame so consumers do not receive a false inactive/active pair.
    if (fraction == 0 && _appliedFraction > 0 && !_zeroFractionPending) {
      _zeroFractionPending = true;
      _scheduleMeasurement();
      WidgetsBinding.instance.ensureVisualUpdate();
      return;
    }
    _zeroFractionPending = false;
    _appliedFraction = fraction;
    _controller.updateLocal(
      visible: visible,
      active: active,
      visibleFraction: fraction,
      cause: LifecycleCause.viewport,
    );
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
    return _ViewportLayoutObserver(
      onLayout: _scheduleMeasurement,
      child: LifecycleScope(
        controller: _controller,
        kind: LifecycleScopeKind.viewport,
        route: ModalRoute.of(context),
        child: widget.child,
      ),
    );
  }

  @override
  void dispose() {
    _position?.removeListener(_scheduleMeasurement);
    _controller.dispose();
    super.dispose();
  }
}

class _ViewportLayoutObserver extends SingleChildRenderObjectWidget {
  const _ViewportLayoutObserver({required this.onLayout, required super.child});

  final VoidCallback onLayout;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _RenderViewportLayoutObserver(onLayout);
  }

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderViewportLayoutObserver renderObject,
  ) {
    renderObject.onLayout = onLayout;
  }
}

class _RenderViewportLayoutObserver extends RenderProxyBox {
  _RenderViewportLayoutObserver(this.onLayout);

  VoidCallback onLayout;

  @override
  void performLayout() {
    super.performLayout();
    onLayout();
  }
}
