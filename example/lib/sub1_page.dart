import 'package:flutter/material.dart';
import 'package:lifecycle/lifecycle.dart';

import 'overlay_log.dart';

class Sub1Page extends StatefulWidget {
  const Sub1Page({Key? key}) : super(key: key);

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
        title: const Text(
          'Sub1Page',
        ),
      ),
      body: Center(
        child: Column(
          children: <Widget>[
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text("pop()"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).popUntil(ModalRoute.withName('/'));
              },
              child: const Text("popUntil('/')"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pushNamed('sub2');
              },
              child: const Text("push('sub2')"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).popAndPushNamed('sub2');
              },
              child: const Text("popAndPushNamed('sub2')"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pushReplacementNamed('sub2');
              },
              child: const Text("pushReplacementNamed('sub2')"),
            ),
          ],
        ),
      ),
    );
  }
}
