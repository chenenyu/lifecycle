import 'package:flutter/widgets.dart';

import 'child_page_lifecycle_wrapper.dart';
import 'lifecycle_aware.dart';
import 'lifecycle_observer.dart';
import 'parent_page_lifecycle_wrapper.dart';

// typedef ParentPageSubscribeLifecycleMixin = LifecycleMixin;

/// Subscribe lifecycle event from [LifecycleObserver] or [ChildPageLifecycleWrapper] (if nested).
@Deprecated('Use LifecycleMixin instead.')
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

    _lifecycleObserver ??= LifecycleObserver.internalGet(context);
    _childPageLifecycleWrapperState ??=
        ChildPageLifecycleWrapper.maybeOf(context);

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
