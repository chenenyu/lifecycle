import 'package:flutter/material.dart';

import 'lifecycle_aware.dart';
import 'parent_page_dispatch_lifecycle_mixin.dart';
import 'parent_page_subscribe_lifecycle_mixin.dart';

/// Lifecycle wrapper for [PageView] / [TabBarView].
class ParentPageLifecycleWrapper extends StatefulWidget {
  /// Instance of [PageController] or [TabController].
  final ChangeNotifier controller;
  final OnLifecycleEvent onLifecycleEvent;
  final Widget child;

  ParentPageLifecycleWrapper({
    Key key,
    @required this.controller,
    this.onLifecycleEvent,
    @required this.child,
  })  : assert(controller is PageController || controller is TabController),
        assert(child != null),
        super(key: key);

  @override
  ParentPageLifecycleWrapperState createState() {
    if (controller is PageController) {
      return _PageViewLifecycleWrapperState();
    } else if (controller is TabController) {
      return _TabBarViewLifecycleWrapperState();
    } else {
      throw ArgumentError.value(
          controller, 'controller', 'Illegal controller type');
    }
  }

  static ParentPageLifecycleWrapperState of(BuildContext context) {
    return context.findAncestorStateOfType<ParentPageLifecycleWrapperState>();
  }
}

abstract class ParentPageLifecycleWrapperState
    extends State<ParentPageLifecycleWrapper>
    with
        LifecycleAware,
        ParentPageDispatchLifecycleMixin,
        ParentPageSubscribeLifecycleMixin {
  void onPageChanged();

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(onPageChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(onPageChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }

  @override
  void onLifecycleEvent(LifecycleEvent event) {
    // print('ParentPageLifecycleWrapperState#${event.toString()}');
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

class _PageViewLifecycleWrapperState extends ParentPageLifecycleWrapperState {
  PageController _pageController;

  @override
  void initState() {
    super.initState();
    // print('_PageViewLifecycleWrapperState#initState');
    _pageController = widget.controller;
    curPage = _pageController.initialPage;
  }

  /// 页面切换监听
  @override
  void onPageChanged() {
    int page = _pageController.page.round();
    if (curPage == page) return;
    dispatchEvent(LifecycleEvent.invisible);
    curPage = page;
    if (ModalRoute.of(context).isCurrent) {
      dispatchEvent(LifecycleEvent.active);
    } else {
      dispatchEvent(LifecycleEvent.visible);
    }
  }
}

class _TabBarViewLifecycleWrapperState extends ParentPageLifecycleWrapperState {
  TabController _tabController;

  @override
  void initState() {
    super.initState();
    // print('_TabBarViewLifecycleWrapperState#initState');
    _tabController = widget.controller;
    curPage = _tabController.index;
  }

  @override
  void onPageChanged() {
    if (_tabController.indexIsChanging) return;
    int page = _tabController.index;
    if (curPage == page) return;
    dispatchEvent(LifecycleEvent.invisible);
    curPage = page;
    if (ModalRoute
        .of(context)
        .isCurrent) {
      dispatchEvent(LifecycleEvent.active);
    } else {
      dispatchEvent(LifecycleEvent.visible);
    }
  }
}
