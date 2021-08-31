import 'package:flutter/widgets.dart';

import 'lifecycle_observer.dart';

/// An interface for objects that are aware of their current [Route].
///
/// This is used with [LifecycleObserver] to make a widget aware of changes to the
/// [Navigator]'s session history.
abstract class LifecycleAware {
  LifecycleEvent? _currentLifecycleState;

  void handleLifecycleEvents(List<LifecycleEvent> events) {
    if (_currentLifecycleState == events.last) {
      return;
    }
    for (LifecycleEvent event in events) {
      if (event != _currentLifecycleState) {
        onLifecycleEvent(event);
      }
    }
    _currentLifecycleState = events.last;
  }

  void onLifecycleEvent(LifecycleEvent event);
}

typedef OnLifecycleEvent = void Function(LifecycleEvent event);

enum LifecycleEvent {
  push,
  visible,
  active,
  inactive,
  invisible,
  pop,
}

const List<LifecycleEvent> lifecycle_events_visible_and_active = [
  LifecycleEvent.visible,
  LifecycleEvent.active,
];

const List<LifecycleEvent> lifecycle_events_inactive_and_invisible = [
  LifecycleEvent.inactive,
  LifecycleEvent.invisible,
];
