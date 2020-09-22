import 'package:flutter/widgets.dart';

import 'lifecycle_aware.dart';

final LifecycleObserver defaultLifecycleObserver = LifecycleObserver();

class LifecycleObserver<R extends Route<dynamic>> extends NavigatorObserver
    with WidgetsBindingObserver {
  final List<Route> _routes = [];
  final Map<R, Set<LifecycleAware>> _listeners = <R, Set<LifecycleAware>>{};

  LifecycleObserver() {
    WidgetsBinding.instance.addObserver(this);
  }

  /// Subscribe [lifecycleAware] to be informed about changes to [route].
  ///
  /// Going forward, [lifecycleAware] will be informed about qualifying changes
  /// to [route], e.g. when [route] is covered by another route or when [route]
  /// is popped off the [Navigator] stack.
  void subscribe(LifecycleAware lifecycleAware, R route) {
    assert(lifecycleAware != null);
    assert(route != null);
    final Set<LifecycleAware> subscribers =
        _listeners.putIfAbsent(route, () => <LifecycleAware>{});
    if (subscribers.add(lifecycleAware)) {
      // print('LifecycleObserver#subscribe');
      lifecycleAware.onLifecycleEvent(LifecycleEvent.push);
    }
  }

  /// Unsubscribe [lifecycleAware].
  ///
  /// [lifecycleAware] is no longer informed about changes to its route. If the given argument was
  /// subscribed to multiple types, this will unregister it (once) from each type.
  void unsubscribe(LifecycleAware lifecycleAware) {
    // print('LifecycleObserver#unsubscribe');
    assert(lifecycleAware != null);
    for (final R route in _listeners.keys) {
      final Set<LifecycleAware> subscribers = _listeners[route];
      subscribers?.remove(lifecycleAware);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // print(state.toString());
    if (_routes.isEmpty || _listeners.isEmpty) return;
    switch (state) {
      case AppLifecycleState.resumed: // active
        // 最上面的 route 触发 active
        _sendEventToLastRoute(LifecycleEvent.active);
        if (_routes.last is! PageRoute) {
          // 上一个 PageRoute 触发 visible
          _sendEventToLastPageRoute(LifecycleEvent.visible);
        }
        break;
      case AppLifecycleState.inactive: // inactive
        // 最上面的 route 触发 inactive
        _sendEventToLastRoute(LifecycleEvent.inactive);
        break;
      case AppLifecycleState.paused: // invisible
        // 最上面的 route 触发 invisible
        _sendEventToLastRoute(LifecycleEvent.invisible);
        if (_routes.last is! PageRoute) {
          // 上一个 PageRoute 触发 invisible
          _sendEventToLastPageRoute(LifecycleEvent.invisible);
        }
        break;
      case AppLifecycleState.detached:
        break;
    }
  }

  /// 启动第一个页面时,previousRoute = null.
  @override
  void didPush(Route<dynamic> route, Route<dynamic> previousRoute) {
    super.didPush(route, previousRoute);
    // print('LifecycleObserver#didPush(route: ${route.settings.name}, '
    //     'previousRoute: ${previousRoute?.settings?.name})');

    if (previousRoute != null) {
      if (route is PageRoute) {
        // 上一个 route 触发 invisible
        _sendEventToRoute(previousRoute, LifecycleEvent.invisible);
        if (previousRoute is PopupRoute) {
          // 上个 PageRoute 触发 invisible
          _sendEventToLastPageRoute(LifecycleEvent.invisible);
        }
      } else if (route is PopupRoute) {
        // 上一个 route 触发 inactive
        _sendEventToRoute(previousRoute, LifecycleEvent.inactive);
      }
    }

    _routes.add(route);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic> previousRoute) {
    super.didPop(route, previousRoute);
    // print('LifecycleObserver#didPop(route: ${route.settings.name}, '
    //     'previousRoute: ${previousRoute.settings.name})');

    // 当前 route 触发 pop
    _sendEventToRoute(route, LifecycleEvent.pop);
    _routes.remove(route);

    if (previousRoute != null) {
      if (route is PageRoute) {
        // 上一个 Route 触发 active
        _sendEventToRoute(previousRoute, LifecycleEvent.active);
        if (previousRoute is PopupRoute) {
          // 上一个 PageRoute 触发 visible
          _sendEventToLastPageRoute(LifecycleEvent.visible);
        }
      } else if (route is PopupRoute) {
        // 上一个 Route 触发 active
        _sendEventToRoute(previousRoute, LifecycleEvent.active);
      }
    }
  }

  @override
  void didReplace({Route newRoute, Route oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    int index = _routes.indexOf(oldRoute);
    assert(index != -1);
    bool isLast = _routes.last == oldRoute;
    // print('LifecycleObserver#didReplace(newRoute: ${newRoute.settings.name}, '
    //     'oldRoute: ${oldRoute.settings.name}, isLast: $isLast)');

    _sendEventToRoute(oldRoute, LifecycleEvent.pop);
    _routes.remove(oldRoute);

    if (isLast) {
      if (oldRoute is PageRoute && newRoute is PopupRoute) {
        // 上一个PageRoute触发visible
        _sendEventToLastPageRoute(LifecycleEvent.visible);
      } else if (oldRoute is PopupRoute && newRoute is PageRoute) {
        // todo: 之前的PopupRoute是否触发invisible ？
        // 之前的PageRoute触发invisible
        _sendEventToLastPageRoute(LifecycleEvent.invisible);
      }
    }

    _routes.insert(index, newRoute);
  }

  /// [route] 被移除的route
  /// [previousRoute] 被移除route下面的route,移除多个route时,该参数值不变
  @override
  void didRemove(Route route, Route previousRoute) {
    super.didRemove(route, previousRoute);
    // print('LifecycleObserver#didRemove(route: ${route.settings.name}, '
    //     'previousRoute: ${previousRoute.settings.name})');

    _sendEventToRoute(route, LifecycleEvent.pop);
    if (previousRoute.isCurrent) {
      _sendEventToRoute(previousRoute, LifecycleEvent.active);
    }

    _routes.remove(route);
  }

  /// 发送 event 给指定的 route
  void _sendEventToRoute(Route route, LifecycleEvent event) {
    final Set<LifecycleAware> subscribers = _listeners[route];
    subscribers?.forEach((lifecycleAware) {
      lifecycleAware.onLifecycleEvent(event);
    });
  }

  /// 发送 event 给最后一个 route
  void _sendEventToLastRoute(LifecycleEvent event) {
    if (_routes.isEmpty) return;
    PageRoute route = _routes.last;
    if (route != null) {
      // 之前的 route 触发 invisible
      final Set<LifecycleAware> subscribers = _listeners[route];
      subscribers?.forEach((lifecycleAware) {
        lifecycleAware.onLifecycleEvent(event);
      });
    }
  }

  /// 发送 event 给最后一个 page route
  void _sendEventToLastPageRoute(LifecycleEvent event) {
    PageRoute lastPageRoute =
        _routes.lastWhere((r) => r is PageRoute, orElse: () => null);
    if (lastPageRoute != null) {
      // 之前的Route触发invisible
      final Set<LifecycleAware> lastPageSubscribers = _listeners[lastPageRoute];
      lastPageSubscribers?.forEach((lifecycleAware) {
        lifecycleAware.onLifecycleEvent(event);
      });
    }
  }
}
