import 'package:flutter/widgets.dart';

import 'lifecycle_aware.dart';

/// Lifecycle dispatcher for child page.
mixin ChildPageDispatchLifecycleMixin<T extends StatefulWidget>
    on State<T>, LifecycleAware {
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
    _dispatchEvents(events);
  }

  /// Dispatch [events] to subscribers.
  void _dispatchEvents(List<LifecycleEvent> events) {
    for (LifecycleAware lifecycleAware in _lifecycleSubscribers) {
      lifecycleAware.handleLifecycleEvents(events);
    }
  }
}
