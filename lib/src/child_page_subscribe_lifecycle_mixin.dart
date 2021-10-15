import 'package:flutter/widgets.dart';

import 'child_page_lifecycle_wrapper.dart';
import 'lifecycle_aware.dart';
import 'page_view_lifecycle_wrapper.dart';

/// Subscribe lifecycle event from [PageViewLifecycleWrapper].
/// This is used in child page of PageView.
mixin ChildPageSubscribeLifecycleMixin
    on State<ChildPageLifecycleWrapper>, LifecycleAware {
  PageViewLifecycleWrapperState? _pageViewLifecycleWrapperState;

  @override
  void initState() {
    super.initState();
    handleLifecycleEvents([LifecycleEvent.push]);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final ModalRoute? route = ModalRoute.of(context);
    if (route == null || !route.isActive) return;
    _pageViewLifecycleWrapperState = PageViewLifecycleWrapper.maybeOf(context);
    _pageViewLifecycleWrapperState?.subscribe(widget.index, this);
  }

  @override
  void dispose() {
    handleLifecycleEvents([LifecycleEvent.pop]);
    _pageViewLifecycleWrapperState?.unsubscribe(this);
    super.dispose();
  }
}
