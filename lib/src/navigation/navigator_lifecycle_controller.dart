import 'dart:collection';

import 'package:flutter/widgets.dart';

import '../core/lifecycle_controller.dart';
import '../core/lifecycle_event.dart';
import 'navigator_lifecycle_observer.dart';
import 'route_lifecycle_entry.dart';

/// Owns route lifecycle state for exactly one Flutter Navigator.
class NavigatorLifecycleController {
  /// Creates a controller and its paired [observer].
  NavigatorLifecycleController({String? debugLabel})
      : root = LifecycleController(
          debugLabel: debugLabel ?? 'NavigatorLifecycleController',
        ) {
    observer = NavigatorLifecycleObserver(this);
    _unknownRouteController = LifecycleController(
      visible: false,
      active: false,
      visibleFraction: 0,
      debugLabel: 'UnknownRoute',
    )..attach(parent: root, cause: LifecycleCause.route);
  }

  /// Root controller through which containing scopes restrict all routes.
  final LifecycleController root;

  /// Observer that must be installed on the associated Navigator.
  late final NavigatorLifecycleObserver observer;
  late final LifecycleController _unknownRouteController;
  final List<RouteLifecycleEntry> _history = [];
  Route<dynamic>? _gesturePreviousRoute;
  bool _disposed = false;

  /// Current route entries in bottom-to-top order.
  UnmodifiableListView<RouteLifecycleEntry> get routes =>
      UnmodifiableListView(_history);

  /// Navigator currently associated with [observer], if mounted.
  NavigatorState? get navigator => observer.navigator;

  /// Attaches the Navigator hierarchy to a containing lifecycle node.
  void attach(LifecycleController? parent) {
    _ensureUsable();
    if (root.isAttached) {
      root.reparent(parent);
    } else {
      root.attach(parent: parent);
    }
    root.updateLocal(
      visible: true,
      active: true,
      visibleFraction: 1,
      cause: LifecycleCause.route,
    );
  }

  /// Makes every route inactive while keeping the controller reusable.
  void detach() {
    if (_disposed || !root.isAttached) return;
    root.updateLocal(
      visible: false,
      active: false,
      visibleFraction: 0,
      cause: LifecycleCause.route,
    );
  }

  /// Resolves the lifecycle controller for [route].
  LifecycleController controllerFor(Route<dynamic> route) {
    for (final entry in _history.reversed) {
      if (identical(entry.route, route)) return entry.controller;
    }
    // Removed routes can remain mounted while their exit animation completes.
    // Keep their descendants inactive instead of falling back to the app scope.
    return _unknownRouteController;
  }

  /// Finds the tracked entry for [route].
  RouteLifecycleEntry? entryFor(Route<dynamic> route) {
    for (final entry in _history.reversed) {
      if (identical(entry.route, route)) return entry;
    }
    return null;
  }

  /// Finds the top-most route whose settings use [name].
  RouteLifecycleEntry? routeNamed(String name) {
    for (final entry in _history.reversed) {
      if (entry.route.settings.name == name) return entry;
    }
    return null;
  }

  /// Handles a route push forwarded by [observer].
  void handlePush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _ensureUsable();
    if (entryFor(route) == null) {
      _history.add(RouteLifecycleEntry(route: route, parent: root));
    }
    _recomputeRoutes(LifecycleCause.route);
  }

  /// Handles a route pop forwarded by [observer].
  void handlePop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _removeRouteEntry(route, LifecycleCause.route);
  }

  /// Handles a route removal forwarded by [observer].
  void handleRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _removeRouteEntry(route, LifecycleCause.route);
  }

  /// Handles route replacement forwarded by [observer].
  void handleReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    _ensureUsable();
    if (newRoute == null || oldRoute == null) return;
    final index = _history.indexWhere(
      (entry) => identical(entry.route, oldRoute),
    );
    if (index < 0) return;
    final oldEntry = _history[index];
    final newEntry = RouteLifecycleEntry(route: newRoute, parent: root);
    _history[index] = newEntry;
    oldEntry.dispose();
    _recomputeRoutes(LifecycleCause.route);
  }

  /// Reconciles route order when Navigator reports a new top route.
  void handleTopChanged(
    Route<dynamic> topRoute,
    Route<dynamic>? previousTopRoute,
  ) {
    _ensureUsable();
    final index = _history.indexWhere(
      (entry) => identical(entry.route, topRoute),
    );
    if (index >= 0 && index != _history.length - 1) {
      final entry = _history.removeAt(index);
      _history.add(entry);
    }
    _recomputeRoutes(LifecycleCause.route);
  }

  /// Exposes [previousRoute] during an interactive back gesture.
  void handleGestureStarted(
    Route<dynamic> route,
    Route<dynamic>? previousRoute,
  ) {
    _ensureUsable();
    _gesturePreviousRoute = previousRoute;
    _recomputeRoutes(LifecycleCause.routeGesture);
  }

  /// Ends an interactive back gesture without changing route history.
  void handleGestureStopped() {
    _ensureUsable();
    _gesturePreviousRoute = null;
    _recomputeRoutes(LifecycleCause.routeGesture);
  }

  void _removeRouteEntry(Route<dynamic> route, LifecycleCause cause) {
    _ensureUsable();
    final index = _history.indexWhere((entry) => identical(entry.route, route));
    if (index < 0) return;
    final entry = _history.removeAt(index);
    if (identical(_gesturePreviousRoute, route)) {
      _gesturePreviousRoute = null;
    }
    entry.dispose(cause: cause);
    _recomputeRoutes(cause);
  }

  void _recomputeRoutes(LifecycleCause cause) {
    var coveredByOpaqueRoute = false;
    for (var index = _history.length - 1; index >= 0; index--) {
      final entry = _history[index];
      final gestureVisible = identical(entry.route, _gesturePreviousRoute);
      final visible = !coveredByOpaqueRoute || gestureVisible;
      final active = index == _history.length - 1;
      entry.update(visible: visible, active: active, cause: cause);
      if (_isOpaque(entry.route)) {
        coveredByOpaqueRoute = true;
      }
    }
  }

  bool _isOpaque(Route<dynamic> route) {
    if (route is TransitionRoute<dynamic>) return route.opaque;
    return true;
  }

  /// Removes [route] through the mounted Navigator and completes its result.
  void removeRoute<T extends Object?>(Route<T> route, [T? result]) {
    final state = navigator;
    if (state == null) {
      throw StateError('NavigatorLifecycleController is not attached.');
    }
    state.removeRoute<T>(route, result);
  }

  void _ensureUsable() {
    if (_disposed) {
      throw StateError('NavigatorLifecycleController has been disposed.');
    }
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    for (final entry in _history.reversed) {
      entry.dispose();
    }
    _history.clear();
    _unknownRouteController.dispose();
    root.dispose();
  }
}
