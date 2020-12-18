import 'package:flutter/widgets.dart';

import 'child_page_lifecycle_wrapper.dart';
import 'lifecycle_aware.dart';
import 'lifecycle_observer.dart';
import 'parent_page_lifecycle_wrapper.dart';

/// Subscribe lifecycle event from [ParentPageLifecycleWrapper].
/// This is used in child page of PageView.
mixin ChildPageSubscribeLifecycleMixin
    on State<ChildPageLifecycleWrapper>, LifecycleAware {
  LifecycleObserver _lifecycleObserver;
  ParentPageLifecycleWrapperState _parentPageLifecycleWrapperState;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Subscribe push events from observer
    _lifecycleObserver = LifecycleObserver.internalGet(context);
    _lifecycleObserver.subscribe(
        this, ModalRoute.of(context), Set.of([LifecycleEvent.push]));
    // Subscribe other events from parent
    _parentPageLifecycleWrapperState = ParentPageLifecycleWrapper.of(context);
    _parentPageLifecycleWrapperState?.subscribe(
        widget.index, this, lifecycle_events_without_push_pop);
  }

  @override
  void dispose() {
    onLifecycleEvent(LifecycleEvent.pop);
    _lifecycleObserver.unsubscribe(this);
    _parentPageLifecycleWrapperState?.unsubscribe(this);
    super.dispose();
  }
}
