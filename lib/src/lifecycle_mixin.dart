import 'package:flutter/widgets.dart';

import 'lifecycle_aware.dart';
import 'lifecycle_observer.dart';

mixin LifecycleMixin<T extends StatefulWidget> on State<T>, LifecycleAware {
  LifecycleObserver? _lifecycleObserver;

  @override
  void initState() {
    super.initState();
    handleLifecycleEvents([LifecycleEvent.push]);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route == null) return;
    if (_lifecycleObserver == null) {
      _lifecycleObserver = LifecycleObserver.internalGet(context);
    }
    _lifecycleObserver!.subscribe(this, route);
  }

  @override
  void dispose() {
    handleLifecycleEvents([LifecycleEvent.pop]);
    _lifecycleObserver!.unsubscribe(this);
    super.dispose();
  }
}
