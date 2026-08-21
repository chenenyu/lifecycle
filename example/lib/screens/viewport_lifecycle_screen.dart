/*
 * ViewportLifecycleItem 的交互实验页。
 *
 * Grid 同时展示可见阈值、活跃阈值、滚动激活策略和批量日志；默认 settle 后激活，可用
 * 开关恢复 immediate 行为。只记录少量 item 可避免日志本身干扰快速滚动性能观察。
 */
import 'package:flutter/material.dart';
import 'package:lifecycle/lifecycle.dart';

import '../logging/demo_log.dart';
import '../widgets/demo_scaffold.dart';
import '../widgets/demo_widgets.dart';
import '../widgets/lifecycle_status_card.dart';

/// 可动态调整阈值和激活策略的 Grid 视口实验页。
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
  bool _activateWhileScrolling = false;
  bool _recordEveryItem = false;

  @override
  Widget build(BuildContext context) {
    return DemoScaffold(
      title: 'Viewport lifecycle',
      log: widget.log,
      body: LayoutBuilder(
        builder: (context, constraints) => Column(
          children: [
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: constraints.maxHeight * 0.6,
              ),
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                  child: Column(
                    children: [
                      const DemoInstructions(
                        action:
                            'scroll or fling until an item is partly clipped, then let the grid settle.',
                        expected:
                            'visible follows its area threshold; active also waits for scrolling to settle unless immediate activation is enabled.',
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
                        title: const Text('Activate while scrolling'),
                        subtitle: const Text(
                          'Off keeps visible items inactive until scrolling settles.',
                        ),
                        value: _activateWhileScrolling,
                        onChanged: (value) =>
                            setState(() => _activateWhileScrolling = value),
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
                  activationPolicy: _activateWhileScrolling
                      ? ViewportLifecycleActivationPolicy.immediate
                      : ViewportLifecycleActivationPolicy.whenScrollSettles,
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
      ),
    );
  }
}
