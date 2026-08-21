/*
 * NavigatorObserver 的私有适配层。
 *
 * 本文件不保存路由状态，只把 Flutter Navigator 的 push/pop/remove/replace、top
 * 变化和手势回调转交主 Controller；保持 Observer 无状态可避免同一事件在两处维护
 * 历史，并让公开 API 只暴露标准 NavigatorObserver 类型。
 */
part of 'navigator_lifecycle_controller.dart';

/// 将 Flutter 导航回调无状态转发给配对 Controller。
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
