/*
 * example 使用的轻量说明和导航组件。
 *
 * 这些 Widget 只负责一致的视觉表达，不感知生命周期状态；将展示组件与 demo 的状态机
 * 分离后，示例代码能把重点放在 Lifecycle API 的接线与事件上。
 */
import 'package:flutter/material.dart';

/// 用统一样式描述 demo 操作和预期结果。
class DemoInstructions extends StatelessWidget {
  const DemoInstructions({
    super.key,
    required this.action,
    required this.expected,
  });

  final String action;
  final String expected;

  @override
  Widget build(BuildContext context) {
    return Card.outlined(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.science_outlined,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 10),
            Expanded(child: Text('操作：$action\n预期：$expected')),
          ],
        ),
      ),
    );
  }
}

/// 首页使用的标准 demo 导航条目。
class DemoNavigationTile extends StatelessWidget {
  const DemoNavigationTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
