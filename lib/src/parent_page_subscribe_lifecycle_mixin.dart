import 'package:flutter/widgets.dart';

import 'child_page_lifecycle_wrapper.dart';
import 'lifecycle_aware.dart';
import 'lifecycle_observer.dart';
import 'parent_page_lifecycle_wrapper.dart';

/// Subscribe lifecycle event from [LifecycleObserver] or [ChildPageLifecycleWrapper] (if nested).
mixin ParentPageSubscribeLifecycleMixin
    on State<ParentPageLifecycleWrapper>, LifecycleAware {
  LifecycleObserver? _lifecycleObserver;
  ChildPageLifecycleWrapperState? _childPageLifecycleWrapperState;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _lifecycleObserver = LifecycleObserver.internalGet(context);
    _childPageLifecycleWrapperState = ChildPageLifecycleWrapper.of(context);

    final page = ModalRoute.of(context);
    if (page == null) return;

    if (_childPageLifecycleWrapperState != null) {
      // If in nested PageView:
      // 1. Subscribe push/pop events from observer

      _lifecycleObserver?.subscribe(
          this, page, lifecycle_events_with_push_pop);
      // 2. Subscribe other events from ancestor
      _childPageLifecycleWrapperState?.subscribe(
          this, lifecycle_events_without_push);
    } else {
      // Subscribe all events from observer
      _lifecycleObserver?.subscribe(
          this, page, lifecycle_events_all);
    }
  }

  @override
  void dispose() {
    if (_childPageLifecycleWrapperState != null) {
      _childPageLifecycleWrapperState?.unsubscribe(this);
      // Supply a pop event is necessary when page changed.
      onLifecycleEvent(LifecycleEvent.pop);
    }
    _lifecycleObserver?.unsubscribe(this);
    super.dispose();
  }
}
