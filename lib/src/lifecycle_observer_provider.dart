import 'package:flutter/widgets.dart';

import 'lifecycle_observer.dart';

class LifecycleObserverProvider<R extends Route<dynamic>>
    extends InheritedWidget {
  final LifecycleObserver<R> lifecycleObserver;

  LifecycleObserverProvider({
    Key key,
    @required this.lifecycleObserver,
    @required Widget child,
  }) : super(key: key, child: child);

  @override
  bool updateShouldNotify(LifecycleObserverProvider oldWidget) {
    if (lifecycleObserver != oldWidget.lifecycleObserver) return true;
    return false;
  }

  static LifecycleObserver of(BuildContext context) {
    LifecycleObserverProvider provider =
        context.dependOnInheritedWidgetOfExactType<LifecycleObserverProvider>();
    return provider?.lifecycleObserver ?? defaultLifecycleObserver;
  }
}
