import 'package:automator/features/emulator/emulator_provider.dart';
import 'package:automator/features/emulator/emulator_stream_view.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  @override
  void initState() {
    super.initState();
    context.read<EmulatorProvider>().listDevices();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            color: Colors.black,
            padding: EdgeInsets.all(30),
            child: Container(
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 4,
                  offset: Offset(2, 2),
                ),
              ],
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints( minWidth: 300),
                child: context.watch<EmulatorProvider>().isEmulatorRunning
                    ? EmulatorStreamView()
                    : Center(
                        child: Text(
                          'Device not running.',
                          style: TextStyle(fontSize: 18, color: Colors.black54),
                        ),
                      ),
              ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 30,
                  ),
                  child: Row(
                    spacing: 40,
                    children: [
                      RichText(
                        text: TextSpan(
                          text: 'Status: ',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                          children: [
                            TextSpan(
                              text:
                                  context
                                      .watch<EmulatorProvider>()
                                      .isEmulatorRunning
                                  ? 'Running'
                                  : 'Stopped',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color:
                                    context
                                        .watch<EmulatorProvider>()
                                        .isEmulatorRunning
                                    ? Colors.green
                                    : Colors.red,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (!context.watch<EmulatorProvider>().isEmulatorRunning)
                        ElevatedButton(
                          onPressed: () {
                            context.read<EmulatorProvider>().startEmulator();
                          },
                          child: const Text('Start Device'),
                        )
                      else
                        ElevatedButton(
                          onPressed: () {
                            context.read<EmulatorProvider>().stopEmulator();
                          },
                          child: const Text('Stop Device'),
                        ),
                    ],
                  ),
                ),
                Divider(height: 1),

                Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 30,
                  ),
                  child: Text(
                    'Device Logs:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                Divider(height: 1),
                Expanded(
                  child: ListView.builder(
                    itemCount: context.watch<EmulatorProvider>().logs.length,
                    itemBuilder: (context, index) {
                      final log = context.watch<EmulatorProvider>().logs[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 2,
                          horizontal: 30,
                        ),
                        child: Text(log),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
