import 'package:flutter/widgets.dart';

import 'child_page_lifecycle_wrapper.dart';
import 'lifecycle_aware.dart';
import 'lifecycle_observer.dart';

/// Subscribe lifecycle event from [LifecycleObserver] or
/// [ChildPageLifecycleWrapper] (if nested).
mixin LifecycleMixin<T extends StatefulWidget> on State<T>, LifecycleAware {
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
    final route = ModalRoute.of(context);
    if (route == null) return;
    if (_lifecycleObserver == null) {
      _lifecycleObserver = LifecycleObserver.internalGet(context);
    }
    if (_childPageLifecycleWrapperState == null) {
      _childPageLifecycleWrapperState =
          ChildPageLifecycleWrapper.maybeOf(context);
    }

    if (_childPageLifecycleWrapperState != null) {
      _childPageLifecycleWrapperState!.subscribe(this);
    } else {
      _lifecycleObserver!.subscribe(this, route);
    }
  }

  @override
  void dispose() {
    handleLifecycleEvents([LifecycleEvent.pop]);
    _lifecycleObserver!.unsubscribe(this);
    _childPageLifecycleWrapperState?.unsubscribe(this);
    super.dispose();
  }
}
