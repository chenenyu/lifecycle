import 'package:flutter/material.dart';
import 'package:lifecycle/lifecycle.dart';

import '../logging/demo_log.dart';
import '../widgets/demo_scaffold.dart';
import '../widgets/demo_widgets.dart';
import '../widgets/lifecycle_status_card.dart';

class ReorderablePagesScreen extends StatefulWidget {
  const ReorderablePagesScreen({super.key, required this.log});

  final DemoLog log;

  @override
  State<ReorderablePagesScreen> createState() => _ReorderablePagesScreenState();
}

class _ReorderablePagesScreenState extends State<ReorderablePagesScreen> {
  final PageController _controller = PageController();
  List<String> _ids = ['alpha', 'beta', 'gamma'];
  int _selectedIndex = 0;

  void _reversePages() {
    final selectedId = _ids[_selectedIndex];
    setState(() {
      _ids = _ids.reversed.toList();
      _selectedIndex = _ids.indexOf(selectedId);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _controller.hasClients) {
        _controller.jumpToPage(_selectedIndex);
      }
    });
  }

  void _removeSelected() {
    if (_ids.length == 1) return;
    setState(() {
      _ids = List.of(_ids)..removeAt(_selectedIndex);
      _selectedIndex = _selectedIndex.clamp(0, _ids.length - 1);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _controller.hasClients) {
        _controller.jumpToPage(_selectedIndex);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return DemoScaffold(
      title: 'Stable page identity',
      log: widget.log,
      actions: [
        IconButton(
          key: const ValueKey('reverse-pages'),
          tooltip: 'Reverse pages',
          onPressed: _reversePages,
          icon: const Icon(Icons.swap_horiz),
        ),
        IconButton(
          key: const ValueKey('remove-selected-page'),
          tooltip: 'Remove selected page',
          onPressed: _ids.length > 1 ? _removeSelected : null,
          icon: const Icon(Icons.remove_circle_outline),
        ),
      ],
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(12),
            child: DemoInstructions(
              action:
                  'increment a page counter, reverse the data, or remove the selected page.',
              expected:
                  'stable page IDs preserve each page State and remap it to the new index.',
            ),
          ),
          Text('Order: ${_ids.join(' · ')}'),
          Expanded(
            child: LifecyclePageView.builder(
              controller: _controller,
              itemCount: _ids.length,
              pageIdBuilder: (index) => _ids[index],
              findPageIndex: (id) {
                final index = _ids.indexOf(id as String);
                return index < 0 ? null : index;
              },
              onPageChanged: (index) => _selectedIndex = index,
              onPageTransition: (index, transition) =>
                  widget.log.record('stable page index $index', transition),
              itemBuilder: (context, index) =>
                  _IdentityPage(key: ValueKey(_ids[index]), id: _ids[index]),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

class _IdentityPage extends StatefulWidget {
  const _IdentityPage({super.key, required this.id});

  final String id;

  @override
  State<_IdentityPage> createState() => _IdentityPageState();
}

class _IdentityPageState extends State<_IdentityPage> {
  int _counter = 0;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              LifecycleStatusCard(label: 'Page ${widget.id}'),
              const SizedBox(height: 12),
              Text(
                '${widget.id}: $_counter',
                key: ValueKey('counter-${widget.id}'),
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              FilledButton(
                key: ValueKey('increment-${widget.id}'),
                onPressed: () => setState(() => _counter++),
                child: const Text('Increment local State'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
