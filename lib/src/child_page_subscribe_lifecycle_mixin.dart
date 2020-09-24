import 'package:flutter/widgets.dart';

import 'child_page_lifecycle_wrapper.dart';
import 'lifecycle_aware.dart';
import 'parent_page_lifecycle_wrapper.dart';

/// Subscribe lifecycle event from [ParentPageLifecycleWrapper].
/// This is used in child page of PageView.
mixin ChildPageSubscribeLifecycleMixin
    on State<ChildPageLifecycleWrapper>, LifecycleAware {
  ParentPageLifecycleWrapperState _basePageViewLifecycleWrapperState;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _basePageViewLifecycleWrapperState = ParentPageLifecycleWrapper.of(context);
    _basePageViewLifecycleWrapperState?.subscribe(widget.index, this);
  }

  @override
  void dispose() {
    _basePageViewLifecycleWrapperState?.unsubscribe(this);
    super.dispose();
  }
}
