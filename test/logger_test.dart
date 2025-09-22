import 'dart:convert';
import 'dart:io';

import 'package:flutter_clean_all/flutter_clean_all.dart';
import 'package:test/test.dart';

void main() {
  group('Logger', () {
    late List<String> capturedOutput;
    late IOSink testSink;

    setUp(() {
      capturedOutput = <String>[];
      testSink = _TestIOSink(capturedOutput);
    });

    group('log levels', () {
      test('should respect log level filtering', () {
        final logger = Logger.create(
          level: LogLevel.warning,
          enableColors: false,
          enableAnimations: false,
          output: testSink,
        );

        logger.debug('Debug message');
        logger.info('Info message');
        logger.warning('Warning message');
        logger.error('Error message');

        expect(capturedOutput.length, equals(2));
        expect(capturedOutput[0], contains('Warning message'));
        expect(capturedOutput[1], contains('Error message'));
      });

      test('should log all messages when level is debug', () {
        final logger = Logger.create(
          level: LogLevel.debug,
          enableColors: false,
          enableAnimations: false,
          output: testSink,
        );

        logger.debug('Debug message');
        logger.info('Info message');
        logger.warning('Warning message');
        logger.error('Error message');

        expect(capturedOutput.length, equals(4));
        expect(capturedOutput[0], contains('Debug message'));
        expect(capturedOutput[1], contains('Info message'));
        expect(capturedOutput[2], contains('Warning message'));
        expect(capturedOutput[3], contains('Error message'));
      });
    });

    group('color formatting', () {
      test('should not add colors when disabled', () {
        final logger = Logger.create(
          level: LogLevel.debug,
          enableColors: false,
          enableAnimations: false,
          output: testSink,
        );

        logger.debug('Debug message');
        logger.info('Info message');
        logger.warning('Warning message');
        logger.error('Error message');

        for (final output in capturedOutput) {
          expect(output, isNot(contains('\x1B')));
        }
      });

      test('should add colors when enabled', () {
        final logger = Logger.create(
          level: LogLevel.debug,
          enableColors: true,
          enableAnimations: false,
          output: testSink,
        );

        logger.debug('Debug message');
        logger.warning('Warning message');
        logger.error('Error message');

        expect(capturedOutput[0], contains('\x1B[90m')); // Debug - Gray
        expect(capturedOutput[1], contains('\x1B[33m')); // Warning - Yellow
        expect(capturedOutput[2], contains('\x1B[31m')); // Error - Red
      });
    });

    group('special message types', () {
      test('should format success messages with green color', () {
        final logger = Logger.create(
          level: LogLevel.info,
          enableColors: true,
          enableAnimations: false,
          output: testSink,
        );

        logger.success('Success message');

        expect(capturedOutput.length, equals(1));
        expect(capturedOutput[0], contains('\x1B[32m')); // Green
        expect(capturedOutput[0], contains('Success message'));
      });

      test('should format dry run messages with cyan color', () {
        final logger = Logger.create(
          level: LogLevel.info,
          enableColors: true,
          enableAnimations: false,
          output: testSink,
        );

        logger.dryRun('Dry run message');

        expect(capturedOutput.length, equals(1));
        expect(capturedOutput[0], contains('\x1B[36m')); // Cyan
        expect(capturedOutput[0], contains('Dry run message'));
      });

      test('should add new lines', () {
        final logger = Logger.create(
          level: LogLevel.info,
          enableColors: false,
          enableAnimations: false,
          output: testSink,
        );

        logger.info('First message');
        logger.newLine();
        logger.info('Second message');

        expect(capturedOutput.length, equals(3));
        expect(capturedOutput[0], contains('First message'));
        expect(capturedOutput[1], equals(''));
        expect(capturedOutput[2], contains('Second message'));
      });
    });

    group('configuration', () {
      test('should allow changing log level dynamically', () {
        final logger = Logger.create(
          level: LogLevel.error,
          enableColors: false,
          enableAnimations: false,
          output: testSink,
        );

        logger.info('Should not appear');
        logger.setLevel(LogLevel.info);
        logger.info('Should appear');

        expect(capturedOutput.length, equals(1));
        expect(capturedOutput[0], contains('Should appear'));
      });

      test('should allow toggling colors dynamically', () {
        final logger = Logger.create(
          level: LogLevel.info,
          enableColors: false,
          enableAnimations: false,
          output: testSink,
        );

        logger.error('No color');
        logger.setColorEnabled(true);
        logger.error('With color');

        expect(capturedOutput.length, equals(2));
        expect(capturedOutput[0], isNot(contains('\x1B')));
        expect(capturedOutput[1], contains('\x1B[31m')); // Red
      });
    });

    group('singleton instance', () {
      test('should return the same instance', () {
        final logger1 = Logger.instance;
        final logger2 = Logger.instance;

        expect(identical(logger1, logger2), isTrue);
      });
    });

    group('integration with FlutterCleanAll', () {
      test('should use custom logger when provided', () {
        final logger = Logger.create(
          level: LogLevel.info,
          enableColors: false,
          enableAnimations: false,
          output: testSink,
        );

        final flutterCleanAll = FlutterCleanAll(logger: logger);

        // This should be verifiable by checking the logger is being used
        expect(flutterCleanAll, isNotNull);
      });

      test('should use default logger when none provided', () {
        final flutterCleanAll = FlutterCleanAll();

        expect(flutterCleanAll, isNotNull);
      });
    });
  });
}

/// Test implementation of IOSink for capturing output
class _TestIOSink implements IOSink {
  final List<String> _capturedOutput;

  _TestIOSink(this._capturedOutput);

  @override
  void writeln([Object? obj = '']) {
    _capturedOutput.add(obj.toString());
  }

  @override
  void write(Object? obj) {
    if (_capturedOutput.isEmpty) {
      _capturedOutput.add(obj.toString());
    } else {
      _capturedOutput[_capturedOutput.length - 1] += obj.toString();
    }
  }

  // Implement other required methods as no-ops for testing
  @override
  void writeAll(Iterable objects, [String separator = '']) {}

  @override
  void writeCharCode(int charCode) {}

  @override
  void add(List<int> data) {}

  @override
  void addError(Object error, [StackTrace? stackTrace]) {}

  @override
  Future addStream(Stream<List<int>> stream) async {}

  @override
  Future close() async {}

  @override
  Future get done => Future.value();

  @override
  Encoding get encoding => utf8;

  @override
  set encoding(Encoding encoding) {}

  @override
  Future flush() async {}
}
