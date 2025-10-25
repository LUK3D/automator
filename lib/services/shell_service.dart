import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';

/// Result object containing the running process and its output stream.
class ShellStreamResult {
  final Process process;
  final Stream<String> output;

  ShellStreamResult({required this.process, required this.output});

  /// Kill the process gracefully.
  Future<void> kill([ProcessSignal signal = ProcessSignal.sigterm]) async {
    process.kill(signal);
  }
}

class ShellService {
  ShellService._privateConstructor();
  static final ShellService _instance = ShellService._privateConstructor();
  factory ShellService() => _instance;

  /// Runs a command and waits for completion (non-streaming).
  Future<ProcessResult> runCommand(
    String command,
    List<String> arguments, {
    String? workingDirectory,
  }) async {
    if (kDebugMode) {
      print('Running command: $command ${arguments.join(' ')}');
    }
    return await Process.run(
      command,
      arguments,
      workingDirectory: workingDirectory,
      includeParentEnvironment: true,
      runInShell: true,
    );
  }

  /// Runs a command and returns both the process and its live output stream.
  Future<ShellStreamResult> streamCommand(
    String command,
    List<String> arguments, {
    String? workingDirectory,
  }) async {
    if (kDebugMode) {
      print('Streaming command: $command ${arguments.join(' ')}');
    }

    final process = await Process.start(
      command,
      arguments,
      mode: ProcessStartMode.normal,
      runInShell: true,
      workingDirectory: workingDirectory,
      includeParentEnvironment: true,
    );

    final stdoutStream = process.stdout
        .transform(utf8.decoder)
        .transform(const LineSplitter());
    final stderrStream = process.stderr
        .transform(utf8.decoder)
        .transform(const LineSplitter());

    final mergedStream = StreamGroup.merge([
      stdoutStream,
      stderrStream,
    ]).transform(_ExitCodeInjector(process));

    return ShellStreamResult(process: process, output: mergedStream);
  }
}

/// Utility for merging multiple streams
class StreamGroup<T> {
  static Stream<T> merge<T>(List<Stream<T>> streams) {
    final controller = StreamController<T>();
    var completed = 0;

    for (final stream in streams) {
      stream.listen(
        controller.add,
        onError: controller.addError,
        onDone: () {
          completed++;
          if (completed == streams.length) controller.close();
        },
      );
    }

    return controller.stream;
  }
}

/// Injects a line with the process exit code when it finishes.
class _ExitCodeInjector extends StreamTransformerBase<String, String> {
  final Process process;
  _ExitCodeInjector(this.process);

  @override
  Stream<String> bind(Stream<String> stream) async* {
    yield* stream;
    final code = await process.exitCode;
    if (code != 0) yield 'Process exited with code $code';
  }
}
