import 'package:flutter/material.dart';
import 'package:lifecycle/lifecycle.dart';

import 'overlay_log.dart';

class Sub2Page extends StatelessWidget {
  const Sub2Page({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LifecycleWrapper(
      onLifecycleEvent: (event) {
        log.add('Sub2Page#${event.name}');
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
                  Route? sub1Route;
                  defaultLifecycleObserver.iterateRoutes((route) {
                    if (route.settings.name == 'sub1') {
                      sub1Route = route;
                      return true;
                    }
                    return false;
                  });
                  if (sub1Route != null) {
                    defaultLifecycleObserver.removeRoute(sub1Route!);
                  }
                },
                child: const Text("removeRoute('sub1')"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
