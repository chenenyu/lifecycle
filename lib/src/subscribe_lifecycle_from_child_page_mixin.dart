import 'package:flutter/widgets.dart';

import 'child_page_lifecycle_wrapper.dart';
import 'lifecycle_aware.dart';
import 'parent_page_lifecycle_wrapper.dart';

/// Subscribe lifecycle event from [ChildPageLifecycleWrapper].
/// This is used in nested page view.
mixin SubscribeLifecycleFromChildPageMixin
    on State<ParentPageLifecycleWrapper>, LifecycleAware {
  ChildPageLifecycleWrapperState _pageLifecycleWrapperState;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _pageLifecycleWrapperState = ChildPageLifecycleWrapper.of(context);
    _pageLifecycleWrapperState?.subscribe(this);
  }

  @override
  void dispose() {
    _pageLifecycleWrapperState?.unsubscribe(this);
    super.dispose();
  }
}
