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
    handleLifecycleEvents([LifecycleEvent.push]);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final ModalRoute? route = ModalRoute.of(context);
    if (route == null) return;

    if (_lifecycleObserver == null) {
      _lifecycleObserver = LifecycleObserver.internalGet(context);
    }
    if (_childPageLifecycleWrapperState == null) {
      _childPageLifecycleWrapperState = ChildPageLifecycleWrapper.of(context);
    }

    if (_childPageLifecycleWrapperState != null) {
      _childPageLifecycleWrapperState?.subscribe(this);
    } else {
      _lifecycleObserver?.subscribe(this, route);
    }
  }

  @override
  void dispose() {
    handleLifecycleEvents([LifecycleEvent.pop]);
    _childPageLifecycleWrapperState?.unsubscribe(this);
    _lifecycleObserver?.unsubscribe(this);
    super.dispose();
  }
}
