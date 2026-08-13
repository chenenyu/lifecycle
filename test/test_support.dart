import 'package:flutter/material.dart';
import 'package:lifecycle/lifecycle.dart';

class LifecycleEventLog {
  final Map<String, List<LifecycleEvent>> _events = {};
  final Map<String, List<LifecycleTransition>> _transitions = {};

  List<LifecycleEvent> operator [](String name) {
    return _events.putIfAbsent(name, () => []);
  }

  List<LifecycleTransition> transitions(String name) {
    return _transitions.putIfAbsent(name, () => []);
  }

  void add(String name, LifecycleEvent event) {
    this[name].add(event);
  }

  void addTransition(String name, LifecycleTransition transition) {
    transitions(name).add(transition);
  }

  void clear([String? name]) {
    if (name == null) {
      for (final events in _events.values) {
        events.clear();
      }
      for (final transitions in _transitions.values) {
        transitions.clear();
      }
    } else {
      this[name].clear();
      transitions(name).clear();
    }
  }
}

class LifecycleProbe extends StatelessWidget {
  const LifecycleProbe({
    super.key,
    required this.name,
    required this.log,
    this.child = const SizedBox.shrink(),
  });

  final String name;
  final LifecycleEventLog log;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LifecycleListener(
      onTransition: (transition) => log.addTransition(name, transition),
      onEvent: (event, _) => log.add(name, event),
      child: child,
    );
  }
}

Widget lifecycleTestApp({
  required Widget home,
  NavigatorLifecycleController? navigation,
  GlobalKey<NavigatorState>? navigatorKey,
}) {
  return LifecycleApp(
    child: MaterialApp(
      navigatorKey: navigatorKey,
      navigatorObservers: [if (navigation != null) navigation.observer],
      builder: navigation == null
          ? null
          : (context, child) =>
              NavigatorLifecycleScope(controller: navigation, child: child!),
      home: home,
    ),
  );
}

const createdAndActive = [
  LifecycleEvent.created,
  LifecycleEvent.appeared,
  LifecycleEvent.activated,
];

const hiddenFromActive = [
  LifecycleEvent.deactivated,
  LifecycleEvent.disappeared,
];

const disposedFromActive = [
  LifecycleEvent.deactivated,
  LifecycleEvent.disappeared,
  LifecycleEvent.disposed,
];
