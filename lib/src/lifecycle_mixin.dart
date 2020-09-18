import 'package:flutter/widgets.dart';
import 'lifecycle_aware.dart';
import 'lifecycle_observer.dart';

mixin LifecycleMixin<T extends StatefulWidget> on State<T>, LifecycleAware {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    lifecycleObserver.subscribe(this, ModalRoute.of(context));
  }

  @override
  void dispose() {
    lifecycleObserver.unsubscribe(this);
    super.dispose();
  }
}
