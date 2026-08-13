import 'package:flutter/material.dart';
import 'package:lifecycle/lifecycle.dart';

import '../logging/demo_log.dart';
import '../widgets/demo_scaffold.dart';
import '../widgets/demo_widgets.dart';
import '../widgets/lifecycle_status_card.dart';

class PageLifecycleScreen extends StatefulWidget {
  const PageLifecycleScreen({super.key, required this.log});

  final DemoLog log;

  @override
  State<PageLifecycleScreen> createState() => _PageLifecycleScreenState();
}

class _PageLifecycleScreenState extends State<PageLifecycleScreen> {
  final PageController _controller = PageController();

  @override
  Widget build(BuildContext context) {
    return DemoScaffold(
      title: 'Page lifecycle',
      log: widget.log,
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(12, 8, 12, 0),
            child: DemoInstructions(
              action: 'drag slowly between the two pages, then release.',
              expected:
                  'both pages are visible with fractional exposure while dragging; only the settled page becomes active.',
            ),
          ),
          Expanded(
            child: LifecyclePageView(
              controller: _controller,
              onPageTransition: (index, transition) =>
                  widget.log.record('page $index', transition),
              children: [
                _KeepAlivePage(
                  child: ListView.builder(
                    key: const ValueKey('page-zero-list'),
                    padding: const EdgeInsets.all(8),
                    itemCount: 12,
                    itemBuilder: (context, index) => SizedBox(
                      height: index == 0 ? 150 : 96,
                      child: ViewportLifecycleItem(
                        visibleThreshold: 0.25,
                        activeThreshold: 0.75,
                        onTransition: (transition) =>
                            widget.log.record('page 0 item $index', transition),
                        child: index == 0
                            ? const LifecycleStatusCard(
                                label: 'Page 0 / item 0',
                                compact: true,
                              )
                            : Card(
                                child: Center(
                                  child: Text('Viewport item $index'),
                                ),
                              ),
                      ),
                    ),
                  ),
                ),
                ColoredBox(
                  color: Theme.of(context).colorScheme.secondaryContainer,
                  child: const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: LifecycleStatusCard(label: 'Page 1'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

class _KeepAlivePage extends StatefulWidget {
  const _KeepAlivePage({required this.child});

  final Widget child;

  @override
  State<_KeepAlivePage> createState() => _KeepAlivePageState();
}

class _KeepAlivePageState extends State<_KeepAlivePage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}
