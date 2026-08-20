import 'package:flutter/widgets.dart';

import '../core/lifecycle_controller.dart';
import '../core/lifecycle_event.dart';
import '../core/lifecycle_scope.dart';
import '../core/lifecycle_snapshot.dart';

/// Owns route lifecycle state for exactly one Flutter Navigator.
class NavigatorLifecycleController {
  /// Creates a controller and its paired [observer].
  NavigatorLifecycleController({String? debugLabel})
      : _root = LifecycleController(
          debugLabel: debugLabel ?? 'NavigatorLifecycleController',
        ) {
    observer = _NavigatorLifecycleObserver(this);
    _unknownRouteController = LifecycleController(
      visible: false,
      active: false,
      visibleFraction: 0,
      debugLabel: 'UnknownRoute',
    )..attach(parent: _root, cause: LifecycleCause.route);
  }

  final LifecycleController _root;

  /// Observer that must be installed on the associated Navigator.
  late final NavigatorObserver observer;
  late final LifecycleController _unknownRouteController;
  final List<_RouteLifecycleEntry> _history = [];
  Route<dynamic>? _gesturePreviousRoute;
  bool _disposed = false;

  /// Effective state of the Navigator hierarchy itself.
  LifecycleSnapshot get lifecycle => _root.value;

  /// Current routes in bottom-to-top order.
  List<Route<dynamic>> get routes =>
      List<Route<dynamic>>.unmodifiable(_history.map((entry) => entry.route));

  /// Navigator currently associated with [observer], if mounted.
  NavigatorState? get navigator => observer.navigator;

  /// Attaches the Navigator hierarchy to a containing lifecycle node.
  void _attach(LifecycleController? parent) {
    _ensureUsable();
    if (_root.isAttached) {
      _root.reparent(parent);
    } else {
      _root.attach(parent: parent);
    }
    _root.updateLocal(
      visible: true,
      active: true,
      visibleFraction: 1,
      cause: LifecycleCause.route,
    );
  }

  /// Makes every route inactive while keeping the controller reusable.
  void _detach() {
    if (_disposed || !_root.isAttached) return;
    _root.updateLocal(
      visible: false,
      active: false,
      visibleFraction: 0,
      cause: LifecycleCause.route,
    );
  }

  /// Resolves the lifecycle controller for [route].
  LifecycleController _controllerFor(Route<dynamic> route) {
    for (final entry in _history.reversed) {
      if (identical(entry.route, route)) return entry.controller;
    }
    // Removed routes can remain mounted while their exit animation completes.
    // Keep their descendants inactive instead of falling back to the app scope.
    return _unknownRouteController;
  }

  _RouteLifecycleEntry? _entryFor(Route<dynamic> route) {
    for (final entry in _history.reversed) {
      if (identical(entry.route, route)) return entry;
    }
    return null;
  }

  /// Returns the top-most route whose settings use [name].
  Route<dynamic>? routeNamed(String name) {
    for (final entry in _history.reversed) {
      if (entry.route.settings.name == name) return entry.route;
    }
    return null;
  }

  /// Returns the effective lifecycle for a currently tracked [route].
  LifecycleSnapshot? lifecycleFor(Route<dynamic> route) {
    return _entryFor(route)?.lifecycle;
  }

  void _handlePush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _ensureUsable();
    if (_entryFor(route) == null) {
      _history.add(_RouteLifecycleEntry(route: route, parent: _root));
    }
    _recomputeRoutes(LifecycleCause.route);
  }

  void _handlePop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _removeRouteEntry(route, LifecycleCause.route);
  }

  void _handleRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _removeRouteEntry(route, LifecycleCause.route);
  }

  void _handleReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    _ensureUsable();
    if (newRoute == null || oldRoute == null) return;
    final index = _history.indexWhere(
      (entry) => identical(entry.route, oldRoute),
    );
    if (index < 0) return;
    final oldEntry = _history[index];
    final newEntry = _RouteLifecycleEntry(route: newRoute, parent: _root);
    _history[index] = newEntry;
    oldEntry.dispose();
    _recomputeRoutes(LifecycleCause.route);
  }

  void _handleTopChanged(
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

  void _handleGestureStarted(
    Route<dynamic> route,
    Route<dynamic>? previousRoute,
  ) {
    _ensureUsable();
    _gesturePreviousRoute = previousRoute;
    _recomputeRoutes(LifecycleCause.routeGesture);
  }

  void _handleGestureStopped() {
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
    _root.dispose();
  }
}

/// Connects a [NavigatorLifecycleController] to surrounding lifecycle scopes.
class NavigatorLifecycleScope extends StatefulWidget {
  /// Creates a Navigator lifecycle scope.
  const NavigatorLifecycleScope({
    super.key,
    required this.controller,
    required this.child,
  });

  /// Controller paired with the Navigator below [child].
  final NavigatorLifecycleController controller;

  /// Typically the Navigator produced by a WidgetsApp or nested Navigator.
  final Widget child;

  @override
  State<NavigatorLifecycleScope> createState() =>
      _NavigatorLifecycleScopeState();
}

class _NavigatorLifecycleScopeState extends State<NavigatorLifecycleScope> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    widget.controller._attach(resolveLifecycleParent(context));
  }

  @override
  void didUpdateWidget(NavigatorLifecycleScope oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller._detach();
      widget.controller._attach(resolveLifecycleParent(context));
    }
  }

  @override
  Widget build(BuildContext context) {
    return LifecycleRouteResolverScope(
      resolver: widget.controller._controllerFor,
      child: widget.child,
    );
  }

  @override
  void dispose() {
    widget.controller._detach();
    super.dispose();
  }
}

class _NavigatorLifecycleObserver extends NavigatorObserver {
  _NavigatorLifecycleObserver(this.controller);

  final NavigatorLifecycleController controller;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    controller._handlePush(route, previousRoute);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    controller._handlePop(route, previousRoute);
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    controller._handleRemove(route, previousRoute);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    controller._handleReplace(newRoute: newRoute, oldRoute: oldRoute);
  }

  @override
  void didChangeTop(Route<dynamic> topRoute, Route<dynamic>? previousTopRoute) {
    controller._handleTopChanged(topRoute, previousTopRoute);
  }

  @override
  void didStartUserGesture(
    Route<dynamic> route,
    Route<dynamic>? previousRoute,
  ) {
    controller._handleGestureStarted(route, previousRoute);
  }

  @override
  void didStopUserGesture() {
    controller._handleGestureStopped();
  }
}

class _RouteLifecycleEntry {
  _RouteLifecycleEntry({
    required this.route,
    required LifecycleController parent,
  }) : controller = LifecycleController(
          visible: false,
          active: false,
          visibleFraction: 0,
          debugLabel: 'Route(${route.settings.name ?? route.hashCode})',
        )..attach(parent: parent, cause: LifecycleCause.route);

  final Route<dynamic> route;
  final LifecycleController controller;

  LifecycleSnapshot get lifecycle => controller.value;

  void update({
    required bool visible,
    required bool active,
    LifecycleCause cause = LifecycleCause.route,
  }) {
    controller.updateLocal(
      visible: visible,
      active: active,
      visibleFraction: visible ? 1 : 0,
      cause: cause,
    );
  }

  void dispose({LifecycleCause cause = LifecycleCause.route}) {
    controller.disposeWithCause(cause);
  }
}
