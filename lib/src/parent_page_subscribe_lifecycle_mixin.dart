import 'package:flutter/widgets.dart';

import 'child_page_lifecycle_wrapper.dart';
import 'lifecycle_aware.dart';
import 'lifecycle_observer.dart';
import 'parent_page_lifecycle_wrapper.dart';

/// Subscribe lifecycle event from [LifecycleObserver] or [ChildPageLifecycleWrapper] (if nested).
mixin ParentPageSubscribeLifecycleMixin
    on State<ParentPageLifecycleWrapper>, LifecycleAware {
  LifecycleObserver _lifecycleObserver;
  ChildPageLifecycleWrapperState _childPageLifecycleWrapperState;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _lifecycleObserver = LifecycleObserver.internalGet(context);
    _childPageLifecycleWrapperState = ChildPageLifecycleWrapper.of(context);
    if (_childPageLifecycleWrapperState != null) {
      // If in nested PageView:
      // 1. Subscribe push events from observer
      _lifecycleObserver.subscribe(
          this, ModalRoute.of(context), Set.of([LifecycleEvent.push]));
      // 2. Subscribe other events from ancestor
      _childPageLifecycleWrapperState.subscribe(
          this, lifecycle_events_without_push_pop);
    } else {
      // Subscribe all events from observer
      _lifecycleObserver.subscribe(
          this, ModalRoute.of(context), lifecycle_events_all);
    }
  }

  @override
  void dispose() {
    if (_childPageLifecycleWrapperState != null) {
      onLifecycleEvent(LifecycleEvent.pop);
    }
    _lifecycleObserver.unsubscribe(this);
    _childPageLifecycleWrapperState?.unsubscribe(this);
    super.dispose();
  }
}
