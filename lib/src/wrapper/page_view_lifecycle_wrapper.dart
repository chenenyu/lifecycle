import 'dart:async';

import 'package:flutter/material.dart';

import '../lifecycle_aware.dart';
import '../lifecycle_mixin.dart';

/// Lifecycle wrapper for [PageView]/[TabBarView].
class PageViewLifecycleWrapper extends StatefulWidget {
  /// [PageController]/[TabController]
  final ChangeNotifier controller;
  final OnLifecycleEvent onLifecycleEvent;
  final Widget child;

  PageViewLifecycleWrapper({
    Key key,
    @required this.controller,
    this.onLifecycleEvent,
    @required this.child,
  })  : assert(controller is PageController || controller is TabController),
        assert(child != null),
        super(key: key);

  @override
  BasePageViewLifecycleWrapperState createState() {
    if (controller is PageController) {
      return _PageViewLifecycleWrapperState();
    } else if (controller is TabController) {
      return _TabBarViewLifecycleWrapperState();
    } else {
      throw ArgumentError.value(controller, 'controller', 'Illegal param type');
    }
  }

  static Stream<LifecycleEvent> of(BuildContext context, int index) {
    assert(index >= 0);
    BasePageViewLifecycleWrapperState state =
        (context.findAncestorStateOfType<BasePageViewLifecycleWrapperState>());
    return state?.getStreamByIndex(index);
  }
}

abstract class BasePageViewLifecycleWrapperState
    extends State<PageViewLifecycleWrapper>
    with LifecycleAware, LifecycleMixin {
  /// Map of page and [StreamController].
  Map<int, StreamController<LifecycleEvent>> streamControllers = {};

  /// Current page.
  int curPage;

  /// Retrieve [Stream] buy page index.
  Stream<LifecycleEvent> getStreamByIndex(int index);

  void onPageChanged();

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(onPageChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(onPageChanged);
    streamControllers?.values?.forEach((e) => e.close());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }

  /// Dispatch event to stream subscription
  void dispatchEvent(LifecycleEvent event) {
    streamControllers[curPage].add(event);
  }

  @override
  void onLifecycleEvent(LifecycleEvent event) {
    // print('_BasePageViewLifecycleWrapperState#${event.toString()}');
    if (widget.onLifecycleEvent != null) {
      widget.onLifecycleEvent(event);
    }
    switch (event) {
      case LifecycleEvent.push:
      case LifecycleEvent.pop:
        break;
      case LifecycleEvent.visible:
      case LifecycleEvent.active:
      case LifecycleEvent.inactive:
      case LifecycleEvent.invisible:
        dispatchEvent(event);
        break;
    }
  }
}

class _PageViewLifecycleWrapperState extends BasePageViewLifecycleWrapperState {
  PageController _pageController;

  @override
  void initState() {
    super.initState();
    // print('_PageViewLifecycleWrapperState#initState');
    _pageController = widget.controller;
    curPage = _pageController.initialPage;
    _updateStream(curPage);
    // 补发第一个page的visible事件
    Future.microtask(() => dispatchEvent(LifecycleEvent.visible));
  }

  void _updateStream(int index) {
    streamControllers.putIfAbsent(
        index, () => StreamController.broadcast(sync: false));
  }

  @override
  Stream<LifecycleEvent> getStreamByIndex(int index) {
    _updateStream(index);
    return streamControllers[index].stream;
  }

  /// 页面切换监听
  @override
  void onPageChanged() {
    int page = _pageController.page.round();
    if (curPage == page) return;
    dispatchEvent(LifecycleEvent.invisible);
    curPage = page;
    _updateStream(curPage);
    dispatchEvent(LifecycleEvent.visible);
  }
}

class _TabBarViewLifecycleWrapperState
    extends BasePageViewLifecycleWrapperState {
  TabController _tabController;

  @override
  void initState() {
    super.initState();
    // print('_TabBarViewLifecycleWrapperState#initState');
    _tabController = widget.controller;
    curPage = _tabController.index;
    _updateStream(curPage);
    // 补发第一个page的visible事件
    Future.microtask(() => dispatchEvent(LifecycleEvent.visible));
  }

  void _updateStream(int index) {
    streamControllers.putIfAbsent(
        index, () => StreamController.broadcast(sync: false));
  }

  @override
  Stream<LifecycleEvent> getStreamByIndex(int index) {
    _updateStream(index);
    return streamControllers[index].stream;
  }

  @override
  void onPageChanged() {
    if (_tabController.indexIsChanging) return;
    int page = _tabController.index;
    if (curPage == page) return;
    dispatchEvent(LifecycleEvent.invisible);
    curPage = page;
    _updateStream(curPage);
    dispatchEvent(LifecycleEvent.visible);
  }
}
