import 'package:flutter/material.dart';
import 'package:lifecycle/lifecycle.dart';

class MyTabView extends StatefulWidget {
  const MyTabView({Key key}) : super(key: key);

  @override
  _MyTabViewState createState() => _MyTabViewState();
}

class _MyTabViewState extends State<MyTabView>
    with SingleTickerProviderStateMixin {
  final List<Tab> myTabs = <Tab>[
    Tab(text: 'LEFT'),
    Tab(text: 'RIGHT'),
  ];

  TabController _tabController;

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
        title: Text('MyTabView'),
        bottom: TabBar(
          controller: _tabController,
          tabs: myTabs,
        ),
      ),
      body: PageViewLifecycleWrapper(
        controller: _tabController,
        onLifecycleEvent: (event) {
          print('MyTabView#${event.toString()}');
        },
        child: TabBarView(
          controller: _tabController,
          children: myTabs.map((Tab tab) {
            final String label = tab.text.toLowerCase();
            final int index = myTabs.indexOf(tab);
            return PageLifecycleWrapper(
              index: index,
              wantKeepAlive: true,
              onLifecycleEvent: (event) {
                print('Page@$index#${event.toString()}');
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
