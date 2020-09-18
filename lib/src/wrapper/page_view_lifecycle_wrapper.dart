import 'dart:async';

import 'package:flutter/material.dart';

import '../lifecycle_aware.dart';
import '../lifecycle_mixin.dart';

/// Lifecycle wrapper for [PageView].
class PageViewLifecycleWrapper extends StatefulWidget {
  final PageController controller;
  final OnLifecycleEvent onLifecycleEvent;
  final Widget child;

  PageViewLifecycleWrapper({
    Key key,
    @required this.controller,
    this.onLifecycleEvent,
    @required this.child,
  })  : assert(controller != null),
        assert(child != null),
        super(key: key);

  @override
  _PageViewLifecycleWrapperState createState() {
    return _PageViewLifecycleWrapperState();
  }

  static Stream<LifecycleEvent> of(BuildContext context, int index) {
    assert(index >= 0);
    _PageViewLifecycleWrapperState state =
        (context.findAncestorStateOfType<_PageViewLifecycleWrapperState>());
    return state?.getStreamByIndex(index);
  }
}

class _PageViewLifecycleWrapperState extends State<PageViewLifecycleWrapper>
    with LifecycleAware, LifecycleMixin {
  Map<int, StreamController<LifecycleEvent>> _streamControllers = {};

  int _curPage;

  @override
  void initState() {
    super.initState();
    // print('_PageViewLifecycleWrapperState#initState');
    widget.controller.addListener(_onPageChange);
    _curPage = widget.controller.initialPage;
    _updateStream(_curPage);
    // 补发第一个page的visible事件
    Future.microtask(() => _dispatchEvent(LifecycleEvent.visible));
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onPageChange);
    _streamControllers?.values?.forEach((e) => e.close());
    super.dispose();
  }

  void _updateStream(int index) {
    _streamControllers.putIfAbsent(
        index, () => StreamController.broadcast(sync: true));
  }

  Stream<LifecycleEvent> getStreamByIndex(int index) {
    _updateStream(index);
    return _streamControllers[index].stream;
  }

  /// 页面切换监听
  void _onPageChange() {
    int page = widget.controller.page.round();
    if (_curPage == page) return;
    _dispatchEvent(LifecycleEvent.invisible);
    _curPage = page;
    _updateStream(_curPage);
    _dispatchEvent(LifecycleEvent.visible);
  }

  /// 发送event
  void _dispatchEvent(LifecycleEvent event, {bool all = false}) {
    if (all == true) {
      _streamControllers.values.forEach((e) => e.add(event));
    } else {
      _streamControllers[_curPage].add(event);
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }

  @override
  void onLifecycleEvent(LifecycleEvent event) {
    // print('_PageViewLifecycleWrapperState#${event.toString()}');
    if (widget.onLifecycleEvent != null) {
      widget.onLifecycleEvent(event);
    }
    switch (event) {
      case LifecycleEvent.push:
      case LifecycleEvent.pop:
        break;
      case LifecycleEvent.visible:
      case LifecycleEvent.resume:
      case LifecycleEvent.pause:
      case LifecycleEvent.invisible:
        _dispatchEvent(event);
        break;
    }
  }
}
