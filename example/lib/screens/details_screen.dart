/*
 * 普通详情路由及非透明 Dialog 的演示页面。
 *
 * LifecycleProbe 记录路由进入、遮挡和关闭过程，Dialog 用于验证下层页面保持 visible 但
 * inactive，以及关闭后的 terminal Snapshot 仍保留继承 AppLifecycleState。
 */
import 'package:flutter/material.dart';
import 'package:lifecycle/lifecycle.dart';

import '../logging/demo_log.dart';
import '../widgets/demo_scaffold.dart';
import '../widgets/demo_widgets.dart';
import '../widgets/lifecycle_status_card.dart';

/// 展示普通详情路由与非透明 Dialog 遮挡行为。
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
