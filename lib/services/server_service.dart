import 'dart:io';

import 'package:automator/services/shell_service.dart';

class ServerService {
  ServerService._privateConstructor();

  static final ServerService _instance = ServerService._privateConstructor();

  factory ServerService() {
    return _instance;
  }

  int get port => 8554;
  ShellService shellService = ShellService();

  Stream<String>? _stream;
  Process? _process;
  Stream<String>? get stream => _stream;

  Future<ShellStreamResult> startServer() async {
    if (_process != null) {
      // Server is already running
      return ShellStreamResult(process: _process!, output: _stream!);
    }
    final result = await shellService.streamCommand(
      'bun',
      ['run', 'dev'],
      workingDirectory:
          '${Directory.current.path}${Platform.pathSeparator}server${Platform.pathSeparator}',
    );
    _stream = result.output;
    _process = result.process;

    return ShellStreamResult(process: _process!, output: _stream!);
  }

  void stopServer() {
    _process?.kill();
    _stream = null;
    _process = null;
  }
}
