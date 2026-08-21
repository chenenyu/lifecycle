/*
 * example 的结构化生命周期日志模型。
 *
 * 日志保存完整 Transition 而不是只保存 Event，因此 visibleFraction-only 变化和 terminal
 * appState 也不会丢失；ChangeNotifier 驱动日志面板刷新，固定容量队列避免长时间演示
 * 导致内存无限增长。
 */
import 'dart:collection';

import 'package:flutter/widgets.dart';
import 'package:lifecycle/lifecycle.dart';

/// 一条可展示、可复制的不可变 Transition 日志。
class DemoLogEntry {
  const DemoLogEntry({
    required this.sequence,
    required this.timestamp,
    required this.source,
    required this.transition,
  });

  final int sequence;
  final DateTime timestamp;
  final String source;
  final LifecycleTransition transition;

  LifecycleSnapshot get previous => transition.previous;
  LifecycleSnapshot get current => transition.current;
  LifecycleCause get cause => transition.cause;
  List<LifecycleEvent> get events => transition.events;

  String get eventSummary => events.isEmpty
      ? 'snapshot changed'
      : events.map((event) => event.name).join(', ');

  String get copyText {
    final fraction =
        '${previous.visibleFraction.toStringAsFixed(2)} → '
        '${current.visibleFraction.toStringAsFixed(2)}';
    return '#$sequence $source | ${previous.phase.name} → '
        '${current.phase.name} | fraction $fraction | '
        '${cause.name} | $eventSummary';
  }
}

/// 有容量上限、可通知 UI 的内存日志仓库。
class DemoLog extends ChangeNotifier {
  static const maximumEntries = 200;

  final List<DemoLogEntry> _entries = [];
  var _nextSequence = 1;
  var _notificationScheduled = false;
  var _paused = false;
  var _disposed = false;

  UnmodifiableListView<DemoLogEntry> get entries =>
      UnmodifiableListView(_entries);

  bool get paused => _paused;

  Set<String> get sources => {for (final entry in _entries) entry.source};

  void record(String source, LifecycleTransition transition) {
    if (_paused || _disposed) return;
    _entries.add(
      DemoLogEntry(
        sequence: _nextSequence++,
        timestamp: DateTime.now(),
        source: source,
        transition: transition,
      ),
    );
    if (_entries.length > maximumEntries) {
      _entries.removeRange(0, _entries.length - maximumEntries);
    }
    _scheduleNotification();
  }

  void togglePaused() {
    _paused = !_paused;
    _scheduleNotification();
  }

  void clear() {
    _entries.clear();
    _scheduleNotification();
  }

  void _scheduleNotification() {
    if (_disposed || _notificationScheduled) return;
    _notificationScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _notificationScheduled = false;
      if (!_disposed) notifyListeners();
    });
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
