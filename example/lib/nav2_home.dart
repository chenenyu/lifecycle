import 'package:flutter/material.dart';
import 'package:lifecycle/lifecycle.dart';

import 'nav2_page1.dart';
import 'nav2_page2.dart';
import 'overlay_log.dart';

class Nav2Home extends StatefulWidget {
  const Nav2Home({Key? key}) : super(key: key);

  @override
  State createState() {
    return _Nav2HomeState();
  }
}

class _Nav2HomeState extends State<Nav2Home>
    with LifecycleAware, LifecycleMixin {
  final LifecycleObserver lifecycleObserver = LifecycleObserver();

  bool _showPage1 = true; // ignore: prefer_final_fields
  bool _showPage2 = false;

  @override
  void dispose() {
    lifecycleObserver.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Navigator(
      observers: [lifecycleObserver],
      pages: [
        if (_showPage1)
          MaterialPage(
            name: 'nav2/page1',
            child: Nav2Page1(
              onShowPage2: () {
                setState(() {
                  _showPage2 = true;
                });
              },
            ),
          ),
        if (_showPage2)
          MaterialPage(
            name: 'nav2/page2',
            child: Nav2Page2(
              onHidePage2: () {
                setState(() {
                  _showPage2 = false;
                });
              },
            ),
          ),
      ],
      onPopPage: (route, result) {
        if (!route.didPop(result)) {
          return false;
        }
        // if (route.settings.name == 'nav2/page2') {
        //   setState(() {
        //     _showPage2 = false;
        //   });
        // }
        return true;
      },
    );
  }

  @override
  void onLifecycleEvent(LifecycleEvent event) {
    log.add('Nav2Home#${event.name}');
  }
}
