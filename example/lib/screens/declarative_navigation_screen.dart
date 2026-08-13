import 'package:flutter/material.dart';
import 'package:lifecycle/lifecycle.dart';

import '../logging/demo_log.dart';
import '../widgets/demo_scaffold.dart';
import '../widgets/demo_widgets.dart';
import '../widgets/lifecycle_status_card.dart';

class DeclarativeNavigationScreen extends StatefulWidget {
  const DeclarativeNavigationScreen({super.key, required this.log});

  final DemoLog log;

  @override
  State<DeclarativeNavigationScreen> createState() =>
      _DeclarativeNavigationScreenState();
}

class _DeclarativeNavigationScreenState
    extends State<DeclarativeNavigationScreen> {
  final NavigatorLifecycleController _navigation = NavigatorLifecycleController(
    debugLabel: 'PagesApiNavigator',
  );
  bool _showDetails = false;

  @override
  Widget build(BuildContext context) {
    return DemoScaffold(
      title: 'Navigator pages API',
      log: widget.log,
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(12),
            child: DemoInstructions(
              action: 'add and remove the second MaterialPage declaratively.',
              expected:
                  'the first page hides while covered, then reappears when the second page leaves the list.',
            ),
          ),
          Expanded(
            child: NavigatorLifecycleScope(
              controller: _navigation,
              child: Navigator(
                observers: [_navigation.observer],
                pages: [
                  MaterialPage<void>(
                    key: const ValueKey('declarative-home-page'),
                    name: '/pages/home',
                    child: _DeclarativePage(
                      label: 'Declarative home',
                      source: 'pages API home',
                      log: widget.log,
                      action: FilledButton(
                        key: const ValueKey('add-declarative-page'),
                        onPressed: () => setState(() => _showDetails = true),
                        child: const Text('Add details page'),
                      ),
                    ),
                  ),
                  if (_showDetails)
                    MaterialPage<void>(
                      key: const ValueKey('declarative-details-page'),
                      name: '/pages/details',
                      child: _DeclarativePage(
                        label: 'Declarative details',
                        source: 'pages API details',
                        log: widget.log,
                        action: FilledButton(
                          key: const ValueKey('remove-declarative-page'),
                          onPressed: () => setState(() => _showDetails = false),
                          child: const Text('Remove details page'),
                        ),
                      ),
                    ),
                ],
                onDidRemovePage: (page) {
                  if (page.name == '/pages/details' && _showDetails) {
                    setState(() => _showDetails = false);
                  }
                },
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

class _DeclarativePage extends StatelessWidget {
  const _DeclarativePage({
    required this.label,
    required this.source,
    required this.log,
    required this.action,
  });

  final String label;
  final String source;
  final DemoLog log;
  final Widget action;

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
                  LifecycleStatusCard(label: label),
                  const SizedBox(height: 12),
                  action,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
