import 'package:flutter/widgets.dart';

import 'child_page_lifecycle_wrapper.dart';
import 'lifecycle_aware.dart';
import 'lifecycle_observer.dart';
import 'lifecycle_observer_provider.dart';
import 'parent_page_lifecycle_wrapper.dart';

/// Subscribe lifecycle event from [ChildPageLifecycleWrapper] or [LifecycleObserver].
mixin ParentPageSubscribeLifecycleMixin
    on State<ParentPageLifecycleWrapper>, LifecycleAware {
  ChildPageLifecycleWrapperState _pageLifecycleWrapperState;
  LifecycleObserver _lifecycleObserver;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _pageLifecycleWrapperState = ChildPageLifecycleWrapper.of(context);
    if (_pageLifecycleWrapperState != null) {
      // 如果是嵌套的PageView，则从上层Page订阅event
      _pageLifecycleWrapperState.subscribe(this);
    } else {
      // 如果不是嵌套的PageView，则从LifecycleObserver订阅event
      _lifecycleObserver = LifecycleObserverProvider.of(context);
      _lifecycleObserver.subscribe(this, ModalRoute.of(context));
    }
  }

  @override
  void dispose() {
    _pageLifecycleWrapperState?.unsubscribe(this);
    _lifecycleObserver?.unsubscribe(this);
    super.dispose();
  }
}
