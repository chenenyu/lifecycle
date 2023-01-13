import 'package:flutter/widgets.dart';

/// A mixin for widgets that are aware of their current lifecycle.
mixin LifecycleAware {
  LifecycleEvent? _currentLifecycleState;

  /// Current lifecycle.
  LifecycleEvent? get currentLifecycleState => _currentLifecycleState;

  @mustCallSuper
  void handleLifecycleEvents(List<LifecycleEvent> events) {
    if (_currentLifecycleState == events.last) {
      return;
    }

    List<LifecycleEvent> fixedEvents = events;

    // Ensures that [LifecycleEvent.inactive] and [LifecycleEvent.invisible]
    // occurs when single [LifecycleEvent.pop] triggered.
    // When an observed widget is removed from widget tree, this case happens.
    //
    // 对 events 进行修正，如果触发了[LifecycleEvent.pop]，确保[LifecycleEvent.inactive]
    // 和[LifecycleEvent.invisible]一定被触发。
    // 当widget被移除时，可能会发生这种情况。
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

    // 分发 events
    for (LifecycleEvent event in fixedEvents) {
      if (event != _currentLifecycleState) {
        _currentLifecycleState = event;
        onLifecycleEvent(event);
      }
    }
  }

  /// [LifecycleEvent] callback.
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
