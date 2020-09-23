import 'package:flutter/widgets.dart';

import 'child_page_lifecycle_wrapper.dart';
import 'lifecycle_aware.dart';

/// Lifecycle dispatcher for child page.
mixin DispatchLifecycleToParentPageMixin
    on State<ChildPageLifecycleWrapper>, LifecycleAware {
  Set<LifecycleAware> _subscribers = <LifecycleAware>{};

  void subscribe(LifecycleAware lifecycleAware) {
    _subscribers.add(lifecycleAware);
  }

  void unsubscribe(LifecycleAware lifecycleAware) {
    _subscribers.remove(lifecycleAware);
  }

  /// Dispatch event to subscribers.
  void dispatchEvent(LifecycleEvent event) {
    _subscribers.forEach((s) {
      s.onLifecycleEvent(event);
    });
  }
}
