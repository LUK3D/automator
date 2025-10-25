import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:web_socket_channel/io.dart';

class EmulatorStreamView extends StatefulWidget {
  final String url;
  final Function(IOWebSocketChannel? channel)? onChannelReady;
  const EmulatorStreamView({
    super.key,
    this.url = 'ws://localhost:8080/ws',
    this.onChannelReady,
  });

  @override
  State<EmulatorStreamView> createState() => _EmulatorStreamViewState();
}

class _EmulatorStreamViewState extends State<EmulatorStreamView> {
  late final channel = IOWebSocketChannel.connect(widget.url);
  Uint8List? _frame;

  Size displaySize = Size.zero;

  GlobalKey imageKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    channel.stream.listen((data) {
      if (data is String) {
        final json = jsonDecode(data);
        if (json['type'] == 'displays') {
          final displays = json['data']['displays'];
          final width = displays[0]['width'];
          final height = displays[0]['height'];
          setState(() {
            displaySize = Size(width.toDouble(), height.toDouble());
          });
        }
        return;
      }
      setState(() => _frame = data);
    });
    widget.onChannelReady?.call(channel);
  }

  void sendEvent(Offset offset, {int pressure = 1}) {
    final tapX = offset.dx;
    final tapY = offset.dy;

    // Flutter widget size
    final widgetWidth = imageKey.currentContext!.size!.width;
    final widgetHeight = imageKey.currentContext!.size!.height;

    final emulatorWidth = displaySize.width;
    final emulatorHeight = displaySize.height;

    // Normalized coordinates
    final relX = tapX / widgetWidth;
    final relY = tapY / widgetHeight;

    // Map to emulator pixels
    final emuX = (relX * emulatorWidth).round();
    final emuY = (relY * emulatorHeight).round();

    debugPrint('Flutter tap: ($tapX, $tapY)');
    debugPrint('Mapped to emulator: ($emuX, $emuY)');

    channel.sink.add(
      jsonEncode({
        "command": "tap",
        "x": emuX,
        "y": emuY,
        "pressure": pressure,
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _frame == null
        ? const Center(child: CircularProgressIndicator())
        : Row(
            children: [
              GestureDetector(
                onTapDown: (details) {
                  sendEvent(details.localPosition);
                },
                onTapUp: (details) {
                  sendEvent(details.localPosition, pressure: 0);
                },
                onVerticalDragStart: (details) {
                  sendEvent(details.localPosition);
                },
                onVerticalDragUpdate: (details) {
                  sendEvent(details.localPosition);
                },
                onVerticalDragEnd: (details) {
                  // Send a final event with pressure 0 to indicate lift
                  sendEvent(Offset.zero, pressure: 0);
                },
                child: Image.memory(
                  _frame!,
                  key: imageKey,
                  gaplessPlayback: true,
                  fit: BoxFit.contain,
                ),
              ),
            ],
          );
  }

  @override
  void dispose() {
    channel.sink.close();
    super.dispose();
  }
}
