import 'package:flutter/widgets.dart';

import 'navigator_lifecycle_controller.dart';

/// Navigator observer that forwards route changes into [controller].
class NavigatorLifecycleObserver extends NavigatorObserver {
  /// Creates an observer paired with [controller].
  NavigatorLifecycleObserver(this.controller);

  /// Controller receiving Navigator callbacks.
  final NavigatorLifecycleController controller;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    controller.handlePush(route, previousRoute);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    controller.handlePop(route, previousRoute);
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    controller.handleRemove(route, previousRoute);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    controller.handleReplace(newRoute: newRoute, oldRoute: oldRoute);
  }

  @override
  void didChangeTop(Route<dynamic> topRoute, Route<dynamic>? previousTopRoute) {
    controller.handleTopChanged(topRoute, previousTopRoute);
  }

  @override
  void didStartUserGesture(
    Route<dynamic> route,
    Route<dynamic>? previousRoute,
  ) {
    controller.handleGestureStarted(route, previousRoute);
  }

  @override
  void didStopUserGesture() {
    controller.handleGestureStopped();
  }
}
