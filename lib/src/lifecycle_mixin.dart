import 'package:flutter/widgets.dart';

import 'lifecycle_aware.dart';
import 'lifecycle_observer.dart';
import 'lifecycle_observer_provider.dart';

mixin LifecycleMixin<T extends StatefulWidget> on State<T>, LifecycleAware {
  LifecycleObserver _lifecycleObserver;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _lifecycleObserver = LifecycleObserverProvider.of(context);
    _lifecycleObserver.subscribe(this, ModalRoute.of(context));
  }

  @override
  void dispose() {
    _lifecycleObserver.unsubscribe(this);
    super.dispose();
  }
}
