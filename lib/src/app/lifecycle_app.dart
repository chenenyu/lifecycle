import 'package:flutter/widgets.dart';

import '../core/lifecycle_scope.dart';
import 'app_lifecycle_controller.dart';

/// Installs the root application lifecycle scope above [child].
class LifecycleApp extends StatefulWidget {
  /// Creates an app scope, optionally using an externally owned [controller].
  const LifecycleApp({super.key, this.controller, required this.child});

  /// Controller to expose; when omitted the widget creates and owns one.
  final AppLifecycleController? controller;

  /// Subtree that inherits the application lifecycle.
  final Widget child;

  @override
  State<LifecycleApp> createState() => _LifecycleAppState();
}

class _LifecycleAppState extends State<LifecycleApp> {
  late AppLifecycleController _controller;
  late bool _ownsController;

  @override
  void initState() {
    super.initState();
    _setController(widget.controller);
  }

  @override
  void didUpdateWidget(LifecycleApp oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      if (_ownsController) _controller.dispose();
      _setController(widget.controller);
    }
  }

  void _setController(AppLifecycleController? controller) {
    _ownsController = controller == null;
    _controller = controller ?? AppLifecycleController();
  }

  @override
  Widget build(BuildContext context) {
    return LifecycleScope(
      controller: _controller,
      kind: LifecycleScopeKind.app,
      route: null,
      child: widget.child,
    );
  }

  @override
  void dispose() {
    if (_ownsController) _controller.dispose();
    super.dispose();
  }
}
