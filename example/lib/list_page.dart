import 'package:flutter/material.dart';
import 'package:lifecycle/lifecycle.dart';

import 'overlay_log.dart';

class ListPage extends StatefulWidget {
  const ListPage({Key? key}) : super(key: key);

  @override
  _ListPageState createState() {
    return _ListPageState();
  }
}

class _ListPageState extends State<ListPage> {
  List _data = [];

  @override
  void initState() {
    super.initState();
    _data = List<String>.generate(20, (index) => 'Item $index');
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'ListPage',
        ),
      ),
      body: ListView.builder(
        itemCount: _data.length,
        itemBuilder: (context, index) {
          // return ListItem(index: index);
          return ScrollViewItemLifecycleWrapper(
            onLifecycleEvent: (LifecycleEvent event) {
              log.add('ListPage(item$index)#${event.toString()}');
            },
            wantKeepAlive: false,
            child: ListTile(
              title: Text(
                _data[index],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          if (_data.isNotEmpty) {
            setState(() {
              _data.removeLast();
            });
          }
        },
        label: const Text('Remove last'),
        icon: const Icon(Icons.remove),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.miniEndTop,
    );
  }
}

class ListItem extends StatefulWidget {
  const ListItem({Key? key, required this.index}) : super(key: key);

  final int index;

  @override
  _ListItemState createState() {
    return _ListItemState();
  }
}

class _ListItemState extends State<ListItem>
    with
        LifecycleAware,
        ScrollViewItemSubscribeLifecycleMixin,
        AutomaticKeepAliveClientMixin {
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return ListTile(
      title: Text(
        'Item ${widget.index}',
      ),
    );
  }

  @override
  void onLifecycleEvent(LifecycleEvent event) {
    log.add('ListPage(item${widget.index})#${event.toString()}');
  }

  @override
  bool get wantKeepAlive => false;
}
