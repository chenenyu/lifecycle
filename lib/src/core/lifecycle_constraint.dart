import 'package:flutter/foundation.dart';

import 'lifecycle_event.dart';

/// A normalized local restriction applied to a lifecycle node.
///
/// Unlike a set of independent visibility fields, a constraint can only
/// represent the three valid local states: hidden, visible, or active.
@immutable
class LifecycleConstraint {
  const LifecycleConstraint._({
    required this.phase,
    required this.visibleFraction,
  });

  /// Prevents the node from being visible or active.
  const LifecycleConstraint.hidden()
      : this._(
          phase: LifecyclePhase.hidden,
          visibleFraction: 0,
        );

  /// Allows the node to be visible, but not active.
  const LifecycleConstraint.visible({this.visibleFraction = 1})
      : assert(visibleFraction > 0 && visibleFraction <= 1),
        phase = LifecyclePhase.visible;

  /// Allows the node to be both visible and active.
  const LifecycleConstraint.active({this.visibleFraction = 1})
      : assert(visibleFraction > 0 && visibleFraction <= 1),
        phase = LifecyclePhase.active;

  /// The local phase allowed by this constraint.
  final LifecyclePhase phase;

  /// The local visible fraction in the range (0, 1], or zero when hidden.
  final double visibleFraction;

  /// Whether local visibility is allowed.
  bool get visible => phase != LifecyclePhase.hidden;

  /// Whether local activity is allowed.
  bool get active => phase == LifecyclePhase.active;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is LifecycleConstraint &&
            phase == other.phase &&
            visibleFraction == other.visibleFraction;
  }

  @override
  int get hashCode => Object.hash(phase, visibleFraction);

  @override
  String toString() {
    return 'LifecycleConstraint('
        'phase: $phase, '
        'visibleFraction: $visibleFraction)';
  }
}
