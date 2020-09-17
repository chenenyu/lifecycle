import 'package:flutter/widgets.dart';

import 'lifecycle_observer.dart';

class LifecycleObserverProvider extends InheritedWidget {
  final LifecycleObserver<ModalRoute> lifecycleObserver =
      LifecycleObserver<ModalRoute>();

  LifecycleObserverProvider({
    Key key,
    @required Widget child,
  }) : super(key: key, child: child);

  @override
  bool updateShouldNotify(InheritedWidget oldWidget) => false;

  static LifecycleObserver<ModalRoute> of(BuildContext context) {
    try {
      LifecycleObserverProvider provider = context
          .dependOnInheritedWidgetOfExactType<LifecycleObserverProvider>();
      return provider == null ? null : provider.lifecycleObserver;
    } catch (e) {
      return null;
    }
  }
}
