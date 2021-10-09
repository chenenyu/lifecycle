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
    _data = List<String>.generate(10, (index) => 'Item $index');
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
          'Sub1Page',
        ),
      ),
      body: ListView.builder(
        itemCount: _data.length,
        itemBuilder: (context, index) {
          return LifecycleWrapper(
            onLifecycleEvent: (LifecycleEvent event) {
              log.add('ListPage(item$index)#${event.toString()}');
            },
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
