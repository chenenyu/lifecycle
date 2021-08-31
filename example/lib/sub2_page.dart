import 'package:flutter/material.dart';
import 'package:lifecycle/lifecycle.dart';

import 'overlay_log.dart';

class Sub2Page extends StatelessWidget {
  Sub2Page({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LifecycleWrapper(
      onLifecycleEvent: (event) {
        log.add('Sub2Page#${event.toString()}');
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'Sub2Page',
          ),
        ),
        body: Center(
          child: Column(
            children: <Widget>[
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text("pop()"),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).removeRoute(ModalRoute.of(context)!);
                },
                child: Text("removeRoute(current)"),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context)
                      .removeRouteBelow(ModalRoute.of(context)!);
                },
                child: Text("removeRouteBelow(current)"),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pushNamedAndRemoveUntil(
                      'sub1', ModalRoute.withName('/'));
                },
                child: Text(
                    "pushNamedAndRemoveUntil('sub1', ModalRoute.withName('/'))"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
