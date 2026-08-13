import 'package:flutter/widgets.dart';

import '../core/lifecycle_scope.dart';
import 'navigator_lifecycle_controller.dart';

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
    widget.controller.attach(resolveLifecycleParent(context));
  }

  @override
  void didUpdateWidget(NavigatorLifecycleScope oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.detach();
      widget.controller.attach(resolveLifecycleParent(context));
    }
  }

  @override
  Widget build(BuildContext context) {
    return LifecycleRouteResolverScope(
      resolver: widget.controller.controllerFor,
      child: widget.child,
    );
  }

  @override
  void dispose() {
    widget.controller.detach();
    super.dispose();
  }
}
