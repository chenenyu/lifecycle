/*
 * LifecycleController 父子合成实验页。
 *
 * 页面允许分别编辑父子本地约束，并实时展示有效 Snapshot，用来观察 phase 交集、可见
 * 比例取最小值和事件传播。布尔 UI 会先规范化为 LifecycleConstraint，避免实验页构造
 * 框架本身不允许的矛盾状态。
 */
import 'package:flutter/material.dart';
import 'package:lifecycle/lifecycle.dart';

import '../logging/demo_log.dart';
import '../widgets/demo_scaffold.dart';
import '../widgets/demo_widgets.dart';

/// 可交互编辑父子约束的 Controller 合成实验页。
class ControllerLabScreen extends StatefulWidget {
  const ControllerLabScreen({super.key});

  @override
  State<ControllerLabScreen> createState() => _ControllerLabScreenState();
}

class _ControllerLabScreenState extends State<ControllerLabScreen> {
  final DemoLog _log = DemoLog();
  late final LifecycleController _parent;
  late final LifecycleController _child;

  bool _parentVisible = true;
  bool _parentActive = true;
  double _parentFraction = 1;
  bool _childVisible = true;
  bool _childActive = true;
  double _childFraction = 1;

  @override
  void initState() {
    super.initState();
    // 先完成 late final 赋值再 attach；attach 会同步通知监听器，级联写法会让
    // 回调在字段赋值完成前读取字段并触发 LateInitializationError。
    _parent = LifecycleController(debugLabel: 'LabParent');
    _parent
      ..addListener(_recordParentTransition)
      ..attach(cause: LifecycleCause.custom);
    _child = LifecycleController(debugLabel: 'LabChild');
    _child
      ..addListener(_recordChildTransition)
      ..attach(parent: _parent, cause: LifecycleCause.custom);
  }

  void _recordParentTransition() {
    _log.record('parent', _parent.lastTransition!);
  }

  void _recordChildTransition() {
    _log.record('child', _child.lastTransition!);
  }

  void _updateParent() {
    _parent.updateLocal(
      constraint: _constraintFor(
        visible: _parentVisible,
        active: _parentActive,
        fraction: _parentFraction,
      ),
      cause: LifecycleCause.custom,
    );
  }

  void _updateChild() {
    _child.updateLocal(
      constraint: _constraintFor(
        visible: _childVisible,
        active: _childActive,
        fraction: _childFraction,
      ),
      cause: LifecycleCause.custom,
    );
  }

  @override
  Widget build(BuildContext context) {
    return DemoScaffold(
      title: 'Controller composition lab',
      log: _log,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const DemoInstructions(
            action: 'change the parent and child restrictions independently.',
            expected:
                'effective booleans are logical intersections and the child fraction is min(parent, child).',
          ),
          _ControllerEditor(
            label: 'Parent local restrictions',
            visible: _parentVisible,
            active: _parentActive,
            fraction: _parentFraction,
            onVisibleChanged: (value) {
              setState(() => _parentVisible = value);
              _updateParent();
            },
            onActiveChanged: (value) {
              setState(() => _parentActive = value);
              _updateParent();
            },
            onFractionChanged: (value) {
              setState(() => _parentFraction = value);
              _updateParent();
            },
          ),
          ValueListenableBuilder<LifecycleSnapshot>(
            valueListenable: _parent,
            builder: (context, value, child) =>
                _SnapshotCard(label: 'Parent effective', snapshot: value),
          ),
          const Divider(height: 32),
          _ControllerEditor(
            label: 'Child local restrictions',
            visible: _childVisible,
            active: _childActive,
            fraction: _childFraction,
            onVisibleChanged: (value) {
              setState(() => _childVisible = value);
              _updateChild();
            },
            onActiveChanged: (value) {
              setState(() => _childActive = value);
              _updateChild();
            },
            onFractionChanged: (value) {
              setState(() => _childFraction = value);
              _updateChild();
            },
          ),
          ValueListenableBuilder<LifecycleSnapshot>(
            valueListenable: _child,
            builder: (context, value, child) =>
                _SnapshotCard(label: 'Child effective', snapshot: value),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _child.disposeWithCause(LifecycleCause.custom);
    _parent.disposeWithCause(LifecycleCause.custom);
    _log.dispose();
    super.dispose();
  }
}

LifecycleConstraint _constraintFor({
  required bool visible,
  required bool active,
  required double fraction,
}) {
  if (!visible || fraction <= 0) return const LifecycleConstraint.hidden();
  if (active) return LifecycleConstraint.active(visibleFraction: fraction);
  return LifecycleConstraint.visible(visibleFraction: fraction);
}

/// 编辑单个本地约束的布尔状态和可见比例。
class _ControllerEditor extends StatelessWidget {
  const _ControllerEditor({
    required this.label,
    required this.visible,
    required this.active,
    required this.fraction,
    required this.onVisibleChanged,
    required this.onActiveChanged,
    required this.onFractionChanged,
  });

  final String label;
  final bool visible;
  final bool active;
  final double fraction;
  final ValueChanged<bool> onVisibleChanged;
  final ValueChanged<bool> onActiveChanged;
  final ValueChanged<double> onFractionChanged;

  @override
  Widget build(BuildContext context) {
    return Card.outlined(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: Theme.of(context).textTheme.titleMedium),
            Wrap(
              spacing: 12,
              children: [
                FilterChip(
                  label: const Text('visible'),
                  selected: visible,
                  onSelected: onVisibleChanged,
                ),
                FilterChip(
                  label: const Text('active'),
                  selected: active,
                  onSelected: onActiveChanged,
                ),
              ],
            ),
            Row(
              children: [
                const Text('fraction'),
                Expanded(
                  child: Slider(
                    value: fraction,
                    divisions: 20,
                    label: fraction.toStringAsFixed(2),
                    onChanged: onFractionChanged,
                  ),
                ),
                SizedBox(width: 36, child: Text(fraction.toStringAsFixed(2))),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// 以诊断友好的格式展示有效 Snapshot。
class _SnapshotCard extends StatelessWidget {
  const _SnapshotCard({required this.label, required this.snapshot});

  final String label;
  final LifecycleSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: ListTile(
        title: Text('$label: ${snapshot.phase.name}'),
        subtitle: Text(
          'visible=${snapshot.visible}, active=${snapshot.active}, '
          'fraction=${snapshot.visibleFraction.toStringAsFixed(2)}',
        ),
      ),
    );
  }
}
