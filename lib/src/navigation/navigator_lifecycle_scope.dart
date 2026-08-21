/*
 * 将 NavigatorLifecycleController 接入外层生命周期树。
 *
 * Scope 在依赖变化时 attach/reparent Navigator 根节点，在 Widget 替换或销毁时 detach，
 * 并向 Navigator 子树注入 route resolver。这样嵌套 Navigator 能拥有独立历史，同时
 * 仍受外层 App、Route、Page 等状态约束。
 */
part of 'navigator_lifecycle_controller.dart';

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

/// 负责 Navigator 根节点的 attach、reparent 和 detach 时序。
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
