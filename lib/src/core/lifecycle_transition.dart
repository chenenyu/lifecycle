import 'package:flutter/foundation.dart';

import 'lifecycle_event.dart';
import 'lifecycle_snapshot.dart';

/// A single atomic change between two lifecycle snapshots.
@immutable
class LifecycleTransition {
  /// Creates a transition and copies [events] into an immutable list.
  LifecycleTransition({
    required this.previous,
    required this.current,
    required this.cause,
    required List<LifecycleEvent> events,
  }) : events = List.unmodifiable(events);

  /// State before the transition.
  final LifecycleSnapshot previous;

  /// State after the transition.
  final LifecycleSnapshot current;

  /// The subsystem that initiated this transition.
  final LifecycleCause cause;

  /// Ordered semantic events derived from the state change.
  final List<LifecycleEvent> events;

  /// Whether [event] was emitted by this transition.
  bool contains(LifecycleEvent event) => events.contains(event);

  @override
  String toString() {
    return 'LifecycleTransition('
        '${previous.phase} -> ${current.phase}, '
        'cause: $cause, events: $events)';
  }
}

/// Receives one atomic lifecycle transition.
typedef LifecycleTransitionCallback = void Function(
    LifecycleTransition transition);

/// Receives one event together with the transition that produced it.
typedef LifecycleEventCallback = void Function(
    LifecycleEvent event, LifecycleTransition transition);
