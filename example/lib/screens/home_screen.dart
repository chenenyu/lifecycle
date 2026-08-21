import 'package:flutter/material.dart';
import 'package:lifecycle/lifecycle.dart';

import '../demo_routes.dart';
import '../logging/demo_log.dart';
import '../widgets/demo_scaffold.dart';
import '../widgets/demo_widgets.dart';
import '../widgets/lifecycle_status_card.dart';

class LifecycleHomeScreen extends StatefulWidget {
  const LifecycleHomeScreen({super.key, required this.log});

  final DemoLog log;

  @override
  State<LifecycleHomeScreen> createState() => _LifecycleHomeScreenState();
}

class _LifecycleHomeScreenState extends State<LifecycleHomeScreen>
    with LifecycleStateMixin<LifecycleHomeScreen> {
  bool _boundaryVisible = true;
  bool _boundaryActive = true;

  @override
  void onLifecycleTransition(LifecycleTransition transition) {
    widget.log.record('home route', transition);
  }

  Future<void> _showLifecycleDialog() {
    return showDialog<void>(
      context: context,
      routeSettings: const RouteSettings(name: '/dialog'),
      builder: (context) => LifecycleListener(
        onTransition: (transition) =>
            widget.log.record('dialog route', transition),
        child: AlertDialog(
          title: const Text('Non-opaque route'),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'The page behind this dialog stays visible, but becomes inactive.',
              ),
              SizedBox(height: 12),
              LifecycleStatusCard(label: 'Dialog route', compact: true),
            ],
          ),
          actions: [
            TextButton(
              key: const ValueKey('close-dialog'),
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );
  }

  void _open(String route) => Navigator.pushNamed(context, route);

  @override
  Widget build(BuildContext context) {
    return DemoScaffold(
      title: 'Lifecycle Lab',
      log: widget.log,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Composable lifecycle scopes',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 4),
          Text(
            'App → Route → Page → Viewport → Widget',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          const LifecycleStatusCard(label: 'Home widget'),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              SizedBox(
                width: 330,
                child: DemoNavigationTile(
                  key: const ValueKey('open-route-demo'),
                  title: 'Route lifecycle',
                  subtitle: 'Opaque routes, disposal and transition causes',
                  icon: Icons.layers_outlined,
                  onTap: () => _open(DemoRoutes.details),
                ),
              ),
              SizedBox(
                width: 330,
                child: DemoNavigationTile(
                  key: const ValueKey('open-page-demo'),
                  title: 'PageView & viewport',
                  subtitle: 'Drag fractions, settled activation and keep-alive',
                  icon: Icons.view_carousel_outlined,
                  onTap: () => _open(DemoRoutes.pages),
                ),
              ),
              SizedBox(
                width: 330,
                child: DemoNavigationTile(
                  key: const ValueKey('open-reorder-demo'),
                  title: 'Reorderable pages',
                  subtitle: 'Stable IDs, item removal and State preservation',
                  icon: Icons.swap_horiz,
                  onTap: () => _open(DemoRoutes.reorderablePages),
                ),
              ),
              SizedBox(
                width: 330,
                child: DemoNavigationTile(
                  key: const ValueKey('open-tab-demo'),
                  title: 'TabBarView lifecycle',
                  subtitle: 'Tap and swipe animations share one state model',
                  icon: Icons.tab_outlined,
                  onTap: () => _open(DemoRoutes.tabs),
                ),
              ),
              SizedBox(
                width: 330,
                child: DemoNavigationTile(
                  key: const ValueKey('open-viewport-demo'),
                  title: 'List/Grid viewport',
                  subtitle: 'Two-dimensional visible area and thresholds',
                  icon: Icons.grid_view_outlined,
                  onTap: () => _open(DemoRoutes.viewport),
                ),
              ),
              SizedBox(
                width: 330,
                child: DemoNavigationTile(
                  key: const ValueKey('open-nested-navigator-demo'),
                  title: 'Nested Navigator',
                  subtitle: 'Independent route histories and lifecycle roots',
                  icon: Icons.account_tree_outlined,
                  onTap: () => _open(DemoRoutes.nestedNavigator),
                ),
              ),
              SizedBox(
                width: 330,
                child: DemoNavigationTile(
                  key: const ValueKey('open-pages-api-demo'),
                  title: 'Navigator pages API',
                  subtitle: 'Declarative page additions and removals',
                  icon: Icons.dynamic_feed_outlined,
                  onTap: () => _open(DemoRoutes.declarativeNavigator),
                ),
              ),
              SizedBox(
                width: 330,
                child: DemoNavigationTile(
                  key: const ValueKey('open-controller-lab'),
                  title: 'Controller composition lab',
                  subtitle:
                      'Change parent and child restrictions interactively',
                  icon: Icons.tune,
                  onTap: () => _open(DemoRoutes.controllerLab),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          FilledButton.tonalIcon(
            key: const ValueKey('open-dialog-demo'),
            onPressed: _showLifecycleDialog,
            icon: const Icon(Icons.open_in_new),
            label: const Text('Open non-opaque dialog'),
          ),
          const Divider(height: 32),
          Text(
            'Custom boundary',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const DemoInstructions(
            action: 'toggle Visible and Active independently.',
            expected:
                'the boundary can restrict its child, but cannot make it more active than the route.',
          ),
          SwitchListTile(
            key: const ValueKey('boundary-visible-switch'),
            contentPadding: EdgeInsets.zero,
            title: const Text('Visible'),
            value: _boundaryVisible,
            onChanged: (value) => setState(() {
              _boundaryVisible = value;
              if (!value) _boundaryActive = false;
            }),
          ),
          SwitchListTile(
            key: const ValueKey('boundary-active-switch'),
            contentPadding: EdgeInsets.zero,
            title: const Text('Active'),
            value: _boundaryActive,
            onChanged: _boundaryVisible
                ? (value) => setState(() => _boundaryActive = value)
                : null,
          ),
          LifecycleBoundary(
            constraint: !_boundaryVisible
                ? const LifecycleConstraint.hidden()
                : _boundaryActive
                ? const LifecycleConstraint.active()
                : const LifecycleConstraint.visible(),
            onTransition: (transition) =>
                widget.log.record('custom boundary', transition),
            child: const LifecycleStatusCard(label: 'Boundary child'),
          ),
        ],
      ),
    );
  }
}
