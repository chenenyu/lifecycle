import 'package:flutter/material.dart';
import 'package:lifecycle/lifecycle.dart';

import 'overlay_log.dart';

class Sub1Page extends StatefulWidget {
  Sub1Page({Key key}) : super(key: key);

  @override
  _Sub1PageState createState() {
    return _Sub1PageState();
  }
}

class _Sub1PageState extends State<Sub1Page>
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
    log.add('Sub1Page#${event.toString()}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Sub1Page',
        ),
      ),
      body: Center(
        child: Column(
          children: <Widget>[
            RaisedButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text("pop()"),
            ),
            RaisedButton(
              onPressed: () {
                Navigator.of(context).popUntil(ModalRoute.withName('/'));
              },
              child: Text("popUntil('/')"),
            ),
            RaisedButton(
              onPressed: () {
                Navigator.of(context).pushNamed('sub2');
              },
              child: Text("push('sub2')"),
            ),
            RaisedButton(
              onPressed: () {
                Navigator.of(context).popAndPushNamed('sub2');
              },
              child: Text("popAndPushNamed('sub2')"),
            ),
            RaisedButton(
              onPressed: () {
                Navigator.of(context).pushReplacementNamed('sub2');
              },
              child: Text("pushReplacementNamed('sub2')"),
            ),
          ],
        ),
      ),
    );
  }
}
