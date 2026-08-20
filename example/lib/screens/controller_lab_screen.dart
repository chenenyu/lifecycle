import 'package:flutter/material.dart';
import 'package:lifecycle/lifecycle.dart';

import '../logging/demo_log.dart';
import '../widgets/demo_scaffold.dart';
import '../widgets/demo_widgets.dart';

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
    _parent = LifecycleController(debugLabel: 'LabParent')
      ..addListener(_recordParentTransition)
      ..attach(cause: LifecycleCause.custom);
    _child = LifecycleController(debugLabel: 'LabChild')
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
      visible: _parentVisible,
      active: _parentActive,
      visibleFraction: _parentFraction,
      cause: LifecycleCause.custom,
    );
  }

  void _updateChild() {
    _child.updateLocal(
      visible: _childVisible,
      active: _childActive,
      visibleFraction: _childFraction,
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
