import 'package:flutter/widgets.dart';

import 'lifecycle_aware.dart';

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
    // print('LifecycleObserver#didPush');

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
    // print('LifecycleObserver#didPop');

    final Set<LifecycleAware> subscribers = _listeners[route];
    subscribers?.forEach((lifecycleAware) {
      lifecycleAware.onLifecycleEvent(LifecycleEvent.pop);
    });
    _routes.remove(route);

    if (previousRoute != null) {
      if (route is PageRoute) {
        final Set<LifecycleAware> previousSubscribers =
            _listeners[previousRoute];
        previousSubscribers?.forEach((lifecycleAware) {
          lifecycleAware.onLifecycleEvent(LifecycleEvent.resume);
        });

        if (previousRoute is PopupRoute) {
          Route lastPageRoute =
              _routes.lastWhere((r) => r is PageRoute, orElse: () => null);
          if (lastPageRoute != null) {
            final Set<LifecycleAware> previousPageSubscribers =
                _listeners[lastPageRoute];
            previousPageSubscribers?.forEach((lifecycleAware) {
              lifecycleAware.onLifecycleEvent(LifecycleEvent.visible);
            });
          }
        }
      } else if (route is PopupRoute) {
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
    super.didReplace();
    print('LifecycleObserver#didReplace');

    // todo ?

    int index = _routes.indexOf(oldRoute);
    assert(index != -1);
    _routes.removeAt(index);
    _routes.insert(index, newRoute);
  }

  @override
  void didRemove(Route route, Route previousRoute) {
    super.didRemove(route, previousRoute);
    print('LifecycleObserver#didRemove');

    // todo?
    // final Set<LifecycleAware> subscribers = _listeners[route];
    // subscribers?.forEach((lifecycleAware) {
    //   lifecycleAware.onPop();
    // });
    // if (route.isCurrent) {
    //   final Set<LifecycleAware> previousSubscribers = _listeners[previousRoute];
    //   previousSubscribers?.forEach((lifecycleAware) {
    //     lifecycleAware.onResume();
    //   });
    // }

    _routes.remove(route);
  }
}

final LifecycleObserver defaultLifecycleObserver = LifecycleObserver();
