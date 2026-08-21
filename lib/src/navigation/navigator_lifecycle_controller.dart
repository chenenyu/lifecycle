/*
 * 管理单个 Navigator 的路由生命周期历史和有效状态。
 *
 * 主 Controller 维护路由栈、遮挡关系和返回手势；Observer、Scope、RouteEntry 拆为
 * part 文件但仍属于同一 library，因此可以共享私有 API 而不扩大公开面。自顶向下
 * 计算 opaque 遮挡可正确处理普通页面、非透明 Dialog 和交互式返回。
 */
import 'package:flutter/widgets.dart';

import '../core/lifecycle_constraint.dart';
import '../core/lifecycle_controller.dart';
import '../core/lifecycle_event.dart';
import '../core/lifecycle_scope.dart';
import '../core/lifecycle_snapshot.dart';

part 'navigator_lifecycle_observer.dart';
part 'navigator_lifecycle_scope.dart';
part 'route_lifecycle_entry.dart';

/// Owns route lifecycle state for exactly one Flutter Navigator.
class NavigatorLifecycleController {
  /// Creates a controller and its paired [observer].
  NavigatorLifecycleController({String? debugLabel})
      : _root = LifecycleController(
          debugLabel: debugLabel ?? 'NavigatorLifecycleController',
        ) {
    observer = _NavigatorLifecycleObserver(this);
    _unknownRouteController = LifecycleController(
      constraint: const LifecycleConstraint.hidden(),
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
      constraint: const LifecycleConstraint.active(),
      cause: LifecycleCause.route,
    );
  }

  /// Makes every route inactive while keeping the controller reusable.
  void _detach() {
    if (_disposed || !_root.isAttached) return;
    _root.updateLocal(
      constraint: const LifecycleConstraint.hidden(),
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
    // 从栈顶向下扫描：遇到首个 opaque route 后，更低层路由全部隐藏；返回手势中的
    // previousRoute 是例外，它需要提前恢复可见但仍保持 inactive。
    var coveredByOpaqueRoute = false;
    for (var index = _history.length - 1; index >= 0; index--) {
      final entry = _history[index];
      final gestureVisible = identical(entry.route, _gesturePreviousRoute);
      final visible = !coveredByOpaqueRoute || gestureVisible;
      final active = index == _history.length - 1;
      entry.update(
        constraint: !visible
            ? const LifecycleConstraint.hidden()
            : active
                ? const LifecycleConstraint.active()
                : const LifecycleConstraint.visible(),
        cause: cause,
      );
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
