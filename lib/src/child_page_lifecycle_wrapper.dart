import 'package:flutter/material.dart';

import 'child_page_dispatch_lifecycle_mixin.dart';
import 'child_page_subscribe_lifecycle_mixin.dart';
import 'lifecycle_aware.dart';
import 'parent_page_lifecycle_wrapper.dart';

/// Lifecycle wrapper for children of [PageView] and [TabBarView].
/// See [ParentPageLifecycleWrapper].
class ChildPageLifecycleWrapper extends StatefulWidget {
  final int index;
  final OnLifecycleEvent onLifecycleEvent;
  final bool wantKeepAlive;
  final Widget child;

  ChildPageLifecycleWrapper({
    Key key,
    @required this.index,
    this.onLifecycleEvent,
    this.wantKeepAlive = false,
    @required this.child,
  })  : assert(index != null && index >= 0),
        assert(child != null),
        super(key: key);

  @override
  ChildPageLifecycleWrapperState createState() {
    return ChildPageLifecycleWrapperState();
  }

  static ChildPageLifecycleWrapperState of(BuildContext context) {
    return context.findAncestorStateOfType<ChildPageLifecycleWrapperState>();
  }
}

/// 不实现[LifecycleMixin],通过parent转发
class ChildPageLifecycleWrapperState extends State<ChildPageLifecycleWrapper>
    with
        LifecycleAware,
        ChildPageDispatchLifecycleMixin,
        ChildPageSubscribeLifecycleMixin,
        AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => widget.wantKeepAlive ?? false;

  @override
  void initState() {
    super.initState();
    // print('ChildPageLifecycleWrapperState#initState');
    onLifecycleEvent(LifecycleEvent.push);
  }

  @override
  void dispose() {
    // print('ChildPageLifecycleWrapperState#dispose');
    onLifecycleEvent(LifecycleEvent.pop);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }

  @override
  void onLifecycleEvent(LifecycleEvent event) {
    // callback
    if (widget.onLifecycleEvent != null) {
      widget.onLifecycleEvent(event);
    }
    // dispatch event to subscribers
    dispatchEvent(event);
  }
}
