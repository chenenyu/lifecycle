import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../logging/demo_log.dart';

class DemoScaffold extends StatelessWidget {
  const DemoScaffold({
    super.key,
    required this.title,
    required this.log,
    required this.body,
    this.bottom,
    this.actions,
  });

  final String title;
  final DemoLog log;
  final Widget body;
  final PreferredSizeWidget? bottom;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title), bottom: bottom, actions: actions),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final panel = LifecycleLogPanel(log: log);
          if (constraints.maxWidth >= 900) {
            return Row(
              children: [
                Expanded(child: body),
                const VerticalDivider(width: 1),
                SizedBox(width: 380, child: panel),
              ],
            );
          }
          return _NarrowDemoLayout(body: body, panel: panel, log: log);
        },
      ),
    );
  }
}

class _NarrowDemoLayout extends StatefulWidget {
  const _NarrowDemoLayout({
    required this.body,
    required this.panel,
    required this.log,
  });

  final Widget body;
  final Widget panel;
  final DemoLog log;

  @override
  State<_NarrowDemoLayout> createState() => _NarrowDemoLayoutState();
}

class _NarrowDemoLayoutState extends State<_NarrowDemoLayout> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(child: widget.body),
        const Divider(height: 1),
        Material(
          color: Theme.of(context).colorScheme.surfaceContainerLow,
          child: InkWell(
            key: const ValueKey('lifecycle-log-toggle'),
            onTap: () => setState(() => _expanded = !_expanded),
            child: SizedBox(
              height: 48,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    const Icon(Icons.receipt_long_outlined),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Transition log',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    AnimatedBuilder(
                      animation: widget.log,
                      builder: (context, child) => Text(
                        '${widget.log.entries.length}',
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(_expanded ? Icons.expand_more : Icons.expand_less),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (_expanded) SizedBox(height: 220, child: widget.panel),
      ],
    );
  }
}

class LifecycleLogPanel extends StatefulWidget {
  const LifecycleLogPanel({super.key, required this.log});

  final DemoLog log;

  @override
  State<LifecycleLogPanel> createState() => _LifecycleLogPanelState();
}

class _LifecycleLogPanelState extends State<LifecycleLogPanel> {
  String? _source;
  bool _eventsOnly = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.log,
      builder: (context, child) {
        final sources = widget.log.sources.toList()..sort();
        final selectedSource = sources.contains(_source) ? _source : null;
        final entries = widget.log.entries.reversed.where((entry) {
          return (selectedSource == null || entry.source == selectedSource) &&
              (!_eventsOnly || entry.events.isNotEmpty);
        }).toList();

        return Material(
          color: Theme.of(context).colorScheme.surfaceContainerLow,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _LogToolbar(
                log: widget.log,
                sources: sources,
                selectedSource: selectedSource,
                eventsOnly: _eventsOnly,
                onSourceChanged: (value) => setState(() => _source = value),
                onEventsOnlyChanged: (value) =>
                    setState(() => _eventsOnly = value),
                onCopy: () => _copyEntries(entries),
              ),
              Expanded(
                child: entries.isEmpty
                    ? const Center(child: Text('No matching transitions yet'))
                    : ListView.builder(
                        key: const ValueKey('lifecycle-log-list'),
                        itemCount: entries.length,
                        itemBuilder: (context, index) =>
                            _LogEntryTile(entry: entries[index]),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _copyEntries(List<DemoLogEntry> entries) async {
    final text = entries.reversed.map((entry) => entry.copyText).join('\n');
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Lifecycle log copied')));
  }
}

class _LogToolbar extends StatelessWidget {
  const _LogToolbar({
    required this.log,
    required this.sources,
    required this.selectedSource,
    required this.eventsOnly,
    required this.onSourceChanged,
    required this.onEventsOnlyChanged,
    required this.onCopy,
  });

  final DemoLog log;
  final List<String> sources;
  final String? selectedSource;
  final bool eventsOnly;
  final ValueChanged<String?> onSourceChanged;
  final ValueChanged<bool> onEventsOnlyChanged;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 6, 4, 4),
      child: Row(
        children: [
          const Text(
            'Transitions',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String?>(
                key: const ValueKey('log-source-filter'),
                value: selectedSource,
                isDense: true,
                isExpanded: true,
                hint: const Text('All sources'),
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('All sources'),
                  ),
                  for (final source in sources)
                    DropdownMenuItem<String?>(
                      value: source,
                      child: Text(source, overflow: TextOverflow.ellipsis),
                    ),
                ],
                onChanged: onSourceChanged,
              ),
            ),
          ),
          Tooltip(
            message: eventsOnly ? 'Show every transition' : 'Show events only',
            child: IconButton(
              key: const ValueKey('log-events-only'),
              visualDensity: VisualDensity.compact,
              isSelected: eventsOnly,
              onPressed: () => onEventsOnlyChanged(!eventsOnly),
              icon: const Icon(Icons.bolt_outlined),
              selectedIcon: const Icon(Icons.bolt),
            ),
          ),
          IconButton(
            key: const ValueKey('log-pause'),
            visualDensity: VisualDensity.compact,
            tooltip: log.paused ? 'Resume recording' : 'Pause recording',
            onPressed: log.togglePaused,
            icon: Icon(log.paused ? Icons.play_arrow : Icons.pause),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            tooltip: 'Copy visible log',
            onPressed: onCopy,
            icon: const Icon(Icons.copy_outlined),
          ),
          IconButton(
            key: const ValueKey('log-clear'),
            visualDensity: VisualDensity.compact,
            tooltip: 'Clear log',
            onPressed: log.clear,
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
    );
  }
}

class _LogEntryTile extends StatelessWidget {
  const _LogEntryTile({required this.entry});

  final DemoLogEntry entry;

  @override
  Widget build(BuildContext context) {
    final transition = entry.transition;
    final fraction =
        '${entry.previous.visibleFraction.toStringAsFixed(2)} → '
        '${entry.current.visibleFraction.toStringAsFixed(2)}';
    return ExpansionTile(
      tilePadding: const EdgeInsets.symmetric(horizontal: 12),
      childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      dense: true,
      title: Text(
        '#${entry.sequence} ${entry.source}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        '${transition.previous.phase.name} → '
        '${transition.current.phase.name} · ${transition.cause.name}',
      ),
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'fraction: $fraction\n'
            'events: ${entry.eventSummary}\n'
            'app: ${entry.current.appState?.name ?? 'unknown'}',
          ),
        ),
      ],
    );
  }
}
