import 'package:flutter/material.dart';
import 'package:lifecycle/lifecycle.dart';

import '../logging/demo_log.dart';
import '../widgets/demo_scaffold.dart';
import '../widgets/demo_widgets.dart';
import '../widgets/lifecycle_status_card.dart';

class ViewportLifecycleScreen extends StatefulWidget {
  const ViewportLifecycleScreen({super.key, required this.log});

  final DemoLog log;

  @override
  State<ViewportLifecycleScreen> createState() =>
      _ViewportLifecycleScreenState();
}

class _ViewportLifecycleScreenState extends State<ViewportLifecycleScreen> {
  double _visibleThreshold = 0.2;
  double _activeThreshold = 0.8;
  bool _recordEveryItem = false;

  @override
  Widget build(BuildContext context) {
    return DemoScaffold(
      title: 'Viewport lifecycle',
      log: widget.log,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            child: Column(
              children: [
                const DemoInstructions(
                  action: 'scroll slowly until an item is partly clipped.',
                  expected:
                      'visible and active change independently when the two-dimensional area crosses each threshold.',
                ),
                Row(
                  children: [
                    const SizedBox(width: 88, child: Text('Visible')),
                    Expanded(
                      child: Slider(
                        key: const ValueKey('visible-threshold-slider'),
                        value: _visibleThreshold,
                        max: 0.9,
                        divisions: 9,
                        label: _visibleThreshold.toStringAsFixed(1),
                        onChanged: (value) => setState(() {
                          _visibleThreshold = value;
                          if (_activeThreshold < value) {
                            _activeThreshold = value;
                          }
                        }),
                      ),
                    ),
                    Text(_visibleThreshold.toStringAsFixed(1)),
                  ],
                ),
                Row(
                  children: [
                    const SizedBox(width: 88, child: Text('Active')),
                    Expanded(
                      child: Slider(
                        key: const ValueKey('active-threshold-slider'),
                        value: _activeThreshold,
                        min: _visibleThreshold,
                        divisions: ((1 - _visibleThreshold) * 10).round(),
                        label: _activeThreshold.toStringAsFixed(1),
                        onChanged: (value) =>
                            setState(() => _activeThreshold = value),
                      ),
                    ),
                    Text(_activeThreshold.toStringAsFixed(1)),
                  ],
                ),
                SwitchListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Record every grid item'),
                  subtitle: const Text(
                    'Off records only items 0–3 to reduce noise.',
                  ),
                  value: _recordEveryItem,
                  onChanged: (value) =>
                      setState(() => _recordEveryItem = value),
                ),
              ],
            ),
          ),
          Expanded(
            child: GridView.builder(
              key: const ValueKey('viewport-grid'),
              padding: const EdgeInsets.all(12),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 240,
                mainAxisExtent: 130,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: 30,
              itemBuilder: (context, index) => ViewportLifecycleItem(
                visibleThreshold: _visibleThreshold,
                activeThreshold: _activeThreshold,
                onTransition: _recordEveryItem || index < 4
                    ? (transition) =>
                          widget.log.record('grid item $index', transition)
                    : null,
                child: index == 0
                    ? const LifecycleStatusCard(
                        label: 'Grid item 0',
                        compact: true,
                      )
                    : Card(child: Center(child: Text('Item $index'))),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
