# Changelog

## [1.0.0-alpha1] - 2026/08/24

Complete, API-incompatible redesign of the package.

### Breaking changes

* Replace the 0.x observer and wrapper APIs with a composable lifecycle tree
  built around `LifecycleController`, `LifecycleScope`, normalized
  `LifecycleConstraint`, and immutable `LifecycleSnapshot` values.
* Use deterministic `LifecycleEvent` and `LifecycleTransition` notifications
  through the standard `ChangeNotifier` API.
* Defer viewport activation until scrolling settles by default; use
  `ViewportLifecycleActivationPolicy.immediate` for immediate activation.
* Require Flutter 3.32 or newer.

### Added

* Support App, Navigator 1.0/2.0, PageView, TabBarView, and scrollable viewport
  lifecycle composition.
* Add `LifecycleApp`, `LifecycleBoundary`, `LifecycleListener`,
  `LifecycleBuilder`, and `LifecycleStateMixin`.
* Add stable page identity, nested Navigator support, batched viewport
  measurement, an interactive example, and comprehensive test suites.

## [0.10.0] - 2025/03/28

* Fix issue #27: Custom `initialPage` in `PageController`(also `initialIndex` in `TabController`)
  will not trigger `visible` and `active`.
* Migrate to new flutter's gradle plugins.

## [0.9.0] - 2024/09/04

* Fix issue #26: both onVisible and onInvisible were not called on web platform.
* Bump flutter version to 3.13.0.

## [0.8.0] - 2023/08/23

* Fix: use `addPostFrameCallback` to avoid unnecessary frame callback.
* The param `wantKeepAlive` in `ChildPageLifecycleWrapper` is not required now.
* Export some mixins.

## [0.7.0] - 2023/04/23

* Added: `iterateRoutes()`, `removeRoute()`.
* Deprecated: `findRoute()`, `removeNamed()`.

## [0.6.0] - 2022/07/01

* Fix issue #23.

## [0.5.0] - 2022/05/16

* Flutter 3.

## [0.4.4] - 2022/04/20

* issue #20. Fix error `Concurrent modification during iteration`.

## [0.4.3] - 2022/02/17

* issue #19.

## [0.4.2] - 2021/12/03

* issue #16.

## [0.4.1] - 2021/11/04

* Fix a null cast error.

## [0.4.0] - 2021/10/22

* ScrollView item lifecycle support.
* Rename `ParentPageLifecycleWrapper` to `PageViewLifecycleWrapper` and remove required param `controller`.

## [0.3.4] - 2021/10/09

* Ensure that `inactive`and `invisible` occurs when single `pop` triggered.

## [0.3.3] - 2021/09/29

* Fix issue #9.

## [0.3.2] - 2021/09/23

* NEW API: `findRoute(String routeName)`.
* Add `flutter_lints`.

## [0.3.1] - 2021/09/01

* Bug fixes.
* Opt: events callback immediately when tab bar changed.

## [0.3.0] - 2021/08/31

**Breaking changes:**

* More reasonable lifecycle events just like Android platform.

## [0.2.0] - 2021/04/12

* Null safety.

## [0.1.1+1] - 2020/12/30

* Fix a NPE caused by debug log.

## [0.1.0] - 2020/12/21

* Emit `push` after `initState` and `pop` before `dispose`.
* Optimize events delivery in nested page view.

## [0.0.6] - 2020/10/28

* Bug fix.

## [0.0.5] - 2020/10/15

* Support usage of `Navigator` widget.

## [0.0.4] - 2020/09/27

* Remove the `active` event which sent manually after page view pushed.

## [0.0.3] - 2020/09/24

* Fix bugs in nested page view.

## [0.0.2] - 2020/09/23

* Support nested page view.

## [0.0.1] - 2020/09/23

* Initial release.
