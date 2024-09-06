import 'package:flutter/material.dart';
import 'package:lifecycle/lifecycle.dart';

import 'overlay_log.dart';

class NestedPageView extends StatefulWidget {
  const NestedPageView({super.key});

  @override
  State createState() => _NestedPageViewState();
}

class _NestedPageViewState extends State<NestedPageView>
    with SingleTickerProviderStateMixin {
  late PageController _pageController;
  late TabController _tabController;

  final List<Tab> myTabs = <Tab>[
    const Tab(text: 'left'),
    const Tab(text: 'right'),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _tabController = TabController(vsync: this, length: myTabs.length);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('NestedPageView'),
        bottom: TabBar(
          controller: _tabController,
          tabs: myTabs,
        ),
      ),
      body: PageViewLifecycleWrapper(
        // onLifecycleEvent: (event) {
        //   log.add('NestedPageView@Outer#${event.name}');
        // },
        child: TabBarView(
          controller: _tabController,
          children: <Widget>[
            ChildPageLifecycleWrapper(
              index: 0,
              onLifecycleEvent: (event) {
                log.add('OuterPage@0#${event.name}');
              },
              wantKeepAlive: true,
              child: const Center(
                child: Text(
                  'This is the first tab',
                  style: TextStyle(fontSize: 20),
                ),
              ),
            ),
            ChildPageLifecycleWrapper(
              index: 1,
              wantKeepAlive: true,
              onLifecycleEvent: (event) {
                log.add('OuterPage@1#${event.name}');
              },
              child: PageViewLifecycleWrapper(
                // onLifecycleEvent: (event) {
                //   log.add('NestedPageView@Inner#${event.name}');
                // },
                child: PageView(
                  controller: _pageController,
                  children: [
                    ChildPageLifecycleWrapper(
                      index: 0,
                      wantKeepAlive: true,
                      onLifecycleEvent: (event) {
                        log.add('InnerPage@0#${event.name}');
                      },
                      child: Container(
                        color: Colors.teal,
                        child: Center(
                          child: ElevatedButton(
                            onPressed: () {
                              if (_pageController.hasClients) {
                                _pageController.animateToPage(
                                  1,
                                  duration: const Duration(milliseconds: 400),
                                  curve: Curves.easeInOut,
                                );
                              }
                            },
                            child: const Text('Next'),
                          ),
                        ),
                      ),
                    ),
                    ChildPageLifecycleWrapper(
                      index: 1,
                      wantKeepAlive: true,
                      onLifecycleEvent: (event) {
                        log.add('InnerPage@1#${event.name}');
                      },
                      child: Container(
                        color: Colors.blue,
                        child: Center(
                          child: ElevatedButton(
                            onPressed: () {
                              if (_pageController.hasClients) {
                                _pageController.animateToPage(
                                  0,
                                  duration: const Duration(milliseconds: 400),
                                  curve: Curves.easeInOut,
                                );
                              }
                            },
                            child: const Text('Previous'),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
