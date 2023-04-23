import 'package:flutter/material.dart';
import 'package:lifecycle/lifecycle.dart';

import 'overlay_log.dart';

class MyTabView extends StatefulWidget {
  const MyTabView({Key? key}) : super(key: key);

  @override
  State createState() => _MyTabViewState();
}

class _MyTabViewState extends State<MyTabView>
    with SingleTickerProviderStateMixin {
  final List<Tab> myTabs = <Tab>[
    const Tab(text: 'LEFT'),
    const Tab(text: 'RIGHT'),
  ];

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(vsync: this, length: myTabs.length);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MyTabView'),
        bottom: TabBar(
          controller: _tabController,
          tabs: myTabs,
        ),
      ),
      body: PageViewLifecycleWrapper(
        // onLifecycleEvent: (event) {
        //   log.add('MyTabView#${event.toString()}');
        // },
        child: TabBarView(
          controller: _tabController,
          children: myTabs.map((Tab tab) {
            final String label = tab.text!.toLowerCase();
            final int index = myTabs.indexOf(tab);
            return ChildPageLifecycleWrapper(
              index: index,
              wantKeepAlive: true,
              onLifecycleEvent: (event) {
                log.add('Page@$index#${event.toString()}');
              },
              child: Center(
                child: Text(
                  'This is the $label tab',
                  style: const TextStyle(fontSize: 36),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
