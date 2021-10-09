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

    List<LifecycleEvent> fixedEvents = events;

    // Ensure that [LifecycleEvent.inactive] and [LifecycleEvent.invisible]
    // occurs when single [LifecycleEvent.pop] triggered.
    // When an observed widget is removed from widget tree, this case happens.
    if (events.length == 1 && events.first == LifecycleEvent.pop) {
      if (_currentLifecycleState!.index < LifecycleEvent.inactive.index) {
        fixedEvents = [
          LifecycleEvent.inactive,
          LifecycleEvent.invisible,
          LifecycleEvent.pop,
        ];
      } else if (_currentLifecycleState!.index <
          LifecycleEvent.invisible.index) {
        fixedEvents = [LifecycleEvent.invisible, LifecycleEvent.pop];
      }
    }

    for (LifecycleEvent event in fixedEvents) {
      if (event != _currentLifecycleState) {
        onLifecycleEvent(event);
      }
    }
    _currentLifecycleState = fixedEvents.last;
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
