// Provider for managing emulator state and commands
import 'package:automator/services/emulator_service.dart';
import 'package:automator/services/server_service.dart';
import 'package:flutter/foundation.dart';

class EmulatorProvider with ChangeNotifier {
  final EmulatorService _emulatorService = EmulatorService();
  final ServerService _serverService = ServerService();
  bool _isEmulatorRunning = false;

  bool get isEmulatorRunning => _isEmulatorRunning;

  final List<String> _logs = [];
  List<String> get logs => _logs;

  void listDevices() async {
    final value = await _emulatorService.getAvailableEmulators();
    if (kDebugMode) {
      debugPrint('Available Emulators: $value');
    }
  }

  Future<void> startEmulator() async {
    final result = await _emulatorService.startEmulator(
      'Medium_Phone_API_36.1',
    );
    result.output.listen((output) {
      if (output.toLowerCase().contains(
            'started grpc server at [::]:${_emulatorService.port}',
          ) ||
          output.toLowerCase().contains(
            'running multiple emulators with the same avd',
          )) {
        _serverService.startServer().then((result) {
          result.output.listen((serverOutput) {
            _logs.add('SERVER: $serverOutput');
            notifyListeners();
          });
        });
        _isEmulatorRunning = true;
        notifyListeners();
      }
      _logs.add(output);
      notifyListeners();
    });
  }

  void stopEmulator() {
    _emulatorService.stopEmulator();
    _serverService.stopServer();
    _isEmulatorRunning = false;
    notifyListeners();
  }
}
