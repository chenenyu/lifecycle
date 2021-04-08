import 'package:flutter/widgets.dart';

import 'child_page_lifecycle_wrapper.dart';
import 'lifecycle_aware.dart';
import 'lifecycle_observer.dart';
import 'parent_page_lifecycle_wrapper.dart';

/// Subscribe lifecycle event from [ParentPageLifecycleWrapper].
/// This is used in child page of PageView.
mixin ChildPageSubscribeLifecycleMixin
    on State<ChildPageLifecycleWrapper>, LifecycleAware {
  late LifecycleObserver? _lifecycleObserver;
  late ParentPageLifecycleWrapperState? _parentPageLifecycleWrapperState;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Subscribe push/pop events from observer
    _lifecycleObserver = LifecycleObserver.internalGet(context);

    final route = ModalRoute.of(context);

    if (route == null || widget.index == null) return;

    _lifecycleObserver?.subscribe(
        this, route, lifecycle_events_with_push_pop);
    // Subscribe other events from parent
    _parentPageLifecycleWrapperState = ParentPageLifecycleWrapper.of(context);
    _parentPageLifecycleWrapperState?.subscribe(
        widget.index!, this, lifecycle_events_without_push);
  }

  @override
  void dispose() {
    // Supply a pop event is necessary when page changed.
    onLifecycleEvent(LifecycleEvent.pop);
    _lifecycleObserver?.unsubscribe(this);
    _parentPageLifecycleWrapperState?.unsubscribe(this);
    super.dispose();
  }
}
