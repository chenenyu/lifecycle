import 'package:flutter/material.dart';

import 'child_page_subscribe_lifecycle_mixin.dart';
import 'lifecycle_aware.dart';
import 'widget_dispatch_lifecycle_mixin.dart';

/// Lifecycle wrapper for children of [PageView] and [TabBarView].
///
/// If you do not want to wrap child widget with this widget, try to mixin
/// [LifecycleAware], [ChildPageSubscribeLifecycleMixin] and [WidgetDispatchLifecycleMixin]
/// on your item's [State].
class ChildPageLifecycleWrapper extends StatefulWidget {
  final int index;
  final OnLifecycleEvent? onLifecycleEvent;
  final bool wantKeepAlive;
  final Widget child;

  const ChildPageLifecycleWrapper({
    Key? key,
    required this.index,
    this.onLifecycleEvent,
    this.wantKeepAlive = false,
    required this.child,
  })  : assert(index >= 0),
        super(key: key);

  @override
  _ChildPageLifecycleWrapperState createState() {
    return _ChildPageLifecycleWrapperState();
  }
}

class _ChildPageLifecycleWrapperState extends State<ChildPageLifecycleWrapper>
    with
        LifecycleAware,
        ChildPageSubscribeLifecycleMixin,
        WidgetDispatchLifecycleMixin,
        AutomaticKeepAliveClientMixin {
  @override
  int get itemIndex => widget.index;

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
