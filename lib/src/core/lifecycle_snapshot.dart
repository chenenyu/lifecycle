import 'package:flutter/widgets.dart';

import 'lifecycle_event.dart';

/// An immutable, normalized view of a lifecycle node's effective state.
@immutable
class LifecycleSnapshot {
  /// Creates a lifecycle snapshot.
  const LifecycleSnapshot({
    required this.attached,
    required this.visible,
    required this.active,
    required this.visibleFraction,
    required this.phase,
    this.appState,
  });

  /// Creates the initial state of a controller that is not attached.
  const LifecycleSnapshot.detached()
      : attached = false,
        visible = false,
        active = false,
        visibleFraction = 0,
        phase = LifecyclePhase.detached,
        appState = null;

  /// Whether the node has been attached to the lifecycle tree.
  final bool attached;

  /// Whether this node and every ancestor are visible.
  final bool visible;

  /// Whether this node and every ancestor are active.
  final bool active;

  /// The normalized effective visible fraction in the range 0–1.
  final double visibleFraction;

  /// The phase derived from the other snapshot fields.
  final LifecyclePhase phase;

  /// The latest application lifecycle state inherited by this node.
  final AppLifecycleState? appState;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is LifecycleSnapshot &&
            attached == other.attached &&
            visible == other.visible &&
            active == other.active &&
            visibleFraction == other.visibleFraction &&
            phase == other.phase &&
            appState == other.appState;
  }

  @override
  int get hashCode =>
      Object.hash(attached, visible, active, visibleFraction, phase, appState);

  @override
  String toString() {
    return 'LifecycleSnapshot('
        'phase: $phase, '
        'attached: $attached, '
        'visible: $visible, '
        'active: $active, '
        'visibleFraction: $visibleFraction, '
        'appState: $appState)';
  }
}
