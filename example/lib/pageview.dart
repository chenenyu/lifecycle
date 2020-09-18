import 'package:flutter/material.dart';
import 'package:lifecycle/lifecycle.dart';

class MyPageView extends StatefulWidget {
  MyPageView({Key key}) : super(key: key);

  _MyPageViewState createState() => _MyPageViewState();
}

class _MyPageViewState extends State<MyPageView> {
  PageController _pageController;

  // @override
  // bool get wantKeepAlive => true;

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
      body: PageViewLifecycleWrapper(
        controller: _pageController,
        onLifecycleEvent: (event) {
          print('MyPageView#${event.toString()}');
        },
        child: PageView(
          controller: _pageController,
          children: [
            PageLifecycleWrapper(
              index: 0,
              wantKeepAlive: true,
              onLifecycleEvent: (event) {
                print('Page@0#${event.toString()}');
              },
              child: Container(
                color: Colors.teal,
                child: Center(
                  child: Column(
                    children: <Widget>[
                      RaisedButton(
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
                      RaisedButton(
                        color: Colors.white,
                        onPressed: () {
                          showDialog(
                            context: context,
                            routeSettings: RouteSettings(name: 'dialog'),
                            builder: (context) {
                              return LifecycleWrapper(
                                onLifecycleEvent: (event) {
                                  print('Dialog#${event.toString()}');
                                },
                                child: AlertDialog(
                                  content: Text(
                                    'This is a dialog.',
                                  ),
                                  actions: <Widget>[
                                    FlatButton(
                                      child: Text('Dismiss'),
                                      onPressed: () {
                                        Navigator.of(context).pop();
                                      },
                                    ),
                                    FlatButton(
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
            PageLifecycleWrapper(
              index: 1,
              wantKeepAlive: true,
              onLifecycleEvent: (event) {
                print('Page@1#${event.toString()}');
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
    );
  }
}
