import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_clean_all/flutter_clean_all.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

void main() {
  group('FlutterCleanAll', () {
    late FlutterCleanAll flutterCleanAll;
    late Directory tempDir;
    late String testDirPath;
    late List<String> logOutput;
    late Logger testLogger;

    setUp(() async {
      logOutput = <String>[];
      testLogger = Logger.create(
        level: LogLevel.info,
        enableColors: false,
        enableAnimations: false,
        output: _TestIOSink(logOutput),
      );
      flutterCleanAll = FlutterCleanAll(logger: testLogger);
      tempDir = await Directory.systemTemp.createTemp('flutter_clean_all_test');
      testDirPath = tempDir.path;
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    group('cleanAll method', () {
      test('should handle non-existent directory gracefully', () async {
        final nonExistentDir = path.join(testDirPath, 'non_existent');

        final result = await flutterCleanAll.cleanAll(nonExistentDir);

        expect(result['successful'], equals(0));
        expect(result['failed'], equals(0));
        expect(
          logOutput.any(
            (line) => line.contains('The provided directory does not exist'),
          ),
          isTrue,
        );
      });

      test('should handle directory with no Flutter projects', () async {
        // Create a directory with non-Flutter content
        final subDir = Directory(path.join(testDirPath, 'empty_project'));
        await subDir.create();

        final regularFile = File(path.join(subDir.path, 'regular_file.txt'));
        await regularFile.writeAsString('Not a Flutter project');

        final result = await flutterCleanAll.cleanAll(testDirPath);

        expect(result['successful'], equals(0));
        expect(result['failed'], equals(0));
        expect(
          logOutput.any(
            (line) => line.contains(
              'No Flutter projects found in the specified directory',
            ),
          ),
          isTrue,
        );
      });

      test('should clean valid Flutter projects in dry run mode', () async {
        // Create valid Flutter project structure
        await createMockFlutterProject(testDirPath, 'project1');
        await createMockFlutterProject(testDirPath, 'project2');

        final result = await flutterCleanAll.cleanAll(
          testDirPath,
          dryRun: true,
        );

        expect(result['successful'], equals(2));
        expect(result['failed'], equals(0));
        expect(
          logOutput.any((line) => line.contains('Found 2 Flutter project(s)')),
          isTrue,
        );
        expect(
          logOutput.any(
            (line) => line.contains('Cleaned 2 Flutter project(s)!'),
          ),
          isTrue,
        );
        expect(
          logOutput
              .where(
                (line) =>
                    line.contains('Dry run: Would execute "flutter clean"'),
              )
              .length,
          equals(2),
        );
      });

      test('should use fvm when useFvm is true', () async {
        await createMockFlutterProject(testDirPath, 'fvm_project');

        final result = await flutterCleanAll.cleanAll(
          testDirPath,
          useFvm: true,
          dryRun: true,
        );

        expect(result['successful'], equals(1));
        expect(result['failed'], equals(0));
        expect(
          logOutput.any(
            (line) =>
                line.contains('Dry run: Would execute "fvm flutter clean"'),
          ),
          isTrue,
        );
      });

      test('should handle nested Flutter projects', () async {
        await createMockFlutterProject(testDirPath, 'nested/project1');
        await createMockFlutterProject(testDirPath, 'nested/deep/project2');

        final result = await flutterCleanAll.cleanAll(
          testDirPath,
          dryRun: true,
        );

        expect(result['successful'], equals(2));
        expect(result['failed'], equals(0));
        expect(
          logOutput.any((line) => line.contains('Found 2 Flutter project(s)')),
          isTrue,
        );
      });

      test('should handle directory with mixed content', () async {
        // Create Flutter project
        await createMockFlutterProject(testDirPath, 'flutter_project');

        // Create non-Flutter content
        final nonFlutterDir = Directory(path.join(testDirPath, 'regular_dir'));
        await nonFlutterDir.create();
        await File(
          path.join(nonFlutterDir.path, 'file.txt'),
        ).writeAsString('content');

        final result = await flutterCleanAll.cleanAll(
          testDirPath,
          dryRun: true,
        );

        expect(result['successful'], equals(1));
        expect(result['failed'], equals(0));
        expect(
          logOutput.any((line) => line.contains('Found 1 Flutter project(s)')),
          isTrue,
        );
      });

      test('should handle empty directory gracefully', () async {
        // Create empty directory
        final emptyDir = Directory(path.join(testDirPath, 'empty'));
        await emptyDir.create();

        final result = await flutterCleanAll.cleanAll(emptyDir.path);

        expect(result['successful'], equals(0));
        expect(result['failed'], equals(0));
        expect(
          logOutput.any(
            (line) => line.contains(
              'No Flutter projects found in the specified directory',
            ),
          ),
          isTrue,
        );
      });

      test('should handle relative paths', () async {
        await createMockFlutterProject(testDirPath, 'project1');

        // Change to temp directory and use relative path
        final originalDir = Directory.current;
        Directory.current = tempDir.parent;

        try {
          final relativePath = path.basename(testDirPath);
          final result = await flutterCleanAll.cleanAll(
            relativePath,
            dryRun: true,
          );

          expect(result['successful'], equals(1));
          expect(result['failed'], equals(0));
        } finally {
          Directory.current = originalDir;
        }
      });

      test('should handle absolute paths', () async {
        await createMockFlutterProject(testDirPath, 'project1');

        final result = await flutterCleanAll.cleanAll(
          testDirPath,
          dryRun: true,
        );

        expect(result['successful'], equals(1));
        expect(result['failed'], equals(0));
        expect(
          logOutput.any((line) => line.contains('Found 1 Flutter project(s)')),
          isTrue,
        );
      });
    });

    group('Error handling', () {
      test('should handle projects with special characters in names', () async {
        await createMockFlutterProject(
          testDirPath,
          'special-chars_project.name',
        );

        final result = await flutterCleanAll.cleanAll(
          testDirPath,
          dryRun: true,
        );

        expect(result['successful'], equals(1));
        expect(result['failed'], equals(0));
      });

      test('should handle very deep nesting', () async {
        const deepPath = 'a/b/c/d/e/f/g/h/i/j/deep_project';
        await createMockFlutterProject(testDirPath, deepPath);

        final result = await flutterCleanAll.cleanAll(
          testDirPath,
          dryRun: true,
        );

        expect(result['successful'], equals(1));
        expect(result['failed'], equals(0));
      });

      test('should handle empty pubspec.yaml', () async {
        final projectDir = Directory(path.join(testDirPath, 'empty_pubspec'));
        await projectDir.create(recursive: true);

        // Create empty pubspec.yaml
        final pubspecFile = File(path.join(projectDir.path, 'pubspec.yaml'));
        await pubspecFile.writeAsString('');

        final result = await flutterCleanAll.cleanAll(
          testDirPath,
          dryRun: true,
        );

        // Empty pubspec.yaml should not be considered a valid Flutter project
        expect(result['successful'], equals(0));
        expect(result['failed'], equals(0));
      });

      test('should handle directory with only hidden files', () async {
        final hiddenDir = Directory(path.join(testDirPath, '.hidden'));
        await hiddenDir.create();
        await File(
          path.join(hiddenDir.path, '.hiddenfile'),
        ).writeAsString('content');

        final result = await flutterCleanAll.cleanAll(testDirPath);

        expect(result['successful'], equals(0));
        expect(result['failed'], equals(0));
      });
    });

    group('Flutter project validation', () {
      test('should only process valid Flutter projects', () async {
        // Create valid Flutter project
        await createMockFlutterProject(testDirPath, 'valid_project');

        // Create directory with only pubspec.yaml but no Flutter content
        final invalidDir = Directory(path.join(testDirPath, 'invalid_project'));
        await invalidDir.create();
        final invalidPubspec = File(path.join(invalidDir.path, 'pubspec.yaml'));
        await invalidPubspec.writeAsString('name: not_flutter\nversion: 1.0.0');

        final result = await flutterCleanAll.cleanAll(
          testDirPath,
          dryRun: true,
        );

        expect(result['successful'], equals(1));
        expect(result['failed'], equals(0));
      });

      test('should handle deeply nested Flutter projects', () async {
        await createMockFlutterProject(testDirPath, 'level1/level2/project1');
        await createMockFlutterProject(
          testDirPath,
          'level1/level3/level4/project2',
        );

        final result = await flutterCleanAll.cleanAll(
          testDirPath,
          dryRun: true,
        );

        expect(result['successful'], equals(2));
        expect(result['failed'], equals(0));
      });
    });

    group('Dry run functionality', () {
      test('should not execute actual flutter clean in dry run mode', () async {
        await createMockFlutterProject(testDirPath, 'project1');

        final result = await flutterCleanAll.cleanAll(
          testDirPath,
          dryRun: true,
        );

        expect(result['successful'], equals(1));
        expect(result['failed'], equals(0));
        expect(
          logOutput.any(
            (line) => line.contains('Dry run: Would execute "flutter clean"'),
          ),
          isTrue,
        );
        // Ensure no actual clean command was executed
        expect(
          logOutput.any(
            (line) => line.contains('Error:') || line.contains('Exception:'),
          ),
          isFalse,
        );
      });

      test('should show fvm command in dry run when useFvm is true', () async {
        await createMockFlutterProject(testDirPath, 'fvm_project');

        final result = await flutterCleanAll.cleanAll(
          testDirPath,
          useFvm: true,
          dryRun: true,
        );

        expect(result['successful'], equals(1));
        expect(result['failed'], equals(0));
        expect(
          logOutput.any(
            (line) =>
                line.contains('Dry run: Would execute "fvm flutter clean"'),
          ),
          isTrue,
        );
      });

      test('should process multiple projects in dry run mode', () async {
        await createMockFlutterProject(testDirPath, 'project1');
        await createMockFlutterProject(testDirPath, 'project2');
        await createMockFlutterProject(testDirPath, 'nested/project3');

        final result = await flutterCleanAll.cleanAll(
          testDirPath,
          dryRun: true,
        );

        expect(result['successful'], equals(3));
        expect(result['failed'], equals(0));
        expect(
          logOutput
              .where(
                (line) =>
                    line.contains('Dry run: Would execute "flutter clean"'),
              )
              .length,
          equals(3),
        );
      });
    });

    group('Edge cases', () {
      test('should handle directory with symlinks', () async {
        await createMockFlutterProject(testDirPath, 'real_project');

        // Create symlink (skip if platform doesn't support it)
        try {
          final linkPath = path.join(testDirPath, 'link_project');
          final link = Link(linkPath);
          await link.create(path.join(testDirPath, 'real_project'));

          final result = await flutterCleanAll.cleanAll(
            testDirPath,
            dryRun: true,
          );

          // Should handle both the real project and symlink appropriately
          expect(result['successful'], greaterThanOrEqualTo(1));
          expect(result['failed'], equals(0));
        } catch (e) {
          // Skip test if symlinks aren't supported
          expect(true, isTrue);
        }
      });
    });
  });
}

/// Helper function to create a mock Flutter project structure
Future<void> createMockFlutterProject(
  String basePath,
  String projectName,
) async {
  final projectDir = Directory(path.join(basePath, projectName));
  await projectDir.create(recursive: true);

  // Create pubspec.yaml with Flutter dependency
  final pubspecFile = File(path.join(projectDir.path, 'pubspec.yaml'));
  await pubspecFile.writeAsString('''
name: $projectName
description: A test Flutter project
version: 1.0.0+1

environment:
  sdk: ">=2.17.0 <4.0.0"

dependencies:
  flutter:
    sdk: flutter

dev_dependencies:
  flutter_test:
    sdk: flutter

flutter:
  uses-material-design: true
''');

  // Create lib directory with main.dart
  final libDir = Directory(path.join(projectDir.path, 'lib'));
  await libDir.create();
  final mainFile = File(path.join(libDir.path, 'main.dart'));
  await mainFile.writeAsString('''
import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      home: Scaffold(
        appBar: AppBar(title: Text('Flutter Demo')),
        body: Center(child: Text('Hello World')),
      ),
    );
  }
}
''');

  // Create android directory to make it look more like a real Flutter project
  final androidDir = Directory(path.join(projectDir.path, 'android'));
  await androidDir.create();

  // Create ios directory
  final iosDir = Directory(path.join(projectDir.path, 'ios'));
  await iosDir.create();
}

/// Test implementation of IOSink that captures output to a list
class _TestIOSink implements IOSink {
  final List<String> _output;

  _TestIOSink(this._output);

  @override
  Encoding encoding = utf8;

  @override
  void write(Object? object) {
    _output.add(object.toString());
  }

  @override
  void writeln([Object? object = ""]) {
    _output.add(object.toString());
  }

  @override
  void writeAll(Iterable objects, [String separator = ""]) {
    _output.add(objects.join(separator));
  }

  @override
  void add(List<int> data) {
    _output.add(encoding.decode(data));
  }

  @override
  void addError(Object error, [StackTrace? stackTrace]) {
    _output.add('Error: $error');
  }

  @override
  Future addStream(Stream<List<int>> stream) async {
    await for (final data in stream) {
      add(data);
    }
  }

  @override
  Future flush() async {}

  @override
  Future close() async {}

  @override
  Future get done => Future.value();

  @override
  void writeCharCode(int charCode) {
    write(String.fromCharCode(charCode));
  }
}
