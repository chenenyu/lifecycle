/*
 * 演示 LifecycleTabBarView 的点击动画和手势切换。
 *
 * TabController 动画驱动可见比例，只有动画稳定后的选中 Tab 才 active；页面记录每个
 * index 的 Transition，用于对照快速点击、滑动与初始索引行为。
 */
import 'package:flutter/material.dart';
import 'package:lifecycle/lifecycle.dart';

import '../logging/demo_log.dart';
import '../widgets/demo_scaffold.dart';
import '../widgets/demo_widgets.dart';
import '../widgets/lifecycle_status_card.dart';

/// 展示 Tab 动画、手势与生命周期约束的页面。
class TabLifecycleScreen extends StatefulWidget {
  const TabLifecycleScreen({super.key, required this.log});

  final DemoLog log;

  @override
  State<TabLifecycleScreen> createState() => _TabLifecycleScreenState();
}

class _TabLifecycleScreenState extends State<TabLifecycleScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _controller = TabController(length: 3, vsync: this);

  @override
  Widget build(BuildContext context) {
    return DemoScaffold(
      title: 'Tab lifecycle',
      log: widget.log,
      bottom: TabBar(
        controller: _controller,
        tabs: const [
          Tab(text: 'FIRST'),
          Tab(text: 'SECOND'),
          Tab(text: 'THIRD'),
        ],
      ),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(12, 8, 12, 0),
            child: DemoInstructions(
              action: 'tap a tab or swipe horizontally between tabs.',
              expected:
                  'tabs remain visible but inactive during animation; only the settled selected tab activates.',
            ),
          ),
          Expanded(
            child: LifecycleTabBarView(
              controller: _controller,
              onTabTransition: (index, transition) =>
                  widget.log.record('tab $index', transition),
              children: const [
                _TabContent(index: 0),
                _TabContent(index: 1),
                _TabContent(index: 2),
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

/// 单个 Tab 的生命周期状态和说明内容。
class _TabContent extends StatelessWidget {
  const _TabContent({required this.index});

  final int index;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: LifecycleStatusCard(label: 'Tab $index'),
        ),
      ),
    );
  }
}
