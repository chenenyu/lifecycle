import 'package:flutter/material.dart';
import 'package:lifecycle/lifecycle.dart';

import 'home_page.dart';
import 'sub1_page.dart';
import 'sub2_page.dart';

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
      navigatorObservers: [lifecycleObserver],
      routes: {
        '/': (_) => HomePage(),
        'sub1': (_) => Sub1Page(),
        'sub2': (_) => Sub2Page(),
      },
    );
  }
}
