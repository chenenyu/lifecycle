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
    _childPageLifecycleWrapperState = ChildPageLifecycleWrapper.of(context);
    if (_childPageLifecycleWrapperState != null) {
      // 如果是嵌套的PageView，则从上层ChildPage订阅event
      _childPageLifecycleWrapperState.subscribe(this);
    } else {
      // 如果不是嵌套的PageView，则从LifecycleObserver订阅event
      _lifecycleObserver = LifecycleObserver.internalGet(context);
      _lifecycleObserver.subscribe(this, ModalRoute.of(context));
    }
  }

  @override
  void dispose() {
    _childPageLifecycleWrapperState?.unsubscribe(this);
    _lifecycleObserver?.unsubscribe(this);
    super.dispose();
  }
}
