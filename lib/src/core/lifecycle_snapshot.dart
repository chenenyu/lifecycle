/*
 * 表示节点与全部祖先合成后的不可变有效状态。
 *
 * 每个 Phase 使用独立命名构造器，并从 phase 派生 attached/visible/active，避免重复
 * 状态源。Snapshot 采用值相等，因此 Controller 能过滤幂等更新，同时仍会识别
 * visibleFraction 或 appState 的真实变化。
 */
import 'package:flutter/widgets.dart';

import 'lifecycle_event.dart';

/// An immutable, normalized view of a lifecycle node's effective state.
@immutable
class LifecycleSnapshot {
  const LifecycleSnapshot._({
    required this.phase,
    required this.visibleFraction,
    this.appState,
  });

  /// Creates the initial state of a controller that is not attached.
  const LifecycleSnapshot.detached()
      : this._(
          phase: LifecyclePhase.detached,
          visibleFraction: 0,
        );

  /// Creates an attached snapshot that is neither visible nor active.
  const LifecycleSnapshot.hidden({this.appState})
      : phase = LifecyclePhase.hidden,
        visibleFraction = 0;

  /// Creates an attached, visible snapshot that is not active.
  const LifecycleSnapshot.visible({
    this.visibleFraction = 1,
    this.appState,
  })  : assert(visibleFraction > 0 && visibleFraction <= 1),
        phase = LifecyclePhase.visible;

  /// Creates an attached, visible, and active snapshot.
  const LifecycleSnapshot.active({
    this.visibleFraction = 1,
    this.appState,
  })  : assert(visibleFraction > 0 && visibleFraction <= 1),
        phase = LifecyclePhase.active;

  /// Creates the terminal snapshot of a disposed controller.
  const LifecycleSnapshot.disposed({this.appState})
      : phase = LifecyclePhase.disposed,
        visibleFraction = 0;

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
