import 'package:flutter/material.dart';

import 'lifecycle_aware.dart';
import 'lifecycle_mixin.dart';
import 'page_view_dispatch_lifecycle_mixin.dart';

/// Lifecycle wrapper for [PageView] / [TabBarView].
class PageViewLifecycleWrapper extends StatefulWidget {
  final OnLifecycleEvent? onLifecycleEvent;
  final Widget child;

  const PageViewLifecycleWrapper({
    Key? key,
    this.onLifecycleEvent,
    required this.child,
  }) : super(key: key);

  @override
  PageViewLifecycleWrapperState createState() {
    return PageViewLifecycleWrapperState();
  }
}

class PageViewLifecycleWrapperState extends State<PageViewLifecycleWrapper>
    with LifecycleAware, LifecycleMixin, PageViewDispatchLifecycleMixin {
  @override
  Widget build(BuildContext context) {
    return widget.child;
  }

  @override
  void onLifecycleEvent(LifecycleEvent event) {
    // print('ParentPageLifecycleWrapperState($hashCode)#${event.toString()}');
    widget.onLifecycleEvent?.call(event);
  }
}
