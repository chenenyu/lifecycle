import 'package:flutter/widgets.dart';

import 'lifecycle_observer.dart';

/// An interface for objects that are aware of their current [Route].
///
/// This is used with [LifecycleObserver] to make a widget aware of changes to the
/// [Navigator]'s session history.
abstract class LifecycleAware {
  void onLifecycleEvent(LifecycleEvent event);
}

typedef OnLifecycleEvent = void Function(LifecycleEvent event);

enum LifecycleEvent {
  push,
  visible,
  active,
  inactive,
  invisible,
  pop,
}
