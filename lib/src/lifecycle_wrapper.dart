import 'package:flutter/material.dart';

import 'lifecycle_aware.dart';
import 'lifecycle_mixin.dart';

/// Lifecycle wrapper for [Widget].
/// If you are using a [StatefulWidget], consider mixin it with [LifecycleMixin].
class LifecycleWrapper extends StatefulWidget {
  final OnLifecycleEvent onLifecycleEvent;
  final Widget child;

  const LifecycleWrapper({
    Key? key,
    required this.onLifecycleEvent,
    required this.child,
  }) : super(key: key);

  @override
  _LifecycleWrapperState createState() {
    return _LifecycleWrapperState();
  }
}

class _LifecycleWrapperState extends State<LifecycleWrapper>
    with LifecycleAware, LifecycleMixin {
  @override
  Widget build(BuildContext context) {
    return widget.child;
  }

  @override
  void onLifecycleEvent(LifecycleEvent event) {
    widget.onLifecycleEvent(event);
  }
}
