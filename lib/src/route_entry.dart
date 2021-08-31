import 'package:flutter/widgets.dart';

import 'lifecycle_aware.dart';

class RouteEntry {
  RouteEntry(this.route);

  final Route<dynamic> route;

  final Set<LifecycleAware> lifecycleSubscribers = {};

  void emitEventsToSubscribers(List<LifecycleEvent> events) {
    lifecycleSubscribers.forEach((lifecycleAware) {
      emitEvents(lifecycleAware, events);
    });
  }

  void emitEvents(LifecycleAware lifecycleAware, List<LifecycleEvent> events) {
    lifecycleAware.handleLifecycleEvents(events);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RouteEntry &&
          runtimeType == other.runtimeType &&
          route == other.route;

  @override
  int get hashCode => route.hashCode;
}
