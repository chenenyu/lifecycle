import 'package:flutter/material.dart';
import 'package:lifecycle/lifecycle.dart';

import 'home_page.dart';
import 'list_page.dart';
import 'nav2_home.dart';
import 'nested_pageview.dart';
import 'overlay_log.dart';
import 'pageview.dart';
import 'sub1_page.dart';
import 'sub2_page.dart';
import 'tabview.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

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
        'sub1': (_) => const Sub1Page(),
        'sub2': (_) => const Sub2Page(),
        'pageview': (_) => const MyPageView(),
        'tabview': (_) => const MyTabView(),
        'nested': (_) => const NestedPageView(),
        'nav2': (_) => const Nav2Home(),
        'list': (_) => const ListPage(),
      },
      home: Builder(
        builder: (context) {
          LogEntry.init(context);
          return const HomePage();
        },
      ),
    );
  }
}
