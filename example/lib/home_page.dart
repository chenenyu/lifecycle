import 'package:flutter/material.dart';
import 'package:lifecycle/lifecycle.dart';

import 'overlay_log.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State createState() {
    return _HomePageState();
  }
}

class _HomePageState extends State<HomePage>
    with LifecycleAware, LifecycleMixin {
  @override
  void onLifecycleEvent(LifecycleEvent event) {
    log.add('HomePage#${event.name}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Home Page',
        ),
      ),
      body: Center(
        child: Column(
          children: <Widget>[
            ElevatedButton(
              child: const Text('Open Sub1Page'),
              onPressed: () {
                Navigator.of(context).pushNamed('sub1');
              },
            ),
            ElevatedButton(
              child: const Text('Open Sub2Page'),
              onPressed: () {
                Navigator.of(context).pushNamed('sub2');
              },
            ),
            ElevatedButton(
              child: const Text('Open Dialog'),
              onPressed: () {
                showDialog(
                  context: context,
                  routeSettings: const RouteSettings(name: 'dialog'),
                  builder: (context) {
                    return LifecycleWrapper(
                      onLifecycleEvent: (event) {
                        log.add('Dialog#${event.name}');
                      },
                      child: AlertDialog(
                        content: const Text(
                          'This is a dialog.',
                        ),
                        actions: <Widget>[
                          TextButton(
                            child: const Text('Dismiss'),
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                          ),
                          TextButton(
                            child: const Text('Open Sub1Page'),
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
              child: const Text('Open MyPageView'),
              onPressed: () {
                Navigator.of(context).pushNamed('pageview');
              },
            ),
            ElevatedButton(
              child: const Text('Open MyTabView'),
              onPressed: () {
                Navigator.of(context).pushNamed('tabview');
              },
            ),
            ElevatedButton(
              child: const Text('Open NestedPageView'),
              onPressed: () {
                Navigator.of(context).pushNamed('nested');
              },
            ),
            ElevatedButton(
              child: const Text('Open Nav2.0'),
              onPressed: () {
                Navigator.of(context).pushNamed('nav2');
              },
            ),
            ElevatedButton(
              child: const Text('Open ListView page'),
              onPressed: () {
                Navigator.of(context).pushNamed('list');
              },
            ),
          ],
        ),
      ),
    );
  }
}
