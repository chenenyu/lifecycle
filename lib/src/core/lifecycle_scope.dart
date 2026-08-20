import 'package:flutter/widgets.dart';

import 'lifecycle_controller.dart';

/// Exposes a lifecycle controller to descendant lifecycle widgets.
///
/// The current route identity is captured automatically from [context]. The
/// scope does not own [controller]; its creator remains responsible for
/// disposing it.
class LifecycleScope extends StatelessWidget {
  /// Creates a scope for [controller].
  const LifecycleScope({
    super.key,
    required this.controller,
    required this.child,
  });

  /// The controller provided by this scope.
  final LifecycleController controller;

  /// Subtree that inherits [controller].
  final Widget child;

  /// Returns the closest lifecycle controller, or null when none exists.
  static LifecycleController? maybeOf(BuildContext context) {
    return _LifecycleScopeData.maybeOf(context)?.controller;
  }

  /// Returns the closest lifecycle controller and asserts that one exists.
  static LifecycleController of(BuildContext context) {
    final result = maybeOf(context);
    assert(result != null, 'No LifecycleScope found in context.');
    return result!;
  }

  @override
  Widget build(BuildContext context) {
    return _LifecycleScopeData(
      controller: controller,
      route: ModalRoute.of(context),
      child: child,
    );
  }
}

class _LifecycleScopeData extends InheritedWidget {
  const _LifecycleScopeData({
    required this.controller,
    required this.route,
    required super.child,
  });

  final LifecycleController controller;
  final ModalRoute<dynamic>? route;

  static _LifecycleScopeData? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<_LifecycleScopeData>();
  }

  @override
  bool updateShouldNotify(_LifecycleScopeData oldWidget) {
    return controller != oldWidget.controller || route != oldWidget.route;
  }
}

typedef LifecycleRouteResolver = LifecycleController? Function(
    Route<dynamic> route);

class LifecycleRouteResolverScope extends InheritedWidget {
  const LifecycleRouteResolverScope({
    super.key,
    required this.resolver,
    required super.child,
  });

  final LifecycleRouteResolver resolver;

  static LifecycleRouteResolverScope? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<LifecycleRouteResolverScope>();
  }

  @override
  bool updateShouldNotify(LifecycleRouteResolverScope oldWidget) {
    return resolver != oldWidget.resolver;
  }
}

LifecycleController? resolveLifecycleParent(BuildContext context) {
  final localScope = _LifecycleScopeData.maybeOf(context);
  final route = ModalRoute.of(context);

  if (localScope != null && localScope.route == route) {
    return localScope.controller;
  }

  final routeResolver = LifecycleRouteResolverScope.maybeOf(context);
  if (route != null && routeResolver != null) {
    final routeController = routeResolver.resolver(route);
    if (routeController != null) {
      return routeController;
    }
  }

  return localScope?.controller;
}
