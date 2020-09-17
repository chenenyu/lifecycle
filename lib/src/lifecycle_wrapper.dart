import 'package:flutter/material.dart';

import 'lifecycle_aware.dart';
import 'lifecycle_mixin.dart';

/// Lifecycle wrapper for [Dialog] and [StatelessWidget].
class LifecycleWrapper extends StatefulWidget {
  final OnLifecycleEvent onLifecycleEvent;
  final Widget child;

  LifecycleWrapper({
    Key key,
    @required this.onLifecycleEvent,
    @required this.child,
  })  : assert(child != null),
        super(key: key);

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
    if (widget.onLifecycleEvent != null) {
      widget.onLifecycleEvent(event);
    }
  }
}
