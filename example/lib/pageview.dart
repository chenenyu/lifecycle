import 'package:flutter/material.dart';
import 'package:lifecycle/lifecycle.dart';

import 'overlay_log.dart';

class MyPageView extends StatefulWidget {
  MyPageView({Key? key}) : super(key: key);

  _MyPageViewState createState() => _MyPageViewState();
}

class _MyPageViewState extends State<MyPageView> {
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('MyPageView'),
      ),
      body: ParentPageLifecycleWrapper(
        controller: _pageController,
        onLifecycleEvent: (event) {
          log.add('MyPageView#${event.toString()}');
        },
        child: PageView(
          controller: _pageController,
          children: [
            ChildPageLifecycleWrapper(
              index: 0,
              wantKeepAlive: false,
              onLifecycleEvent: (event) {
                log.add('Page@0#${event.toString()}');
              },
              child: Container(
                color: Colors.teal,
                child: Center(
                  child: Column(
                    children: <Widget>[
                      ElevatedButton(
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
                      ElevatedButton(
                        onPressed: () {
                          showDialog(
                            context: context,
                            routeSettings: RouteSettings(name: 'dialog'),
                            builder: (context) {
                              return LifecycleWrapper(
                                onLifecycleEvent: (event) {
                                  log.add('Dialog#${event.toString()}');
                                },
                                child: AlertDialog(
                                  content: Text(
                                    'This is a dialog.',
                                  ),
                                  actions: <Widget>[
                                    TextButton(
                                      child: Text('Dismiss'),
                                      onPressed: () {
                                        Navigator.of(context).pop();
                                      },
                                    ),
                                    TextButton(
                                      child: Text('Open Sub1Page'),
                                      onPressed: () {
                                        Navigator.of(context).pushNamed('sub1');
                                      },
                                    ),
                                  ],
                                ),
                              );
                            },
                          );
                        },
                        child: Text('Open dialog'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            ChildPageLifecycleWrapper(
              index: 1,
              wantKeepAlive: false,
              onLifecycleEvent: (event) {
                log.add('Page@1#${event.toString()}');
              },
              child: Container(
                color: Colors.blue,
                child: Center(
                  child: Column(
                    children: <Widget>[
                      ElevatedButton(
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
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
