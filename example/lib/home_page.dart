import 'package:flutter/material.dart';
import 'package:lifecycle/lifecycle.dart';

class HomePage extends StatefulWidget {
  HomePage({Key key}) : super(key: key);

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
    print('HomePage#${event.toString()}');
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
            RaisedButton(
              child: Text('Open Sub1Page'),
              onPressed: () {
                Navigator.of(context).pushNamed('sub1');
              },
            ),
            RaisedButton(
              child: Text('Open Sub2Page'),
              onPressed: () {
                Navigator.of(context).pushNamed('sub2');
              },
            ),
            RaisedButton(
              child: Text('Open Dialog'),
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
            ),
            RaisedButton(
              child: Text('Open MyPageView'),
              onPressed: () {
                Navigator.of(context).pushNamed('pageview');
              },
            ),
            RaisedButton(
              child: Text('Open MyTabView'),
              onPressed: () {
                Navigator.of(context).pushNamed('tabview');
              },
            ),
          ],
        ),
      ),
    );
  }
}
