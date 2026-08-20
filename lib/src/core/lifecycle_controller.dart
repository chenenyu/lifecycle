import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

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
    bool visible = true,
    bool active = true,
    double visibleFraction = 1,
    AppLifecycleState? appState,
    this.debugLabel,
  })  : _localVisible = visible,
        _localActive = active,
        _localVisibleFraction = _normalizeFraction(visibleFraction),
        _localAppState = appState;

  /// Optional label used when inspecting lifecycle trees in a debugger.
  final String? debugLabel;

  bool _localVisible;
  bool _localActive;
  double _localVisibleFraction;
  AppLifecycleState? _localAppState;

  bool _attached = false;
  bool _disposed = false;
  AppLifecycleState? _terminalAppState;
  LifecycleController? _parent;
  LifecycleSnapshot _value = const LifecycleSnapshot.detached();
  LifecycleTransition? _lastTransition;

  bool _emitting = false;
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
    bool? visible,
    bool? active,
    double? visibleFraction,
    AppLifecycleState? appState,
    bool clearAppState = false,
    LifecycleCause cause = LifecycleCause.custom,
  }) {
    _ensureUsable();
    if (visible != null) _localVisible = visible;
    if (active != null) _localActive = active;
    if (visibleFraction != null) {
      _localVisibleFraction = _normalizeFraction(visibleFraction);
    }
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
      return LifecycleSnapshot(
        phase: LifecyclePhase.disposed,
        visibleFraction: 0,
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
    final visibleFraction = math.min(parentFraction, _localVisibleFraction);
    final visible = _localVisible && parentVisible && visibleFraction > 0;
    final active = visible && _localActive && parentActive;

    final phase = active
        ? LifecyclePhase.active
        : visible
            ? LifecyclePhase.visible
            : LifecyclePhase.hidden;
    return LifecycleSnapshot(
      phase: phase,
      visibleFraction: visible ? visibleFraction : 0,
      appState: _localAppState ?? parentSnapshot?.appState,
    );
  }

  static List<LifecycleEvent> _deriveEvents(
    LifecycleSnapshot previous,
    LifecycleSnapshot current,
  ) {
    final events = <LifecycleEvent>[];
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

  static double _normalizeFraction(double value) {
    if (value.isNaN) return 0;
    return value.clamp(0.0, 1.0).toDouble();
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
