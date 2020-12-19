import 'package:flutter/widgets.dart';

import 'lifecycle_aware.dart';
import 'parent_page_lifecycle_wrapper.dart';

/// Dispatch lifecycle event to child page.
mixin ParentPageDispatchLifecycleMixin
    on State<ParentPageLifecycleWrapper>, LifecycleAware {
  /// Current page.
  int curPage;

  /// Map of page index and child.
  final Map<int, LifecycleAware> _lifecycleSubscribers = {};
  final Map<LifecycleAware, Set<LifecycleEvent>> _eventsFilters = {};

  void subscribe(int index, LifecycleAware lifecycleAware,
      [Set<LifecycleEvent> events]) {
    _lifecycleSubscribers[index] = lifecycleAware;
    _eventsFilters.putIfAbsent(lifecycleAware, () => events);
  }

  void unsubscribe(LifecycleAware lifecycleAware) {
    if (_lifecycleSubscribers.containsValue(lifecycleAware)) {
      _lifecycleSubscribers
          .removeWhere((key, value) => value == lifecycleAware);
    }
    _eventsFilters.remove(lifecycleAware);
  }

  /// Dispatch event to stream subscription
  void dispatchEvent(LifecycleEvent event) {
    if (event == LifecycleEvent.pop) {
      // Dispatch pop event to all subscribers.
      _lifecycleSubscribers.forEach((page, lifecycleAware) {
        _doDispatch(lifecycleAware, event);
      });
    } else {
      // Dispatch event to current subscriber.
      LifecycleAware lifecycleAware = _lifecycleSubscribers[curPage];
      _doDispatch(lifecycleAware, event);
    }
  }

  void _doDispatch(LifecycleAware lifecycleAware, LifecycleEvent event) {
    if (lifecycleAware != null) {
      Set<LifecycleEvent> events = _eventsFilters[lifecycleAware];
      if (events.contains(event)) {
        lifecycleAware.onLifecycleEvent(event);
      }
    }
  }
}
