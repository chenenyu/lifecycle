import 'package:flutter/widgets.dart';

import 'lifecycle_aware.dart';
import 'lifecycle_observer.dart';
import 'widget_dispatch_lifecycle_mixin.dart';

/// Subscribe lifecycle event for normal widgets.
mixin LifecycleMixin<T extends StatefulWidget> on State<T>, LifecycleAware {
  LifecycleObserver? _lifecycleObserver;
  WidgetDispatchLifecycleMixin? _widgetDispatchLifecycleMixin;

  @override
  void initState() {
    super.initState();
    handleLifecycleEvents([LifecycleEvent.push]);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final ModalRoute? route = ModalRoute.of(context);
    // Avoid re-subscribe when a route is popping.
    // When called Navigator#pop(), the [_RouteLifecycle] will change to [popping],
    // then notify the [NavigatorObserver].
    if (route == null || !route.isActive) return;

    _widgetDispatchLifecycleMixin = null;
    context.visitAncestorElements((element) {
      if (element is StatefulElement &&
          element.state is WidgetDispatchLifecycleMixin) {
        _widgetDispatchLifecycleMixin =
            element.state as WidgetDispatchLifecycleMixin;
        return false;
      }
      return true;
    });
    if (_widgetDispatchLifecycleMixin != null) {
      _widgetDispatchLifecycleMixin!.subscribe(this);
    } else {
      _lifecycleObserver = LifecycleObserver.internalGet(context);
      _lifecycleObserver!.subscribe(this, route);
    }
  }

  @override
  void dispose() {
    handleLifecycleEvents([LifecycleEvent.pop]);
    _lifecycleObserver?.unsubscribe(this);
    _widgetDispatchLifecycleMixin?.unsubscribe(this);
    super.dispose();
  }
}
