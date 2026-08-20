import 'package:flutter/widgets.dart';

import 'lifecycle_event.dart';

/// An immutable, normalized view of a lifecycle node's effective state.
@immutable
class LifecycleSnapshot {
  /// Creates a lifecycle snapshot.
  const LifecycleSnapshot({
    required this.phase,
    required this.visibleFraction,
    this.appState,
  })  : assert(visibleFraction >= 0 && visibleFraction <= 1),
        assert(
          phase == LifecyclePhase.visible || phase == LifecyclePhase.active
              ? visibleFraction > 0
              : visibleFraction == 0,
          'Only visible and active snapshots can have a visible fraction.',
        ),
        assert(
          phase != LifecyclePhase.detached || appState == null,
          'A detached snapshot cannot inherit an application state.',
        );

  /// Creates the initial state of a controller that is not attached.
  const LifecycleSnapshot.detached()
      : this(
          phase: LifecyclePhase.detached,
          visibleFraction: 0,
        );

  /// The node's stable lifecycle phase.
  final LifecyclePhase phase;

  /// The normalized effective visible fraction in the range 0–1.
  ///
  /// This is zero for detached, hidden, and disposed snapshots.
  final double visibleFraction;

  /// The latest application lifecycle state inherited by this node.
  final AppLifecycleState? appState;

  /// Whether the node is currently attached to the lifecycle tree.
  bool get attached => switch (phase) {
        LifecyclePhase.hidden ||
        LifecyclePhase.visible ||
        LifecyclePhase.active =>
          true,
        LifecyclePhase.detached || LifecyclePhase.disposed => false,
      };

  /// Whether this node and every ancestor are visible.
  bool get visible =>
      phase == LifecyclePhase.visible || phase == LifecyclePhase.active;

  /// Whether this node and every ancestor are active.
  bool get active => phase == LifecyclePhase.active;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is LifecycleSnapshot &&
            phase == other.phase &&
            visibleFraction == other.visibleFraction &&
            appState == other.appState;
  }

  @override
  int get hashCode => Object.hash(phase, visibleFraction, appState);

  @override
  String toString() {
    return 'LifecycleSnapshot('
        'phase: $phase, '
        'visibleFraction: $visibleFraction, '
        'appState: $appState)';
  }
}
