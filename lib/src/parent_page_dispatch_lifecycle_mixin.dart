import 'package:flutter/widgets.dart';

import 'child_page_lifecycle_wrapper.dart';
import 'lifecycle_aware.dart';
import 'parent_page_lifecycle_wrapper.dart';

/// Dispatch lifecycle event to child page.
mixin ParentPageDispatchLifecycleMixin on State<ParentPageLifecycleWrapper> {
  /// Current page.
  int curPage = 0;

  /// Map of page index and child.
  final Map<int, LifecycleAware> _lifecycleSubscribers = {};

  void subscribe(int index, LifecycleAware lifecycleAware) {
    assert(lifecycleAware is ChildPageLifecycleWrapperState);
    if (_lifecycleSubscribers[index] != lifecycleAware) {
      _lifecycleSubscribers[index] = lifecycleAware;
      // Dispatch [LifecycleEvent.active] to initial page.
      if (curPage == index) {
        if (ModalRoute.of(context)!.isCurrent) {
          dispatchEvents(lifecycle_events_visible_and_active);
        } else {
          dispatchEvents([LifecycleEvent.visible]);
        }
      }
    }
  }

  void unsubscribe(LifecycleAware lifecycleAware) {
    if (_lifecycleSubscribers.containsValue(lifecycleAware)) {
      _lifecycleSubscribers
          .removeWhere((key, value) => value == lifecycleAware);
    }
  }

  /// Dispatch [events] to subscribers.
  void dispatchEvents(List<LifecycleEvent> events) {
    _lifecycleSubscribers[curPage]?.handleLifecycleEvents(events);
  }
}
