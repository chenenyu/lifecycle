import 'package:flutter/material.dart';
import 'package:lifecycle/lifecycle.dart';

import 'overlay_log.dart';

class NestedPageView extends StatefulWidget {
  NestedPageView({Key key}) : super(key: key);

  _NestedPageViewState createState() => _NestedPageViewState();
}

class _NestedPageViewState extends State<NestedPageView> with SingleTickerProviderStateMixin {
  PageController _pageController;
  TabController _tabController;

  final List<Tab> myTabs = <Tab>[
    Tab(text: 'left'),
    Tab(text: 'right'),
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
        title: Text('NestedPageView'),
        bottom: TabBar(
          controller: _tabController,
          tabs: myTabs,
        ),
      ),
      body: ParentPageLifecycleWrapper(
        controller: _tabController,
        onLifecycleEvent: (event) {
          log.add('NestedPageView#${event.toString()}');
        },
        child: TabBarView(
          controller: _tabController,
          children: <Widget>[
            ChildPageLifecycleWrapper(
              index: 0,
              wantKeepAlive: true,
              onLifecycleEvent: (event) {
                log.add('OuterPage@0#${event.toString()}');
              },
              child: Center(
                child: Text(
                  'This is the first tab',
                  style: const TextStyle(fontSize: 20),
                ),
              ),
            ),
            ChildPageLifecycleWrapper(
              index: 1,
              wantKeepAlive: true,
              onLifecycleEvent: (event) {
                log.add('OuterPage@1#${event.toString()}');
              },
              child: ParentPageLifecycleWrapper(
                controller: _pageController,
                child: PageView(
                  controller: _pageController,
                  children: [
                    ChildPageLifecycleWrapper(
                      index: 0,
                      wantKeepAlive: false,
                      onLifecycleEvent: (event) {
                        log.add('InnerPage@0#${event.toString()}');
                      },
                      child: Container(
                        color: Colors.teal,
                        child: Center(
                          child: RaisedButton(
                            color: Colors.white,
                            onPressed: () {
                              if (_pageController.hasClients) {
                                _pageController.animateToPage(
                                  1,
                                  duration: const Duration(milliseconds: 400),
                                  curve: Curves.easeInOut,
                                );
                              }
                            },
                            child: Text('Next'),
                          ),
                        ),
                      ),
                    ),
                    ChildPageLifecycleWrapper(
                      index: 1,
                      wantKeepAlive: false,
                      onLifecycleEvent: (event) {
                        log.add('InnerPage@1#${event.toString()}');
                      },
                      child: Container(
                        color: Colors.blue,
                        child: Center(
                          child: RaisedButton(
                            color: Colors.white,
                            onPressed: () {
                              if (_pageController.hasClients) {
                                _pageController.animateToPage(
                                  0,
                                  duration: const Duration(milliseconds: 400),
                                  curve: Curves.easeInOut,
                                );
                              }
                            },
                            child: Text('Previous'),
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
