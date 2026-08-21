/*
 * 演示嵌套 Navigator 拥有独立生命周期历史。
 *
 * 内层 Navigator 使用自己的 Controller、Observer 和 Scope；外层路由变化仍通过父节点
 * 约束内层所有页面，避免把两个 Navigator 的 Route 栈错误合并。
 */
import 'package:flutter/material.dart';
import 'package:lifecycle/lifecycle.dart';

import '../logging/demo_log.dart';
import '../widgets/demo_scaffold.dart';
import '../widgets/demo_widgets.dart';
import '../widgets/lifecycle_status_card.dart';

/// 为内层 Navigator 安装独立 Controller 的示例页。
class NestedNavigatorScreen extends StatefulWidget {
  const NestedNavigatorScreen({super.key, required this.log});

  final DemoLog log;

  @override
  State<NestedNavigatorScreen> createState() => _NestedNavigatorScreenState();
}

class _NestedNavigatorScreenState extends State<NestedNavigatorScreen> {
  final NavigatorLifecycleController _navigation = NavigatorLifecycleController(
    debugLabel: 'NestedDemoNavigator',
  );
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    return DemoScaffold(
      title: 'Nested Navigator',
      log: widget.log,
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(12),
            child: DemoInstructions(
              action: 'push and pop inside the embedded Navigator.',
              expected:
                  'only the nested route history changes; the outer demo route remains active as its parent.',
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: Border.all(color: Theme.of(context).dividerColor),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: NavigatorLifecycleScope(
                    controller: _navigation,
                    child: Navigator(
                      key: _navigatorKey,
                      observers: [_navigation.observer],
                      initialRoute: '/nested/home',
                      onGenerateRoute: (settings) {
                        return MaterialPageRoute<void>(
                          settings: settings,
                          builder: (context) =>
                              settings.name == '/nested/details'
                              ? _NestedPage(
                                  title: 'Nested details',
                                  source: 'nested details route',
                                  log: widget.log,
                                  button: FilledButton.icon(
                                    key: const ValueKey('nested-pop'),
                                    onPressed: () => Navigator.pop(context),
                                    icon: const Icon(Icons.arrow_back),
                                    label: const Text('Pop nested route'),
                                  ),
                                )
                              : _NestedPage(
                                  title: 'Nested home',
                                  source: 'nested home route',
                                  log: widget.log,
                                  button: FilledButton.icon(
                                    key: const ValueKey('nested-push'),
                                    onPressed: () => Navigator.pushNamed(
                                      context,
                                      '/nested/details',
                                    ),
                                    icon: const Icon(Icons.arrow_forward),
                                    label: const Text('Push nested route'),
                                  ),
                                ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _navigation.dispose();
    super.dispose();
  }
}

/// 内层路由的探针页面，通过按钮推进或回退局部历史。
class _NestedPage extends StatelessWidget {
  const _NestedPage({
    required this.title,
    required this.source,
    required this.log,
    required this.button,
  });

  final String title;
  final String source;
  final DemoLog log;
  final Widget button;

  @override
  Widget build(BuildContext context) {
    return LifecycleListener(
      onTransition: (transition) => log.record(source, transition),
      child: ColoredBox(
        color: Theme.of(context).colorScheme.surface,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(title, style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 12),
                  LifecycleStatusCard(label: title),
                  const SizedBox(height: 12),
                  button,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
