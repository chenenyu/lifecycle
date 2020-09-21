import 'package:flutter/material.dart';

class LogEntry extends StatefulWidget {
  LogEntry() : super(key: entryKey);

  @override
  LogEntryState createState() {
    return LogEntryState();
  }

  static OverlayEntry _logEntry;

  static void init(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      OverlayState overlayState = Overlay.of(context);
      if (overlayState == null) return;
      _logEntry?.remove();
      _logEntry = OverlayEntry(builder: (context) {
        return LogEntry();
      });
      overlayState.insert(_logEntry);
    });
  }
}

class LogEntryState extends State<LogEntry> {
  ScrollController _controller = ScrollController();
  List<String> _logs = [];

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void add(String log) {
    _logs.add(log);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {});
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _controller?.jumpTo(_controller.position.maxScrollExtent);
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Material(
        type: MaterialType.transparency,
        child: Container(
          // height: MediaQuery.of(context).size.height / 2,
          margin:
              EdgeInsets.only(top: MediaQuery.of(context).size.height * 2 / 3),
          padding: EdgeInsets.all(16),
          color: Colors.black54,
          child: ListView.builder(
            controller: _controller,
            shrinkWrap: true,
            padding: EdgeInsets.zero,
            itemCount: _logs.length,
            itemBuilder: (context, index) {
              final String log = _logs[index];
              return Text(
                log,
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

final GlobalKey<LogEntryState> entryKey = GlobalKey();

class LogManager {
  void add(String log) {
    print(log);
    entryKey.currentState?.add(log);
  }
}

final LogManager log = LogManager();
