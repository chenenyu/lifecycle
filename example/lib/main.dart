import 'package:flutter/material.dart';
import 'package:lifecycle/lifecycle.dart';

import 'home_page.dart';
import 'nav2_home.dart';
import 'nested_pageview.dart';
import 'overlay_log.dart';
import 'pageview.dart';
import 'sub1_page.dart';
import 'sub2_page.dart';
import 'tabview.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      navigatorObservers: [defaultLifecycleObserver],
      routes: {
        'sub1': (_) => Sub1Page(),
        'sub2': (_) => Sub2Page(),
        'pageview': (_) => MyPageView(),
        'tabview': (_) => MyTabView(),
        'nested': (_) => NestedPageView(),
        'nav2': (_) => Nav2Home(),
      },
      home: Builder(
        builder: (context) {
          LogEntry.init(context);
          return HomePage();
        },
      ),
    );
  }
}
