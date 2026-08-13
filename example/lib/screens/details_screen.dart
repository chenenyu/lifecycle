import 'package:flutter/material.dart';
import 'package:lifecycle/lifecycle.dart';

import '../logging/demo_log.dart';
import '../widgets/demo_scaffold.dart';
import '../widgets/demo_widgets.dart';
import '../widgets/lifecycle_status_card.dart';

class DetailsScreen extends StatelessWidget {
  const DetailsScreen({super.key, required this.log});

  final DemoLog log;

  @override
  Widget build(BuildContext context) {
    return LifecycleListener(
      onTransition: (transition) => log.record('details route', transition),
      child: DemoScaffold(
        title: 'Route lifecycle',
        log: log,
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: const [
            DemoInstructions(
              action: 'use the system Back button or the app-bar Back button.',
              expected:
                  'this route emits deactivated, disappeared and disposed; the home route reappears and activates.',
            ),
            LifecycleStatusCard(label: 'Details route'),
          ],
        ),
      ),
    );
  }
}
