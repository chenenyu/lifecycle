import 'package:flutter/material.dart';
import 'package:lifecycle/lifecycle.dart';

import 'overlay_log.dart';

class Sub2Page extends StatelessWidget {
  const Sub2Page({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LifecycleWrapper(
      onLifecycleEvent: (event) {
        log.add('Sub2Page#${event.toString()}');
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
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
                  Navigator.of(context).removeRoute(ModalRoute.of(context)!);
                },
                child: const Text("removeRoute(current)"),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context)
                      .removeRouteBelow(ModalRoute.of(context)!);
                },
                child: const Text("removeRouteBelow(current)"),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pushNamedAndRemoveUntil(
                      'sub1', ModalRoute.withName('/'));
                },
                child: const Text(
                    "pushNamedAndRemoveUntil('sub1', ModalRoute.withName('/'))"),
              ),
              ElevatedButton(
                onPressed: () {
                  defaultLifecycleObserver.removeNamed('sub1');
                },
                child: const Text("removeNamed('sub1')"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
