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

const Set<LifecycleEvent> lifecycle_events_all = <LifecycleEvent>{
  LifecycleEvent.push,
  LifecycleEvent.visible,
  LifecycleEvent.active,
  LifecycleEvent.inactive,
  LifecycleEvent.invisible,
  LifecycleEvent.pop,
};

const Set<LifecycleEvent> lifecycle_events_only_push_pop = <LifecycleEvent>{
  LifecycleEvent.push,
  LifecycleEvent.pop,
};

const Set<LifecycleEvent> lifecycle_events_without_push = <LifecycleEvent>{
  LifecycleEvent.visible,
  LifecycleEvent.active,
  LifecycleEvent.inactive,
  LifecycleEvent.invisible,
  LifecycleEvent.pop,
};

const Set<LifecycleEvent> lifecycle_events_without_push_pop = <LifecycleEvent>{
  LifecycleEvent.visible,
  LifecycleEvent.active,
  LifecycleEvent.inactive,
  LifecycleEvent.invisible,
};
