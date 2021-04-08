import 'package:flutter/widgets.dart';

import 'lifecycle_aware.dart';
import 'log.dart';

/// An observer can only be used by one [Navigator] (include [MaterialApp]).
/// If you have your own [Navigator], please use a new instance of LifecycleObserver.
final LifecycleObserver defaultLifecycleObserver = LifecycleObserver();

class LifecycleObserver<R extends Route<dynamic>> extends NavigatorObserver
    with WidgetsBindingObserver {
  final List<Route> _routes = [];
  final Map<R, Set<LifecycleAware>> _lifecycleSubscribers = {};
  final Map<LifecycleAware, Set<LifecycleEvent>> _eventsFilters = {};

  static final List<LifecycleObserver> _cache = [];

  /// Avoid calling this constructor in [build] method.
  LifecycleObserver() {
    // clean cache
    _cache.removeWhere((e) {
      if (e.navigator == null) {
        WidgetsBinding.instance?.removeObserver(e);
        return true;
      }
      return false;
    });

    _cache.add(this);
    WidgetsBinding.instance?.addObserver(this);
  }

  /// Only for internal usage.
  factory LifecycleObserver.internalGet(BuildContext? context) {
    assert(context != null);
    NavigatorState navigator = Navigator.of(context!);
    for (LifecycleObserver observer in _cache) {
      if (observer.navigator == navigator) {
        return observer;
      }
    }
    throw Exception(
        'Can not get associated LifecycleObserver, did you forget to register it in MaterialApp or Navigator?');
  }

  /// Subscribe [lifecycleAware] to be informed about changes to [route].
  ///
  /// Going forward, [lifecycleAware] will be informed about qualifying changes
  /// to [route], e.g. when [route] is covered by another route or when [route]
  /// is popped off the [Navigator] stack.
  void subscribe(LifecycleAware lifecycleAware, R route,
      [Set<LifecycleEvent> events = lifecycle_events_all]) {
    assert(lifecycleAware != null);
    assert(route != null);
    final Set<LifecycleAware> subscribers =
        _lifecycleSubscribers.putIfAbsent(route, () => <LifecycleAware>{});
    if (subscribers.add(lifecycleAware)) {
      log('LifecycleObserver($hashCode)#subscribe (${lifecycleAware.hashCode})');
      Set<LifecycleEvent> subscribedEvents =
          _eventsFilters.putIfAbsent(lifecycleAware, () => events);
      if (subscribedEvents.contains(LifecycleEvent.push)) {
        lifecycleAware.onLifecycleEvent(LifecycleEvent.push);
      }
    }
  }

  /// Unsubscribe [lifecycleAware].
  ///
  /// [lifecycleAware] is no longer informed about changes to its route. If the given argument was
  /// subscribed to multiple types, this will unregister it (once) from each type.
  void unsubscribe(LifecycleAware lifecycleAware) {
    log('LifecycleObserver($hashCode)#unsubscribe (${lifecycleAware.hashCode})');
    assert(lifecycleAware != null);
    for (final R route in _lifecycleSubscribers.keys) {
      final Set<LifecycleAware>? subscribers = _lifecycleSubscribers[route];
      subscribers?.remove(lifecycleAware);
    }
    _eventsFilters.remove(lifecycleAware);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // log(state.toString());
    if (_routes.isEmpty || _lifecycleSubscribers.isEmpty) return;
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

  /// 启动第一个页面时, previousRoute = null.
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    log('LifecycleObserver($hashCode)#didPush('
        'route(${route.hashCode}): ${route.settings.name}, '
        'previousRoute(${previousRoute?.hashCode}): ${previousRoute?.settings.name})');

    if (previousRoute != null) {
      if (route is PageRoute) {
        // 上一个 route 触发 invisible
        _sendEventToGivenRoute(previousRoute, LifecycleEvent.invisible);
        if (previousRoute is PopupRoute) {
          // 上个 PageRoute 触发 invisible
          _sendEventToLastPageRoute(LifecycleEvent.invisible);
        }
      } else if (route is PopupRoute) {
        // 上一个 route 触发 inactive
        _sendEventToGivenRoute(previousRoute, LifecycleEvent.inactive);
      }
    }

    _routes.add(route);
  }

  @override
  void didPop(Route<dynamic>? route, Route<dynamic>? previousRoute) {
    if (route == null) return;
    super.didPop(route, previousRoute);
    log('LifecycleObserver($hashCode)#didPop('
        'route(${route.hashCode}): ${route.settings.name}, '
        'previousRoute(${previousRoute.hashCode}): ${previousRoute?.settings.name})');

    // 当前 route 触发 pop
    _sendEventToGivenRoute(route, LifecycleEvent.pop);
    _routes.remove(route);

    if (previousRoute != null) {
      if (route is PageRoute) {
        // 上一个 Route 触发 active
        _sendEventToGivenRoute(previousRoute, LifecycleEvent.active);
        if (previousRoute is PopupRoute) {
          // 上一个 PageRoute 触发 visible
          _sendEventToLastPageRoute(LifecycleEvent.visible);
        }
      } else if (route is PopupRoute) {
        // 上一个 Route 触发 active
        _sendEventToGivenRoute(previousRoute, LifecycleEvent.active);
      }
    }
  }

  @override
  void didReplace({Route? newRoute, Route? oldRoute}) {
    if (newRoute == null || oldRoute == null) return;
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    int index = _routes.indexOf(oldRoute);
    assert(index != -1);
    bool isLast = _routes.last == oldRoute;
    log('LifecycleObserver($hashCode)#didReplace('
        'newRoute: ${newRoute.settings.name}, '
        'oldRoute: ${oldRoute.settings.name}, isLast: $isLast)');

    _sendEventToGivenRoute(oldRoute, LifecycleEvent.pop);
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
  /// [previousRoute] 被移除route下面的route,移除多个route时,该参数值不变, 可能为null
  @override
  void didRemove(Route? route, Route? previousRoute) {
    if (route == null || previousRoute == null) return;
    super.didRemove(route, previousRoute);
    log('LifecycleObserver($hashCode)#didRemove('
        'route: ${route.settings.name}, '
        'previousRoute: ${previousRoute.settings.name})');

    _sendEventToGivenRoute(route, LifecycleEvent.pop);
    if (previousRoute.isCurrent) {
      _sendEventToGivenRoute(previousRoute, LifecycleEvent.active);
    }

    _routes.remove(route);
  }

  /// 发送 event 给指定的 route
  void _sendEventToGivenRoute(Route route, LifecycleEvent event) {
    final Set<LifecycleAware>? subscribers = _lifecycleSubscribers[route];
    subscribers?.forEach((lifecycleAware) {
      Set<LifecycleEvent>? subscribedEvents = _eventsFilters[lifecycleAware];
      if (subscribedEvents?.contains(event) == true) {
        lifecycleAware.onLifecycleEvent(event);
      }
    });
  }

  /// 发送 event 给最后一个 route
  void _sendEventToLastRoute(LifecycleEvent event) {
    if (_routes.isEmpty) return;
    Route route = _routes.last;
    _sendEventToGivenRoute(route, event);
  }

  /// 发送 event 给最后一个 page route
  void _sendEventToLastPageRoute(LifecycleEvent event) {
    Route? lastPageRoute =
        _routes.lastWhere((r) => r is PageRoute);
    if (lastPageRoute != null) {
      // 之前的 route 触发 invisible
      _sendEventToGivenRoute(lastPageRoute, event);
    }
  }
}
