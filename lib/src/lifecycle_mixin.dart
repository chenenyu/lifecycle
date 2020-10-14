import 'package:flutter/widgets.dart';

import 'lifecycle_aware.dart';
import 'lifecycle_observer.dart';

mixin LifecycleMixin<T extends StatefulWidget> on State<T>, LifecycleAware {
  LifecycleObserver _lifecycleObserver;

  @override
  void initState() {
    super.initState();
    onLifecycleEvent(LifecycleEvent.push);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _lifecycleObserver = LifecycleObserver.internalGet(context);
    _lifecycleObserver.subscribe(this, ModalRoute.of(context));
  }

  @override
  void dispose() {
    onLifecycleEvent(LifecycleEvent.pop);
    _lifecycleObserver.unsubscribe(this);
    super.dispose();
  }
}
