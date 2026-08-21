/*
 * 生命周期树的核心状态机，负责父子合成、事件推导、通知和安全销毁。
 *
 * 节点保存一个本地 LifecycleConstraint，通过 min(fraction) 与父 Snapshot 合成有效
 * 状态；每次有效变化生成唯一 LifecycleTransition，并借助队列处理回调中的重入更新。
 * 父环校验、监听器隔离和延迟 finalize 共同规避递归通知、悬挂父引用及派发中销毁。
 */
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'lifecycle_constraint.dart';
import 'lifecycle_event.dart';
import 'lifecycle_snapshot.dart';
import 'lifecycle_transition.dart';

/// A lifecycle node that composes its local state with an optional parent.
///
/// It is also a [ValueListenable] for the latest [LifecycleSnapshot].
class LifecycleController extends ChangeNotifier
    implements ValueListenable<LifecycleSnapshot> {
  /// Creates a detached controller with the supplied local restrictions.
  LifecycleController({
    LifecycleConstraint constraint = const LifecycleConstraint.active(),
    AppLifecycleState? appState,
    this.debugLabel,
  })  : _localConstraint = constraint,
        _localAppState = appState;

  /// Optional label used when inspecting lifecycle trees in a debugger.
  final String? debugLabel;

  LifecycleConstraint _localConstraint;
  AppLifecycleState? _localAppState;

  bool _attached = false;
  bool _disposed = false;
  AppLifecycleState? _terminalAppState;
  LifecycleController? _parent;
  LifecycleSnapshot _value = const LifecycleSnapshot.detached();
  LifecycleTransition? _lastTransition;

  bool _emitting = false;

  // 回调可能再次更新当前节点。待处理标记把递归调用合并为下一轮计算，保证每个
  // Transition.previous 都等于上一轮已经交付的 current。
  bool _recomputePending = false;
  LifecycleCause _pendingCause = LifecycleCause.custom;
  bool _disposeAfterEmission = false;
  bool _changeNotifierDisposed = false;

  @override
  LifecycleSnapshot get value => _value;

  /// The most recent transition that caused [value] to change.
  ///
  /// This is null until the first snapshot change. Listeners registered with
  /// [addListener] can read this value synchronously from their callback.
  LifecycleTransition? get lastTransition => _lastTransition;

  /// The normalized local restriction composed with the parent snapshot.
  LifecycleConstraint get localConstraint => _localConstraint;

  /// Whether this node has been attached.
  bool get isAttached => _attached;

  /// Whether this controller has been disposed.
  bool get isDisposed => _disposed;

  /// The parent whose state restricts this node, if any.
  LifecycleController? get parent => _parent;

  /// Attaches this node and computes its first effective snapshot.
  void attach({
    LifecycleController? parent,
    LifecycleCause cause = LifecycleCause.widgetTree,
  }) {
    _ensureUsable();
    _setParent(parent);
    _attached = true;
    _recompute(cause);
  }

  /// Moves an attached node under [parent] without replacing the controller.
  void reparent(
    LifecycleController? parent, {
    LifecycleCause cause = LifecycleCause.widgetTree,
  }) {
    _ensureUsable();
    if (_parent == parent) return;
    _setParent(parent);
    if (_attached) {
      _recompute(cause);
    }
  }

  /// Updates the local restrictions that are composed with the parent.
  ///
  /// Set [clearAppState] to remove a local app-state override and inherit it
  /// from the parent again.
  void updateLocal({
    LifecycleConstraint? constraint,
    AppLifecycleState? appState,
    bool clearAppState = false,
    LifecycleCause cause = LifecycleCause.custom,
  }) {
    _ensureUsable();
    if (constraint != null) _localConstraint = constraint;
    if (clearAppState) {
      _localAppState = null;
    } else if (appState != null) {
      _localAppState = appState;
    }
    if (_attached) {
      _recompute(cause);
    }
  }

  void _setParent(LifecycleController? parent) {
    if (_parent == parent) return;
    _validateParent(parent);
    _parent?.removeListener(_handleParentChanged);
    _parent = parent;
    _parent?.addListener(_handleParentChanged);
  }

  void _validateParent(LifecycleController? parent) {
    if (parent == null) return;
    parent._ensureUsable();
    // 先沿候选父链检查环，再解除旧父监听；失败时原树结构保持不变。
    for (LifecycleController? ancestor = parent;
        ancestor != null;
        ancestor = ancestor._parent) {
      if (identical(ancestor, this)) {
        throw ArgumentError.value(
          parent,
          'parent',
          'A lifecycle controller cannot be its own ancestor.',
        );
      }
    }
  }

  void _handleParentChanged() {
    if (!_attached || _disposed) return;
    final transition = _parent?.lastTransition;
    if (transition == null) return;
    _recompute(transition.cause);
  }

  void _recompute(LifecycleCause cause) {
    if (_emitting) {
      _recomputePending = true;
      _pendingCause = cause;
      return;
    }

    try {
      // do/while 消费通知期间产生的最后一批更新。监听器保持同步调用，但不会形成
      // 深层递归栈或交付中间的半成品状态。
      LifecycleCause nextCause = cause;
      do {
        _recomputePending = false;
        _emitting = true;
        try {
          final previous = _value;
          final current = _buildSnapshot();
          if (current != previous) {
            _value = current;
            _lastTransition = LifecycleTransition(
              previous: previous,
              current: current,
              cause: nextCause,
              events: _deriveEvents(previous, current),
            );
            notifyListeners();
          }
        } finally {
          _emitting = false;
        }
        nextCause = _pendingCause;
      } while (_recomputePending);
    } finally {
      _emitting = false;
      if (_disposeAfterEmission && !_changeNotifierDisposed) {
        _finalizeDispose();
      }
    }
  }

  LifecycleSnapshot _buildSnapshot() {
    if (_disposed) {
      return LifecycleSnapshot.disposed(
        appState: _terminalAppState,
      );
    }
    if (!_attached) {
      return const LifecycleSnapshot.detached();
    }

    final parentSnapshot = _parent?.value;
    final parentVisible = parentSnapshot?.visible ?? true;
    final parentActive = parentSnapshot?.active ?? true;
    final parentFraction = parentSnapshot?.visibleFraction ?? 1;
    // 子节点不能比父节点拥有更高可见比例，visible/active 也只能逐层收窄。
    final visibleFraction =
        math.min(parentFraction, _localConstraint.visibleFraction);
    final visible =
        _localConstraint.visible && parentVisible && visibleFraction > 0;
    final active = visible && _localConstraint.active && parentActive;
    final appState = _localAppState ?? parentSnapshot?.appState;

    if (active) {
      return LifecycleSnapshot.active(
        visibleFraction: visibleFraction,
        appState: appState,
      );
    }
    if (visible) {
      return LifecycleSnapshot.visible(
        visibleFraction: visibleFraction,
        appState: appState,
      );
    }
    return LifecycleSnapshot.hidden(appState: appState);
  }

  static List<LifecycleEvent> _deriveEvents(
    LifecycleSnapshot previous,
    LifecycleSnapshot current,
  ) {
    final events = <LifecycleEvent>[];
    // 顺序固定为“先退出旧状态，再进入新状态”，terminal disposed 始终最后交付。
    if (!previous.attached && current.attached) {
      events.add(LifecycleEvent.created);
    }
    if (previous.active && !current.active) {
      events.add(LifecycleEvent.deactivated);
    }
    if (previous.visible && !current.visible) {
      events.add(LifecycleEvent.disappeared);
    }
    if (!previous.visible && current.visible) {
      events.add(LifecycleEvent.appeared);
    }
    if (!previous.active && current.active) {
      events.add(LifecycleEvent.activated);
    }
    if (previous.phase != LifecyclePhase.disposed &&
        current.phase == LifecyclePhase.disposed) {
      events.add(LifecycleEvent.disposed);
    }
    return events;
  }

  void _ensureUsable() {
    if (_disposed) {
      throw StateError('LifecycleController has already been disposed.');
    }
  }

  @override
  void dispose() {
    if (_disposed) return;
    try {
      _beginDispose(LifecycleCause.widgetTree);
    } finally {
      if (!_emitting && !_changeNotifierDisposed) {
        _changeNotifierDisposed = true;
        super.dispose();
      }
    }
  }

  /// Disposes this controller using an explicit transition [cause].
  void disposeWithCause(LifecycleCause cause) {
    if (_disposed) return;
    try {
      _beginDispose(cause);
    } finally {
      if (!_emitting && !_changeNotifierDisposed) {
        _finalizeDispose();
      }
    }
  }

  void _beginDispose(LifecycleCause cause) {
    // Capture inherited state before disconnecting from the parent. The
    // terminal snapshot must describe the latest effective app state even
    // though a disposed node no longer remains in the lifecycle tree.
    _terminalAppState =
        _localAppState ?? _parent?.value.appState ?? _value.appState;
    _setParent(null);
    _disposed = true;
    _attached = false;
    if (_emitting) {
      // ChangeNotifier 正在遍历监听器时不能立即 finalize；先排队 terminal Snapshot，
      // 等当前通知结束后再调用 super.dispose()。
      _recomputePending = true;
      _pendingCause = cause;
      _disposeAfterEmission = true;
    } else {
      _recompute(cause);
    }
  }

  void _finalizeDispose() {
    if (_changeNotifierDisposed) return;
    _changeNotifierDisposed = true;
    super.dispose();
  }
}
