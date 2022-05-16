import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import 'lifecycle_aware.dart';
import 'lifecycle_observer.dart';
import 'widget_dispatch_lifecycle_mixin.dart';

/// Used for child widget of a [ScrollView].
/// See [ListView]/[GridView]/[CustomScrollView].
mixin ScrollViewItemSubscribeLifecycleMixin<T extends StatefulWidget>
    on State<T>, LifecycleAware {
  LifecycleObserver? _lifecycleObserver;
  WidgetDispatchLifecycleMixin? _widgetDispatchLifecycleMixin;

  late ScrollableState _scrollableState;
  ScrollPosition? _scrollPosition;
  bool _visibleInViewport = false;

  @override
  void initState() {
    super.initState();
    handleLifecycleEvents([LifecycleEvent.push]);
    SchedulerBinding.instance.endOfFrame.then((value) {
      // trigger manually
      _onScrollPositionChanged();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final ModalRoute? route = ModalRoute.of(context);
    if (route == null || !route.isActive) return;

    _widgetDispatchLifecycleMixin = null;
    context.visitAncestorElements((element) {
      if (element is StatefulElement &&
          element.state is WidgetDispatchLifecycleMixin) {
        _widgetDispatchLifecycleMixin =
            element.state as WidgetDispatchLifecycleMixin;
        return false;
      }
      return true;
    });
    if (_widgetDispatchLifecycleMixin != null) {
      _widgetDispatchLifecycleMixin!.subscribe(this);
    } else {
      _lifecycleObserver = LifecycleObserver.internalGet(context);
      _lifecycleObserver!.subscribe(this, route);
    }

    _updateScrollPosition();
  }

  @override
  void dispose() {
    handleLifecycleEvents([LifecycleEvent.pop]);
    _lifecycleObserver?.unsubscribe(this);
    _widgetDispatchLifecycleMixin?.unsubscribe(this);
    _scrollPosition?.removeListener(_onScrollPositionChanged);
    super.dispose();
  }

  @override
  void handleLifecycleEvents(List<LifecycleEvent> events) {
    bool pushOrPop = events.length == 1 &&
        (events.first == LifecycleEvent.push ||
            events.first == LifecycleEvent.pop);
    if (!pushOrPop && _visibleInViewport != true) {
      return;
    }
    super.handleLifecycleEvents(events);
  }

  void _updateScrollPosition() {
    _scrollableState = Scrollable.of(context)!;
    ScrollPosition newValue = _scrollableState.position;
    if (_scrollPosition == newValue) {
      return;
    }
    final ScrollPosition? oldValue = _scrollPosition;
    _scrollPosition = newValue;
    oldValue?.removeListener(_onScrollPositionChanged);
    newValue.addListener(_onScrollPositionChanged);
  }

  int? _nextFrameCallbackId;

  void _onScrollPositionChanged() {
    if (!mounted) return;
    if (_scrollPosition!.recommendDeferredLoading(context)) {
      if (_nextFrameCallbackId != null) {
        SchedulerBinding.instance
            .cancelFrameCallbackWithId(_nextFrameCallbackId!);
      }
      _nextFrameCallbackId =
          SchedulerBinding.instance.scheduleFrameCallback((_) {
        _onScrollPositionChanged();
      });
      return;
    }
    Axis axis = _scrollableState.widget.axis;
    RenderBox renderBox = context.findRenderObject()! as RenderBox;
    double itemOffset = _determineItemOffset(axis, renderBox);
    Size size = renderBox.size;
    if (itemOffset.isNaN) {
      return;
    }

    if (itemOffset < -(axis == Axis.vertical ? size.height : size.width) ||
        itemOffset > _scrollPosition!.viewportDimension) {
      // Completely invisible in viewport
      handleLifecycleEvents(lifecycleEventsInactiveAndInvisible);
      _visibleInViewport = false;
    } else {
      _visibleInViewport = true;
      handleLifecycleEvents(lifecycleEventsVisibleAndActive);
    }
  }

  double _determineItemOffset(Axis axis, RenderBox renderBox) {
    final scrollBox = _scrollableState.context.findRenderObject();
    if (scrollBox?.attached ?? false) {
      try {
        Offset offset =
            renderBox.localToGlobal(Offset.zero, ancestor: scrollBox);
        return axis == Axis.vertical ? offset.dy : offset.dx;
      } catch (e) {
        // ignore and fall-through and return 0.0
      }
    }
    return 0.0;
  }
}
