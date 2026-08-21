/*
 * 在应用 Widget 树顶层安装 AppLifecycleController 和 LifecycleScope。
 *
 * 组件既支持内部创建 Controller，也支持外部注入；State 仅销毁自己拥有的实例，
 * 并在 Controller 替换时重新绑定监听范围，避免双重 dispose 和旧根节点残留。
 */
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

/// 维护根 Controller 的所有权，并把它同步到 Widget 树。
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
      // 外部 Controller 替换时，仅释放本 State 拥有的实例；调用方注入对象的生命周期
      // 仍由调用方负责。
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
      child: widget.child,
    );
  }

  @override
  void dispose() {
    if (_ownsController) _controller.dispose();
    super.dispose();
  }
}
