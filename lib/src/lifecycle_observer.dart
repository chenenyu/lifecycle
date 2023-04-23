import 'package:flutter/widgets.dart';

import 'lifecycle_aware.dart';
import 'route_entry.dart';

/// An observer can only be used by one [Navigator] (include [MaterialApp]).
/// If you have your own [Navigator], please use a new instance of [LifecycleObserver].
///
/// 一个observer只能被一个[Navigator]（包括[MaterialApp]）使用。
/// 如果你使用了多个[Navigator]，请使用新的[LifecycleObserver]实例。
final LifecycleObserver defaultLifecycleObserver = LifecycleObserver();

class LifecycleObserver extends NavigatorObserver with WidgetsBindingObserver {
  final List<RouteEntry> _history = [];

  static final List<LifecycleObserver> _cache = [];

  /// Avoids calling this constructor in [build] method.
  /// Call [dispose] when it will never be used, e.g. call it in State#dispose.
  ///
  /// 避免在[build]方法里调用该构造方法。记得在[State#build]里调用[dispose]销毁实例。
  LifecycleObserver() {
    _cache.add(this);
    WidgetsBinding.instance.addObserver(this);
  }

  /// Only for internal usage.
  ///
  /// 仅内部使用。
  @protected
  factory LifecycleObserver.internalGet(BuildContext context) {
    NavigatorState navigator = Navigator.of(context);
    for (int i = _cache.length - 1; i >= 0; i--) {
      LifecycleObserver observer = _cache[i];
      if (observer.navigator == navigator) {
        return observer;
      }
    }
    throw Exception(
        'Can not get associated LifecycleObserver, did you forget to register it in MaterialApp or Navigator?');
  }

  /// Must be called when the observer will no longer be used.
  @mustCallSuper
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cache.remove(this);
  }

  /// [lifecycleAware] subscribes events.
  ///
  /// [route]有变化时，通知[lifecycleAware]。
  void subscribe(LifecycleAware lifecycleAware, Route route) {
    RouteEntry entry = _getRouteEntry(route);
    if (entry.lifecycleSubscribers.add(lifecycleAware)) {
      // print('LifecycleObserver($hashCode)#subscribe(${lifecycleAware.toString()})');
      entry.emitEvents(lifecycleAware, lifecycleEventsVisibleAndActive);
    }
  }

  /// [lifecycleAware] unsubscribes events.
  ///
  /// [lifecycleAware]取消订阅事件。
  void unsubscribe(LifecycleAware lifecycleAware) {
    // print('LifecycleObserver($hashCode)#unsubscribe(${lifecycleAware.toString()})');
    for (final RouteEntry entry in _history) {
      entry.lifecycleSubscribers.remove(lifecycleAware);
    }
  }

  RouteEntry _getRouteEntry(Route route) {
    return _history.firstWhere((e) => e.route == route);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // print(state);
    if (_history.isEmpty) return;
    switch (state) {
      case AppLifecycleState.resumed: // active
        // Top route trigger active
        //
        // 最上面的route触发active
        _sendEventsToLastRoute(lifecycleEventsVisibleAndActive);
        if (_history.last.route is! PageRoute) {
          // Previous PageRoute trigger visible
          //
          // 前一个PageRoute触发visible
          _sendEventsToLastPageRoute([LifecycleEvent.visible]);
        }
        break;
      case AppLifecycleState.inactive: // inactive
        // Top route trigger inactive
        //
        // 最上面的route触发inactive
        _sendEventsToLastRoute([LifecycleEvent.inactive]);
        break;
      case AppLifecycleState.paused: // invisible
        // Top route trigger invisible
        //
        // 最上面的route触发invisible
        _sendEventsToLastRoute([LifecycleEvent.invisible]);
        if (_history.last.route is! PageRoute) {
          // Previous PageRoute trigger invisible
          //
          // 前一个PageRoute触发invisible
          _sendEventsToLastPageRoute([LifecycleEvent.invisible]);
        }
        break;
      case AppLifecycleState.detached:
        break;
    }
  }

  /// When boot first page, [previousRoute] is null.
  ///
  /// 启动第一个页面时，[previousRoute]为null。
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    // print('LifecycleObserver($hashCode)#didPush('
    //     'route(${route.hashCode}): ${route.settings.name}, '
    //     'previousRoute(${previousRoute?.hashCode}): ${previousRoute?.settings.name})');

    if (previousRoute != null) {
      try {
        RouteEntry previousEntry = _getRouteEntry(previousRoute);
        if (route is PageRoute) {
          // previousRoute trigger invisible
          //
          // previousRoute触发invisible
          _sendEventsToGivenRoute(
              previousEntry, lifecycleEventsInactiveAndInvisible);
          if (previousRoute is PopupRoute) {
            // Previous PageRoute trigger invisible
            //
            // 前一个PageRoute触发invisible
            _sendEventsToLastPageRoute([LifecycleEvent.invisible]);
          }
        } else if (route is PopupRoute) {
          // Previous route trigger inactive
          //
          // previousRoute触发inactive
          _sendEventsToGivenRoute(previousEntry, [LifecycleEvent.inactive]);
        }
      } catch (e) {
        // print(e);
      }
    }

    // 新push进来的route添加进history
    _history.add(RouteEntry(route));
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    // print('LifecycleObserver($hashCode)#didPop('
    //     'route(${route.hashCode}): ${route.settings.name}, '
    //     'previousRoute(${previousRoute.hashCode}): ${previousRoute?.settings.name})');

    RouteEntry entry = _getRouteEntry(route);
    // Current route trigger pop
    //
    // 当前route触发pop
    _sendEventsToGivenRoute(entry, lifecycleEventsInactiveAndInvisible);
    _history.remove(entry);

    if (previousRoute != null) {
      RouteEntry previousEntry = _getRouteEntry(previousRoute);
      if (route is PageRoute) {
        // Previous Route trigger active
        //
        // 如果pop掉的route是PageRoute，则previousRoute触发active
        _sendEventsToGivenRoute(previousEntry, lifecycleEventsVisibleAndActive);
        if (previousRoute is PopupRoute) {
          // Previous PageRoute trigger visible
          //
          // 如果previousRoute是PopupRoute，则前一个PageRoute触发visible
          _sendEventsToLastPageRoute([LifecycleEvent.visible]);
        }
      } else if (route is PopupRoute) {
        // Previous Route trigger active
        //
        // 如果如果pop掉的route是PopupRoute,则previousEntry触发active
        _sendEventsToGivenRoute(previousEntry, [LifecycleEvent.active]);
      }
    }
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    if (newRoute == null || oldRoute == null) return;

    RouteEntry oldEntry = _getRouteEntry(oldRoute);
    RouteEntry newEntry = RouteEntry(newRoute);
    int index = _history.indexOf(oldEntry);
    assert(index != -1);
    bool isLast = _history.last == oldEntry; // 被replace的是否是最上层的route
    // print('LifecycleObserver($hashCode)#didReplace('
    //     'newRoute: ${newRoute.settings.name}, '
    //     'oldRoute: ${oldRoute.settings.name}, isLast: $isLast)');

    // 被replace的oldRoute触发invisible
    _sendEventsToGivenRoute(oldEntry, lifecycleEventsInactiveAndInvisible);
    _history.remove(oldEntry);

    if (isLast) {
      // 用PopupRoute替换PageRoute
      if (oldRoute is PageRoute && newRoute is PopupRoute) {
        // Previous PageRoute trigger visible
        //
        // 前一个PageRoute触发visible
        _sendEventsToLastPageRoute([LifecycleEvent.visible]);
      }
      // 用PageRoute替换PopupRoute
      else if (oldRoute is PopupRoute && newRoute is PageRoute) {
        // todo: Previous PopupRoute trigger invisible ？
        // Previous PageRoute trigger invisible
        //
        // 前一个PageRoute触发invisible
        _sendEventsToLastPageRoute(lifecycleEventsInactiveAndInvisible);
      }
    }

    _history.insert(index, newEntry);
  }

  /// [route] Route that will be removed.
  /// [previousRoute] A route below the removed route. When removing
  /// multiple routes, the [previousRoute] is unchanged, and may be null.
  ///
  /// [route] 被移除的route
  /// [previousRoute] 被移除的route下面的route。当移除多个route时，该route不变，并且可能为null。
  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didRemove(route, previousRoute);
    // print('LifecycleObserver($hashCode)#didRemove('
    //     'route: ${route.settings.name}, '
    //     'previousRoute: ${previousRoute?.settings.name})');

    RouteEntry entry = _getRouteEntry(route);
    // 被移除的route触发invisible
    _sendEventsToGivenRoute(entry, lifecycleEventsInactiveAndInvisible);
    if (previousRoute?.isCurrent ?? false) {
      // previousRoute成为上层route时，触发active
      RouteEntry previousEntry = _getRouteEntry(previousRoute!);
      _sendEventsToGivenRoute(previousEntry, lifecycleEventsVisibleAndActive);
    }

    _history.remove(entry);
  }

  /// Send [events] to special [entry].
  void _sendEventsToGivenRoute(RouteEntry entry, List<LifecycleEvent> events) {
    entry.emitEventsToSubscribers(events);
  }

  /// Send [events] to last route.
  void _sendEventsToLastRoute(List<LifecycleEvent> events) {
    if (_history.isEmpty) return;
    RouteEntry entry = _history.last;
    _sendEventsToGivenRoute(entry, events);
  }

  /// Send [events] to last [PageRoute].
  void _sendEventsToLastPageRoute(List<LifecycleEvent> events) {
    try {
      RouteEntry entry = _history.lastWhere((r) => r.route is PageRoute);
      _sendEventsToGivenRoute(entry, events);
    } catch (e) {
      // IterableElementError.noElement()
      // print(e);
      rethrow;
    }
  }

  /// Finds route by [routeName].
  @Deprecated('Use iterateRoutes() instead.')
  Route<dynamic>? findRoute(String routeName) {
    try {
      Route route =
          _history.firstWhere((r) => r.route.settings.name == routeName).route;
      return route;
    } catch (_) {
      return null;
    }
  }

  /// Remove a route according to the [routeName].
  @Deprecated('Use removeRoute() instead.')
  void removeNamed<T>(String routeName, [T? result]) {
    Route? route = findRoute(routeName);
    if (route != null) {
      route.didPop(result);
      navigator?.removeRoute(route);
    }
  }

  /// Iterates routes. It's usually used for locating a specific route.
  /// [callback] The callback function to be called for each route.
  ///            Returns true to break the iteration.
  void iterateRoutes(bool Function(Route<dynamic> route) callback) {
    for (var route in _history) {
      if (callback(route.route)) {
        break;
      }
    }
  }

  /// Removes a route.
  void removeRoute<T>(Route route, [T? result]) {
    if (result != null) {
      route.didPop(result);
    }
    navigator?.removeRoute(route);
  }
}
