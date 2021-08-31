import 'package:flutter/material.dart';

import 'child_page_dispatch_lifecycle_mixin.dart';
import 'child_page_subscribe_lifecycle_mixin.dart';
import 'lifecycle_aware.dart';
import 'parent_page_lifecycle_wrapper.dart';

/// Lifecycle wrapper for children of [PageView] and [TabBarView].
/// See [ParentPageLifecycleWrapper].
class ChildPageLifecycleWrapper extends StatefulWidget {
  final int index;
  final OnLifecycleEvent? onLifecycleEvent;
  final bool wantKeepAlive;
  final Widget child;

  ChildPageLifecycleWrapper({
    Key? key,
    required this.index,
    this.onLifecycleEvent,
    this.wantKeepAlive = false,
    required this.child,
  })  : assert(index >= 0),
        super(key: key);

  @override
  ChildPageLifecycleWrapperState createState() {
    return ChildPageLifecycleWrapperState();
  }

  static ChildPageLifecycleWrapperState? of(BuildContext context) {
    return context.findAncestorStateOfType<ChildPageLifecycleWrapperState>();
  }
}

class ChildPageLifecycleWrapperState extends State<ChildPageLifecycleWrapper>
    with
        LifecycleAware,
        ChildPageSubscribeLifecycleMixin,
        ChildPageDispatchLifecycleMixin,
        AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => widget.wantKeepAlive;

  @override
  void initState() {
    super.initState();
    // log('ChildPageLifecycleWrapperState($hashCode)#initState');
  }

  @override
  void dispose() {
    // log('ChildPageLifecycleWrapperState($hashCode)#dispose');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }

  @override
  void onLifecycleEvent(LifecycleEvent event) {
    // log('ChildPageLifecycleWrapperState($hashCode)#${event.toString()}');
    widget.onLifecycleEvent?.call(event);
  }
}
