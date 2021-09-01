import 'package:flutter/widgets.dart';

import 'child_page_lifecycle_wrapper.dart';
import 'lifecycle_aware.dart';

/// Lifecycle dispatcher for child page.
mixin ChildPageDispatchLifecycleMixin
    on State<ChildPageLifecycleWrapper>, LifecycleAware {
  final Set<LifecycleAware> _lifecycleSubscribers = {};

  void subscribe(LifecycleAware lifecycleAware) {
    _lifecycleSubscribers.add(lifecycleAware);
  }

  void unsubscribe(LifecycleAware lifecycleAware) {
    _lifecycleSubscribers.remove(lifecycleAware);
  }

  @override
  void handleLifecycleEvents(List<LifecycleEvent> events) {
    super.handleLifecycleEvents(events);
    dispatchEvents(events);
  }

  /// Dispatch [events] to subscribers.
  void dispatchEvents(List<LifecycleEvent> events) {
    _lifecycleSubscribers.forEach((lifecycleAware) {
      lifecycleAware.handleLifecycleEvents(events);
    });
  }
}
