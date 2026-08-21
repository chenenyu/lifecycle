part of 'navigator_lifecycle_controller.dart';

class _NavigatorLifecycleObserver extends NavigatorObserver {
  _NavigatorLifecycleObserver(this.controller);

  final NavigatorLifecycleController controller;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    controller._handlePush(route, previousRoute);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    controller._handlePop(route, previousRoute);
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    controller._handleRemove(route, previousRoute);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    controller._handleReplace(newRoute: newRoute, oldRoute: oldRoute);
  }

  @override
  void didChangeTop(Route<dynamic> topRoute, Route<dynamic>? previousTopRoute) {
    controller._handleTopChanged(topRoute, previousTopRoute);
  }

  @override
  void didStartUserGesture(
    Route<dynamic> route,
    Route<dynamic>? previousRoute,
  ) {
    controller._handleGestureStarted(route, previousRoute);
  }

  @override
  void didStopUserGesture() {
    controller._handleGestureStopped();
  }
}
