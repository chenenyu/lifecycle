import 'package:flutter/widgets.dart';

import 'lifecycle_aware.dart';
import 'lifecycle_observer.dart';

mixin LifecycleMixin<T extends StatefulWidget> on State<T>, LifecycleAware {
  late LifecycleObserver _lifecycleObserver;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _lifecycleObserver = LifecycleObserver.internalGet(context);
    final route = ModalRoute.of(context);
    if (route == null) return;
    _lifecycleObserver.subscribe(this, route, lifecycle_events_all);
  }

  @override
  void dispose() {
    _lifecycleObserver.unsubscribe(this);
    super.dispose();
  }
}
