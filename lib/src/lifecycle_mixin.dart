import 'package:flutter/widgets.dart';

import 'lifecycle_aware.dart';
import 'lifecycle_observer.dart';

mixin LifecycleMixin<T extends StatefulWidget> on State<T>, LifecycleAware {
  LifecycleObserver _lifecycleObserver;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _lifecycleObserver = LifecycleObserver.internalGet(context);
    _lifecycleObserver.subscribe(
        this, ModalRoute.of(context), lifecycle_events_all);
  }

  @override
  void dispose() {
    _lifecycleObserver.unsubscribe(this);
    super.dispose();
  }
}
