import 'package:flutter/material.dart';
import 'package:lifecycle/lifecycle.dart';

import 'overlay_log.dart';

class HomePage extends StatefulWidget {
  HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() {
    return _HomePageState();
  }
}

class _HomePageState extends State<HomePage>
    with LifecycleAware, LifecycleMixin {
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  void onLifecycleEvent(LifecycleEvent event) {
    log.add('HomePage#${event.toString()}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Home Page',
        ),
      ),
      body: Center(
        child: Column(
          children: <Widget>[
            ElevatedButton(
              child: Text('Open Sub1Page'),
              onPressed: () {
                Navigator.of(context).pushNamed('sub1');
              },
            ),
            ElevatedButton(
              child: Text('Open Sub2Page'),
              onPressed: () {
                Navigator.of(context).pushNamed('sub2');
              },
            ),
            ElevatedButton(
              child: Text('Open Dialog'),
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
            ),
            ElevatedButton(
              child: Text('Open MyPageView'),
              onPressed: () {
                Navigator.of(context).pushNamed('pageview');
              },
            ),
            ElevatedButton(
              child: Text('Open MyTabView'),
              onPressed: () {
                Navigator.of(context).pushNamed('tabview');
              },
            ),
            ElevatedButton(
              child: Text('Open NestedPageView'),
              onPressed: () {
                Navigator.of(context).pushNamed('nested');
              },
            ),
            ElevatedButton(
              child: Text('Open Nav2.0'),
              onPressed: () {
                Navigator.of(context).pushNamed('nav2');
              },
            ),
          ],
        ),
      ),
    );
  }
}
