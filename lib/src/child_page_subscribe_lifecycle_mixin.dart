import 'package:flutter/widgets.dart';

import 'child_page_lifecycle_wrapper.dart';
import 'lifecycle_aware.dart';
import 'parent_page_lifecycle_wrapper.dart';

/// Subscribe lifecycle event from [ParentPageLifecycleWrapper].
/// This is used in child page of PageView.
mixin ChildPageSubscribeLifecycleMixin
    on State<ChildPageLifecycleWrapper>, LifecycleAware {
  ParentPageLifecycleWrapperState _parentPageLifecycleWrapperState;

  @override
  void initState() {
    super.initState();
    onLifecycleEvent(LifecycleEvent.push);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _parentPageLifecycleWrapperState = ParentPageLifecycleWrapper.of(context);
    _parentPageLifecycleWrapperState?.subscribe(widget.index, this);
  }

  @override
  void dispose() {
    onLifecycleEvent(LifecycleEvent.pop);
    _parentPageLifecycleWrapperState?.unsubscribe(this);
    super.dispose();
  }
}
