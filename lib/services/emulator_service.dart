import 'dart:io';

import 'package:automator/services/shell_service.dart';

class EmulatorService {
  EmulatorService._privateConstructor();

  static final EmulatorService _instance =
      EmulatorService._privateConstructor();

  factory EmulatorService() {
    return _instance;
  }

  int get port => 8554;
  ShellService shellService = ShellService();

  Stream<String>? _stream;
  Process? _process;
  Stream<String>? get stream => _stream;
  final String basePath = 'C:/Users/%USERNAME%/AppData/Local/Android/Sdk/emulator/emulator';
  final String avdmanager = 'C:/Users/%USERNAME%/AppData/Local/Android/Sdk/cmdline-tools/latest/bin/avdmanager';

  Future<ShellStreamResult> startEmulator(String emulatorName) async {
    if (_process != null) {
      // Emulator is already running
      return ShellStreamResult(process: _process!, output: _stream!);
    }
    final result = await shellService.streamCommand(
      basePath,
      ['-avd', emulatorName, '-grpc', port.toString(), '-no-window'],
    );
    _stream = result.output;
    _process = result.process;

    return ShellStreamResult(process: _process!, output: _stream!);
  }

  Future<List<String>> getAvailableEmulators() async {
    final result = await shellService.runCommand(
      basePath,
      ['-list-avds'],
    );
    if (result.exitCode == 0) {
      return (result.stdout as String)
          .split('\n')
          .where((e) => e.isNotEmpty)
          .toList();
    } else {
      throw Exception('Failed to get available emulators: ${result.stderr}');
    }
  }

  void stopEmulator() {
    _process?.kill();
    _stream = null;
    _process = null;
  }
}
