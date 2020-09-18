import 'dart:async';

import 'package:flutter/material.dart';

import '../lifecycle_aware.dart';
import 'page_view_lifecycle_wrapper.dart';

/// Lifecycle wrapper for children of [PageView] and [TabBarView].
/// See [PageViewLifecycleWrapper].
class PageLifecycleWrapper extends StatefulWidget {
  final int index;
  final OnLifecycleEvent onLifecycleEvent;
  final bool wantKeepAlive;
  final Widget child;

  PageLifecycleWrapper({
    Key key,
    @required this.index,
    @required this.onLifecycleEvent,
    this.wantKeepAlive = false,
    @required this.child,
  })  : assert(index != null && index >= 0),
        assert(child != null),
        super(key: key);

  @override
  _PageLifecycleWrapperState createState() {
    return _PageLifecycleWrapperState();
  }
}

class _PageLifecycleWrapperState extends State<PageLifecycleWrapper>
    with LifecycleAware, AutomaticKeepAliveClientMixin {
  StreamSubscription<LifecycleEvent> _ss;

  @override
  bool get wantKeepAlive => widget.wantKeepAlive ?? false;

  @override
  void initState() {
    super.initState();
    // print('_PageLifecycleWrapperState#initState');
    onLifecycleEvent(LifecycleEvent.push);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_ss == null) {
      Stream<LifecycleEvent> stream =
          PageViewLifecycleWrapper.of(context, widget.index);
      if (stream != null) {
        _ss = stream.listen(onLifecycleEvent);
      }
    }
  }

  @override
  void dispose() {
    // print('_PageLifecycleWrapperState#dispose');
    onLifecycleEvent(LifecycleEvent.pop);
    _ss?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }

  @override
  void onLifecycleEvent(LifecycleEvent event) {
    if (widget.onLifecycleEvent != null) {
      widget.onLifecycleEvent(event);
    }
  }
}
