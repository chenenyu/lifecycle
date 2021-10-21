import 'package:flutter/widgets.dart';

import 'lifecycle_aware.dart';
import 'scroll_view_item_subscribe_lifecycle_mixin.dart';
import 'widget_dispatch_lifecycle_mixin.dart';

/// Wrapper widget for item of scrollable widget.
class ScrollViewItemLifecycleWrapper extends StatefulWidget {
  const ScrollViewItemLifecycleWrapper({
    Key? key,
    this.onLifecycleEvent,
    this.wantKeepAlive = false,
    required this.child,
  }) : super(key: key);

  final OnLifecycleEvent? onLifecycleEvent;
  final bool wantKeepAlive;
  final Widget child;

  @override
  _ScrollViewItemLifecycleWrapperState createState() {
    return _ScrollViewItemLifecycleWrapperState();
  }
}

class _ScrollViewItemLifecycleWrapperState
    extends State<ScrollViewItemLifecycleWrapper>
    with
        LifecycleAware,
        ScrollViewItemSubscribeLifecycleMixin,
        WidgetDispatchLifecycleMixin,
        AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => widget.wantKeepAlive;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }

  @override
  void onLifecycleEvent(LifecycleEvent event) {
    widget.onLifecycleEvent?.call(event);
  }
}
