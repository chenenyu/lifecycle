import 'package:flutter/material.dart';

import 'lifecycle_aware.dart';
import 'log.dart';
import 'parent_page_dispatch_lifecycle_mixin.dart';
import 'parent_page_subscribe_lifecycle_mixin.dart';

/// Lifecycle wrapper for [PageView] / [TabBarView].
class ParentPageLifecycleWrapper extends StatefulWidget {
  /// Instance of [PageController] or [TabController].
  final ChangeNotifier controller;
  final OnLifecycleEvent? onLifecycleEvent;
  final Widget child;

  ParentPageLifecycleWrapper({
    Key? key,
    required this.controller,
    this.onLifecycleEvent,
    required this.child,
  })   : assert(controller is PageController || controller is TabController),
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

  static ParentPageLifecycleWrapperState? of(BuildContext context) {
    return context.findAncestorStateOfType<ParentPageLifecycleWrapperState>();
  }
}

abstract class ParentPageLifecycleWrapperState
    extends State<ParentPageLifecycleWrapper>
    with
        LifecycleAware,
        ParentPageDispatchLifecycleMixin,
        ParentPageSubscribeLifecycleMixin {
  bool _popped = false;

  void onPageChanged();

  @override
  void initState() {
    super.initState();
    log('ParentPageLifecycleWrapperState($hashCode)#initState');
    widget.controller.addListener(onPageChanged);
  }

  @override
  void dispose() {
    log('ParentPageLifecycleWrapperState($hashCode)#dispose');
    widget.controller.removeListener(onPageChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }

  @override
  void onLifecycleEvent(LifecycleEvent event) {
    log('ParentPageLifecycleWrapperState($hashCode)#${event.toString()}');
    dispatchEvent(event);
    if (widget.onLifecycleEvent != null) {
      // Intercept pop event except first time.
      if (event == LifecycleEvent.pop) {
        if (_popped == true) {
          return;
        } else {
          _popped = true;
        }
      }
      widget.onLifecycleEvent!(event);
    }
  }
}

class _PageViewLifecycleWrapperState extends ParentPageLifecycleWrapperState {
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = widget.controller as PageController;
    curPage = _pageController.initialPage;
  }

  /// 页面切换监听
  @override
  void onPageChanged() {
    if (_pageController.page == null) return;
    int page = _pageController.page!.round();
    if (curPage == page) return;
    dispatchEvent(LifecycleEvent.invisible);
    curPage = page;
    if (ModalRoute.of(context)?.isCurrent == true) {
      dispatchEvent(LifecycleEvent.active);
    } else {
      dispatchEvent(LifecycleEvent.visible);
    }
  }
}

class _TabBarViewLifecycleWrapperState extends ParentPageLifecycleWrapperState {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = widget.controller as TabController;
    curPage = _tabController.index;
  }

  @override
  void onPageChanged() {
    if (_tabController.indexIsChanging == true) return;
    int page = _tabController.index;
    if (curPage == page) return;
    dispatchEvent(LifecycleEvent.invisible);
    curPage = page;
    if (ModalRoute.of(context)?.isCurrent == true) {
      dispatchEvent(LifecycleEvent.active);
    } else {
      dispatchEvent(LifecycleEvent.visible);
    }
  }
}
