/*
 * 从最近 LifecycleScope 读取并可视化 Snapshot。
 *
 * LifecycleBuilder 确保 phase、fraction 或 appState 任一变化都会刷新卡片；compact 模式
 * 供 Grid/Page 等受限空间复用，帮助演示父级约束如何影响同一个后代组件。
 */
import 'package:flutter/material.dart';
import 'package:lifecycle/lifecycle.dart';

/// 实时展示最近作用域 Snapshot 的诊断卡片。
class LifecycleStatusCard extends StatelessWidget {
  const LifecycleStatusCard({
    super.key,
    required this.label,
    this.compact = false,
  });

  final String label;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return LifecycleBuilder(
      builder: (context, lifecycle) {
        final color = switch (lifecycle.phase) {
          LifecyclePhase.active => Colors.green,
          LifecyclePhase.visible => Colors.amber,
          LifecyclePhase.hidden => Colors.grey,
          LifecyclePhase.detached => Colors.blueGrey,
          LifecyclePhase.disposed => Colors.red,
        };
        return Card(
          key: ValueKey('status-$label'),
          color: color.withValues(alpha: 0.12),
          child: Padding(
            padding: EdgeInsets.all(compact ? 8 : 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        label,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    Chip(
                      visualDensity: VisualDensity.compact,
                      avatar: CircleAvatar(backgroundColor: color, radius: 5),
                      label: Text(lifecycle.phase.name),
                    ),
                  ],
                ),
                Text(
                  'visible: ${lifecycle.visible}  ·  '
                  'active: ${lifecycle.active}  ·  '
                  'fraction: ${lifecycle.visibleFraction.toStringAsFixed(2)}',
                ),
                if (!compact)
                  Text('app state: ${lifecycle.appState?.name ?? 'unknown'}'),
              ],
            ),
          ),
        );
      },
    );
  }
}
