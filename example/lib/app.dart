import 'package:flutter/material.dart';
import 'package:lifecycle/lifecycle.dart';

import 'demo_routes.dart';
import 'logging/demo_log.dart';
import 'screens/controller_lab_screen.dart';
import 'screens/declarative_navigation_screen.dart';
import 'screens/details_screen.dart';
import 'screens/home_screen.dart';
import 'screens/nested_navigator_screen.dart';
import 'screens/page_lifecycle_screen.dart';
import 'screens/reorderable_pages_screen.dart';
import 'screens/tab_lifecycle_screen.dart';
import 'screens/viewport_lifecycle_screen.dart';

class LifecycleExampleApp extends StatefulWidget {
  const LifecycleExampleApp({super.key});

  @override
  State<LifecycleExampleApp> createState() => _LifecycleExampleAppState();
}

class _LifecycleExampleAppState extends State<LifecycleExampleApp> {
  final NavigatorLifecycleController _navigation = NavigatorLifecycleController(
    debugLabel: 'ExampleNavigator',
  );
  final DemoLog _log = DemoLog();

  @override
  Widget build(BuildContext context) {
    return LifecycleApp(
      child: MaterialApp(
        title: 'Lifecycle Demo',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
          useMaterial3: true,
        ),
        navigatorObservers: [_navigation.observer],
        builder: (context, child) => NavigatorLifecycleScope(
          controller: _navigation,
          child: child ?? const SizedBox.shrink(),
        ),
        routes: {
          DemoRoutes.details: (_) => DetailsScreen(log: _log),
          DemoRoutes.pages: (_) => PageLifecycleScreen(log: _log),
          DemoRoutes.reorderablePages: (_) => ReorderablePagesScreen(log: _log),
          DemoRoutes.tabs: (_) => TabLifecycleScreen(log: _log),
          DemoRoutes.viewport: (_) => ViewportLifecycleScreen(log: _log),
          DemoRoutes.nestedNavigator: (_) => NestedNavigatorScreen(log: _log),
          DemoRoutes.declarativeNavigator: (_) =>
              DeclarativeNavigationScreen(log: _log),
          DemoRoutes.controllerLab: (_) => const ControllerLabScreen(),
        },
        home: LifecycleHomeScreen(log: _log),
      ),
    );
  }

  @override
  void dispose() {
    _navigation.dispose();
    _log.dispose();
    super.dispose();
  }
}
