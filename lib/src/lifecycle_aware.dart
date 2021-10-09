import 'package:flutter/widgets.dart';

import 'lifecycle_observer.dart';

/// An interface for objects that are aware of their current [Route].
///
/// This is used with [LifecycleObserver] to make a widget aware of changes to the
/// [Navigator]'s session history.
abstract class LifecycleAware {
  LifecycleEvent? _currentLifecycleState;

  @mustCallSuper
  void handleLifecycleEvents(List<LifecycleEvent> events) {
    if (_currentLifecycleState == events.last) {
      return;
    }
    // Ensure that [LifecycleEvent.inactive] and [LifecycleEvent.invisible]
    // occurs when single [LifecycleEvent.pop] triggered.
    if (events.length == 1 && events.first == LifecycleEvent.pop) {
      if (_currentLifecycleState!.index < LifecycleEvent.inactive.index) {
        events
            .insertAll(0, [LifecycleEvent.inactive, LifecycleEvent.invisible]);
      } else if (_currentLifecycleState!.index <
          LifecycleEvent.invisible.index) {
        events.insert(0, LifecycleEvent.invisible);
      }
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

const List<LifecycleEvent> lifecycleEventsVisibleAndActive = [
  LifecycleEvent.visible,
  LifecycleEvent.active,
];

const List<LifecycleEvent> lifecycleEventsInactiveAndInvisible = [
  LifecycleEvent.inactive,
  LifecycleEvent.invisible,
];
