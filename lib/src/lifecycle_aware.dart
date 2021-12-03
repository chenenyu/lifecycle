import 'package:flutter/widgets.dart';

/// An interface for objects that are aware of their current [Route].
mixin LifecycleAware {
  LifecycleEvent? _currentLifecycleState;

  LifecycleEvent? get currentLifecycleState => _currentLifecycleState;

  @mustCallSuper
  void handleLifecycleEvents(List<LifecycleEvent> events) {
    if (_currentLifecycleState == events.last) {
      return;
    }

    List<LifecycleEvent> fixedEvents = events;

    // Ensure that [LifecycleEvent.inactive] and [LifecycleEvent.invisible]
    // occurs when single [LifecycleEvent.pop] triggered.
    // When an observed widget is removed from widget tree, this case happens.
    if (events.length == 1 &&
        events.first == LifecycleEvent.pop &&
        _currentLifecycleState != LifecycleEvent.push) {
      if (_currentLifecycleState!.index < LifecycleEvent.inactive.index) {
        fixedEvents = [
          LifecycleEvent.inactive,
          LifecycleEvent.invisible,
          LifecycleEvent.pop,
        ];
      } else if (_currentLifecycleState! == LifecycleEvent.inactive) {
        fixedEvents = [LifecycleEvent.invisible, LifecycleEvent.pop];
      }
    }

    for (LifecycleEvent event in fixedEvents) {
      if (event != _currentLifecycleState) {
        _currentLifecycleState = event;
        onLifecycleEvent(event);
      }
    }
  }

  void onLifecycleEvent(LifecycleEvent event);

  /// Used for an indexed child, such as an item of [ListView]/[GridView].
  int? get itemIndex => null;
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
