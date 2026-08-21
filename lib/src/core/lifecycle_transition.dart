/*
 * 封装一次完整状态变化：前后 Snapshot、Cause 和有序 Event 列表。
 *
 * 构造时复制并冻结 events，防止调用方随后修改原列表破坏已派发记录；消费者可同时
 * 使用快照差异处理连续值变化，并用 contains() 查询一次性语义事件。
 */
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
