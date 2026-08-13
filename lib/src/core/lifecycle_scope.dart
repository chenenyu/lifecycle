import 'package:flutter/widgets.dart';

import 'lifecycle_controller.dart';

/// The container represented by a [LifecycleScope].
enum LifecycleScopeKind {
  /// Application root scope.
  app,

  /// Navigator route scope.
  route,

  /// PageView or TabBarView child scope.
  page,

  /// Scrollable viewport item scope.
  viewport,

  /// Application-defined boundary scope.
  custom,
}

/// Exposes a lifecycle controller to descendant lifecycle widgets.
class LifecycleScope extends InheritedWidget {
  /// Creates a lifecycle scope.
  const LifecycleScope({
    super.key,
    required this.controller,
    required this.kind,
    required this.route,
    required super.child,
  });

  /// The controller provided by this scope.
  final LifecycleController controller;

  /// The type of container represented by the scope.
  final LifecycleScopeKind kind;

  /// Route in which the scope was created, or null above a Navigator.
  final ModalRoute<dynamic>? route;

  /// Returns the closest declared scope, or null when none exists.
  static LifecycleScope? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<LifecycleScope>();
  }

  /// Returns the closest declared scope and asserts that one exists.
  static LifecycleScope of(BuildContext context) {
    final result = maybeOf(context);
    assert(result != null, 'No LifecycleScope found in context.');
    return result!;
  }

  @override
  bool updateShouldNotify(LifecycleScope oldWidget) {
    return controller != oldWidget.controller ||
        kind != oldWidget.kind ||
        route != oldWidget.route;
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
  final localScope = LifecycleScope.maybeOf(context);
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
