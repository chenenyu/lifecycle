import 'package:flutter/widgets.dart';

import 'lifecycle_aware.dart';
import 'parent_page_lifecycle_wrapper.dart';

/// Dispatch lifecycle event to child page.
mixin DispatchLifecycleToChildPageMixin
    on State<ParentPageLifecycleWrapper>, LifecycleAware {
  /// Current page.
  int curPage;

  /// Map of page index and child.
  Map<int, LifecycleAware> _subscribers = {};

  void subscribe(int index, LifecycleAware lifecycleAware) {
    _subscribers[index] = lifecycleAware;
  }

  void unsubscribe(LifecycleAware lifecycleAware) {
    if (_subscribers.containsValue(lifecycleAware)) {
      _subscribers.removeWhere((key, value) => value == lifecycleAware);
    }
  }

  /// Dispatch event to stream subscription
  void dispatchEvent(LifecycleEvent event) {
    _subscribers[curPage].onLifecycleEvent(event);
  }
}
