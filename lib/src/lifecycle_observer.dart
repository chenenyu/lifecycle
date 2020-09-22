import 'package:flutter/widgets.dart';

import 'lifecycle_aware.dart';

final LifecycleObserver defaultLifecycleObserver = LifecycleObserver();

class LifecycleObserver<R extends Route<dynamic>> extends NavigatorObserver {
  final List<Route> _routes = [];
  final Map<R, Set<LifecycleAware>> _listeners = <R, Set<LifecycleAware>>{};

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

  /// 启动第一个页面时,previousRoute = null.
  @override
  void didPush(Route<dynamic> route, Route<dynamic> previousRoute) {
    super.didPush(route, previousRoute);
    print('LifecycleObserver#didPush(route: ${route.settings.name}, '
        'previousRoute: ${previousRoute?.settings?.name})');

    if (previousRoute != null) {
      if (route is PageRoute) {
        final Set<LifecycleAware> previousSubscribers =
            _listeners[previousRoute];
        previousSubscribers?.forEach((lifecycleAware) {
          lifecycleAware.onLifecycleEvent(LifecycleEvent.invisible);
        });

        if (previousRoute is PopupRoute) {
          Route lastPageRoute =
              _routes.lastWhere((r) => r is PageRoute, orElse: () => null);
          if (lastPageRoute != null) {
            final Set<LifecycleAware> previousPageSubscribers =
                _listeners[lastPageRoute];
            previousPageSubscribers?.forEach((lifecycleAware) {
              lifecycleAware.onLifecycleEvent(LifecycleEvent.invisible);
            });
          }
        }
      } else if (route is PopupRoute) {
        final Set<LifecycleAware> previousSubscribers =
            _listeners[previousRoute];
        previousSubscribers?.forEach((lifecycleAware) {
          lifecycleAware.onLifecycleEvent(LifecycleEvent.pause);
        });
      }
    }

    _routes.add(route);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic> previousRoute) {
    super.didPop(route, previousRoute);
    print('LifecycleObserver#didPop(route: ${route.settings.name}, '
        'previousRoute: ${previousRoute.settings.name})');

    final Set<LifecycleAware> subscribers = _listeners[route];
    subscribers?.forEach((lifecycleAware) {
      lifecycleAware.onLifecycleEvent(LifecycleEvent.pop);
    });
    _routes.remove(route);

    if (previousRoute != null) {
      if (route is PageRoute) {
        // 上一个 Route 触发 resume
        final Set<LifecycleAware> previousSubscribers =
            _listeners[previousRoute];
        previousSubscribers?.forEach((lifecycleAware) {
          lifecycleAware.onLifecycleEvent(LifecycleEvent.resume);
        });

        if (previousRoute is PopupRoute) {
          Route lastPageRoute =
              _routes.lastWhere((r) => r is PageRoute, orElse: () => null);
          // 上一个 PageRoute 触发 visible
          if (lastPageRoute != null) {
            final Set<LifecycleAware> previousPageSubscribers =
                _listeners[lastPageRoute];
            previousPageSubscribers?.forEach((lifecycleAware) {
              lifecycleAware.onLifecycleEvent(LifecycleEvent.visible);
            });
          }
        }
      } else if (route is PopupRoute) {
        // 上一个 Route 触发 resume
        final Set<LifecycleAware> previousSubscribers =
            _listeners[previousRoute];
        previousSubscribers?.forEach((lifecycleAware) {
          lifecycleAware.onLifecycleEvent(LifecycleEvent.resume);
        });
      }
    }
  }

  @override
  void didReplace({Route newRoute, Route oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    int index = _routes.indexOf(oldRoute);
    assert(index != -1);
    bool isLast = _routes.last == oldRoute;
    print('LifecycleObserver#didReplace(newRoute: ${newRoute.settings.name}, '
        'oldRoute: ${oldRoute.settings.name}, isLast: $isLast)');

    final Set<LifecycleAware> oldSubscribers = _listeners[oldRoute];
    oldSubscribers?.forEach((lifecycleAware) {
      lifecycleAware.onLifecycleEvent(LifecycleEvent.pop);
    });

    _routes.remove(oldRoute);

    if (isLast) {
      if (oldRoute is PageRoute && newRoute is PopupRoute) {
        PageRoute lastPageRoute =
            _routes.lastWhere((r) => r is PageRoute, orElse: () => null);
        // 上一个PageRoute触发visible
        if (lastPageRoute != null) {
          final Set<LifecycleAware> lastPageSubscribers =
              _listeners[lastPageRoute];
          lastPageSubscribers?.forEach((lifecycleAware) {
            lifecycleAware.onLifecycleEvent(LifecycleEvent.visible);
          });
        }
      } else if (oldRoute is PopupRoute && newRoute is PageRoute) {
        //  fixme: 之前的PopupRoute是否触发invisible ？
        PageRoute lastPageRoute =
            _routes.lastWhere((r) => r is PageRoute, orElse: () => null);
        if (lastPageRoute != null) {
          // 之前的Route触发invisible
          final Set<LifecycleAware> lastPageSubscribers =
              _listeners[lastPageRoute];
          lastPageSubscribers?.forEach((lifecycleAware) {
            lifecycleAware.onLifecycleEvent(LifecycleEvent.invisible);
          });
        }
      }
    }

    _routes.insert(index, newRoute);
  }

  /// [route] 被移除的route
  /// [previousRoute] 被移除route下面的route,移除多个route时,该参数值不变
  @override
  void didRemove(Route route, Route previousRoute) {
    super.didRemove(route, previousRoute);
    print('LifecycleObserver#didRemove(route: ${route.settings.name}, '
        'previousRoute: ${previousRoute.settings.name})');

    final Set<LifecycleAware> subscribers = _listeners[route];
    subscribers?.forEach((lifecycleAware) {
      lifecycleAware.onLifecycleEvent(LifecycleEvent.pop);
    });
    if (previousRoute.isCurrent) {
      final Set<LifecycleAware> previousSubscribers = _listeners[previousRoute];
      previousSubscribers?.forEach((lifecycleAware) {
        lifecycleAware.onLifecycleEvent(LifecycleEvent.resume);
      });
    }

    _routes.remove(route);
  }
}
