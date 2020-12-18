import 'package:flutter/widgets.dart';

import 'child_page_lifecycle_wrapper.dart';
import 'lifecycle_aware.dart';

/// Lifecycle dispatcher for child page.
mixin ChildPageDispatchLifecycleMixin
    on State<ChildPageLifecycleWrapper>, LifecycleAware {
  final Set<LifecycleAware> _lifecycleSubscribers = <LifecycleAware>{};
  final Map<LifecycleAware, Set<LifecycleEvent>> _eventsFilters = {};

  void subscribe(LifecycleAware lifecycleAware, [Set<LifecycleEvent> events]) {
    _lifecycleSubscribers.add(lifecycleAware);
    _eventsFilters.putIfAbsent(lifecycleAware, () => events);
  }

  void unsubscribe(LifecycleAware lifecycleAware) {
    _lifecycleSubscribers.remove(lifecycleAware);
    _eventsFilters.remove(lifecycleAware);
  }

  /// Dispatch event to subscribers.
  void dispatchEvent(LifecycleEvent event) {
    _lifecycleSubscribers.forEach((lifecycleAware) {
      Set<LifecycleEvent> events = _eventsFilters[lifecycleAware];
      if (events.contains(event)) {
        lifecycleAware.onLifecycleEvent(event);
      }
    });
  }
}
