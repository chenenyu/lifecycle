/*
 * 通过 InheritedWidget 在 Widget 树中传播 LifecycleController。
 *
 * 普通后代读取最近节点；导航场景额外用私有 route resolver 将当前 ModalRoute 映射
 * 到对应 Controller。Scope 只暴露 controller/child，路由识别留在内部，以避免调用方
 * 构造与 Navigator 历史不一致的作用域。
 */
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

/// 实际参与依赖追踪的私有 InheritedWidget，避免公开 Scope 暴露继承实现。
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
  // Navigator 子树优先按 ModalRoute 解析路由节点；找不到 Route 或 resolver 时才回退到
  // 最近普通 Scope，避免移除动画中的 route 意外继承 App 根节点。
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
