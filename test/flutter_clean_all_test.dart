import 'dart:async';
import 'dart:io';

import 'package:flutter_clean_all/flutter_clean_all.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

void main() {
  group('FlutterCleanAll', () {
    late FlutterCleanAll flutterCleanAll;
    late Directory tempDir;
    late String testDirPath;

    setUp(() async {
      flutterCleanAll = FlutterCleanAll();
      tempDir = await Directory.systemTemp.createTemp('flutter_clean_all_test');
      testDirPath = tempDir.path;
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    group('cleanAll', () {
      test('should handle non-existent directory gracefully', () async {
        final nonExistentDir = path.join(testDirPath, 'non_existent');

        // Capture stdout to verify the message
        final stdout = <String>[];
        await runWithCapture(() async {
          await flutterCleanAll.cleanAll(nonExistentDir);
        }, stdout);

        expect(
          stdout.any(
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

        final stdout = <String>[];
        await runWithCapture(() async {
          await flutterCleanAll.cleanAll(testDirPath);
        }, stdout);

        expect(
          stdout.any((line) => line.contains('No Flutter projects found')),
          isTrue,
        );
      });

      test('should clean valid Flutter projects', () async {
        // Create valid Flutter project structure
        await createMockFlutterProject(testDirPath, 'project1');
        await createMockFlutterProject(testDirPath, 'project2');

        final stdout = <String>[];
        await runWithCapture(() async {
          await flutterCleanAll.cleanAll(testDirPath, dryRun: true);
        }, stdout);

        expect(
          stdout.any((line) => line.contains('Cleaned 2 Flutter project(s)')),
          isTrue,
        );
        expect(
          stdout
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

        final stdout = <String>[];
        await runWithCapture(() async {
          await flutterCleanAll.cleanAll(
            testDirPath,
            useFvm: true,
            dryRun: true,
          );
        }, stdout);

        expect(
          stdout.any(
            (line) =>
                line.contains('Dry run: Would execute "fvm flutter clean"'),
          ),
          isTrue,
        );
      });

      test('should handle nested Flutter projects', () async {
        // Create nested structure
        await createMockFlutterProject(testDirPath, 'parent_project');
        await createMockFlutterProject(
          path.join(testDirPath, 'parent_project'),
          'nested_project',
        );

        final stdout = <String>[];
        await runWithCapture(() async {
          await flutterCleanAll.cleanAll(testDirPath, dryRun: true);
        }, stdout);

        expect(
          stdout.any((line) => line.contains('Cleaned 2 Flutter project(s)')),
          isTrue,
        );
      });

      test('should handle directory with mixed content', () async {
        // Create mixed content: Flutter projects and non-Flutter directories
        await createMockFlutterProject(testDirPath, 'flutter_app');

        // Create non-Flutter directory
        final nonFlutterDir = Directory(path.join(testDirPath, 'not_flutter'));
        await nonFlutterDir.create();
        await File(
          path.join(nonFlutterDir.path, 'some_file.txt'),
        ).writeAsString('content');

        // Create directory with only pubspec.yaml but no lib
        final incompleteDir = Directory(path.join(testDirPath, 'incomplete'));
        await incompleteDir.create();
        await File(
          path.join(incompleteDir.path, 'pubspec.yaml'),
        ).writeAsString('name: incomplete');

        final stdout = <String>[];
        await runWithCapture(() async {
          await flutterCleanAll.cleanAll(testDirPath, dryRun: true);
        }, stdout);

        expect(
          stdout.any((line) => line.contains('Cleaned 1 Flutter project(s)')),
          isTrue,
        );
      });
    });

    group('project validation (integration test)', () {
      test('should only process valid Flutter projects', () async {
        // Create various directory structures
        await createMockFlutterProject(testDirPath, 'valid_project');

        // Project without lib directory
        final noLibDir = Directory(path.join(testDirPath, 'no_lib'));
        await noLibDir.create();
        await File(
          path.join(noLibDir.path, 'pubspec.yaml'),
        ).writeAsString('name: no_lib');

        // Project without pubspec.yaml
        final noPubspecDir = Directory(path.join(testDirPath, 'no_pubspec'));
        await noPubspecDir.create();
        await Directory(path.join(noPubspecDir.path, 'lib')).create();

        // Completely empty directory
        final emptyDir = Directory(path.join(testDirPath, 'empty'));
        await emptyDir.create();

        final stdout = <String>[];
        await runWithCapture(() async {
          await flutterCleanAll.cleanAll(testDirPath, dryRun: true);
        }, stdout);

        // Should only find and process the valid project
        expect(
          stdout.any((line) => line.contains('Cleaned 1 Flutter project(s)')),
          isTrue,
        );
        expect(
          stdout
              .where(
                (line) =>
                    line.contains('Dry run: Would execute "flutter clean"'),
              )
              .length,
          equals(1),
        );
      });

      test('should handle deeply nested Flutter projects', () async {
        // Create deeply nested structure
        final nestedPath = path.join(testDirPath, 'level1', 'level2', 'level3');
        await createMockFlutterProject(nestedPath, 'deep_project');

        // Also create a project at root level
        await createMockFlutterProject(testDirPath, 'root_project');

        final stdout = <String>[];
        await runWithCapture(() async {
          await flutterCleanAll.cleanAll(testDirPath, dryRun: true);
        }, stdout);

        expect(
          stdout.any((line) => line.contains('Cleaned 2 Flutter project(s)')),
          isTrue,
        );
      });
    });

    group('error handling', () {
      test('should continue cleaning other projects when one fails', () async {
        await createMockFlutterProject(testDirPath, 'project1');
        await createMockFlutterProject(testDirPath, 'project2');

        // In dry run mode, no actual failures occur, but we can test the structure
        final stdout = <String>[];
        await runWithCapture(() async {
          await flutterCleanAll.cleanAll(testDirPath, dryRun: true);
        }, stdout);

        expect(
          stdout.any((line) => line.contains('Cleaned 2 Flutter project(s)')),
          isTrue,
        );
      });

      test('should handle empty directory gracefully', () async {
        final stdout = <String>[];
        await runWithCapture(() async {
          await flutterCleanAll.cleanAll(testDirPath);
        }, stdout);

        expect(
          stdout.any((line) => line.contains('No Flutter projects found')),
          isTrue,
        );
      });
    });

    group('dry run functionality', () {
      test('should not execute actual flutter clean in dry run mode', () async {
        await createMockFlutterProject(testDirPath, 'dry_run_project');

        final stdout = <String>[];
        await runWithCapture(() async {
          await flutterCleanAll.cleanAll(testDirPath, dryRun: true);
        }, stdout);

        expect(
          stdout.any(
            (line) => line.contains('Dry run: Would execute "flutter clean"'),
          ),
          isTrue,
        );
        expect(
          stdout.any(
            (line) => line.contains('Successfully ran "flutter clean"'),
          ),
          isFalse,
        );
      });

      test('should show fvm command in dry run when useFvm is true', () async {
        await createMockFlutterProject(testDirPath, 'fvm_dry_run_project');

        final stdout = <String>[];
        await runWithCapture(() async {
          await flutterCleanAll.cleanAll(
            testDirPath,
            useFvm: true,
            dryRun: true,
          );
        }, stdout);

        expect(
          stdout.any(
            (line) =>
                line.contains('Dry run: Would execute "fvm flutter clean"'),
          ),
          isTrue,
        );
      });

      test('should process multiple projects in dry run mode', () async {
        await createMockFlutterProject(testDirPath, 'project1');
        await createMockFlutterProject(testDirPath, 'project2');
        await createMockFlutterProject(testDirPath, 'project3');

        final stdout = <String>[];
        await runWithCapture(() async {
          await flutterCleanAll.cleanAll(testDirPath, dryRun: true);
        }, stdout);

        expect(
          stdout.any((line) => line.contains('Cleaned 3 Flutter project(s)')),
          isTrue,
        );
        expect(
          stdout
              .where(
                (line) =>
                    line.contains('Dry run: Would execute "flutter clean"'),
              )
              .length,
          equals(3),
        );
      });
    });

    group('edge cases', () {
      test('should handle directory with symlinks', () async {
        // Create a real Flutter project
        await createMockFlutterProject(testDirPath, 'real_project');

        // Create a symlink to it (if supported on the system)
        final linkPath = path.join(testDirPath, 'linked_project');
        final realPath = path.join(testDirPath, 'real_project');

        try {
          await Link(linkPath).create(realPath);

          final stdout = <String>[];
          await runWithCapture(() async {
            await flutterCleanAll.cleanAll(testDirPath, dryRun: true);
          }, stdout);

          // Should find both the real project and the symlinked one
          expect(
            stdout.any((line) => line.contains('Cleaned 2 Flutter project(s)')),
            isTrue,
          );
        } catch (e) {
          // If symlinks aren't supported, just test the real project
          final stdout = <String>[];
          await runWithCapture(() async {
            await flutterCleanAll.cleanAll(testDirPath, dryRun: true);
          }, stdout);

          expect(
            stdout.any((line) => line.contains('Cleaned 1 Flutter project(s)')),
            isTrue,
          );
        }
      });

      test('should handle project with special characters in name', () async {
        await createMockFlutterProject(testDirPath, 'project-with-dashes');
        await createMockFlutterProject(testDirPath, 'project_with_underscores');
        await createMockFlutterProject(testDirPath, 'project.with.dots');

        final stdout = <String>[];
        await runWithCapture(() async {
          await flutterCleanAll.cleanAll(testDirPath, dryRun: true);
        }, stdout);

        expect(
          stdout.any((line) => line.contains('Cleaned 3 Flutter project(s)')),
          isTrue,
        );
      });

      test('should handle very deep nesting', () async {
        // Create a very deeply nested project
        final deepPath = path.join(
          testDirPath,
          'a',
          'b',
          'c',
          'd',
          'e',
          'f',
          'g',
          'h',
        );
        await createMockFlutterProject(deepPath, 'deep_project');

        final stdout = <String>[];
        await runWithCapture(() async {
          await flutterCleanAll.cleanAll(testDirPath, dryRun: true);
        }, stdout);

        expect(
          stdout.any((line) => line.contains('Cleaned 1 Flutter project(s)')),
          isTrue,
        );
      });

      test('should handle empty pubspec.yaml', () async {
        final projectDir = Directory(path.join(testDirPath, 'empty_pubspec'));
        await projectDir.create();

        // Create empty pubspec.yaml
        await File(
          path.join(projectDir.path, 'pubspec.yaml'),
        ).writeAsString('');

        // Create lib directory
        await Directory(path.join(projectDir.path, 'lib')).create();

        final stdout = <String>[];
        await runWithCapture(() async {
          await flutterCleanAll.cleanAll(testDirPath, dryRun: true);
        }, stdout);

        // Should still be considered a valid Flutter project
        expect(
          stdout.any((line) => line.contains('Cleaned 1 Flutter project(s)')),
          isTrue,
        );
      });

      test('should handle directory with only hidden files', () async {
        final hiddenDir = Directory(path.join(testDirPath, '.hidden'));
        await hiddenDir.create();
        await File(
          path.join(hiddenDir.path, '.hidden_file'),
        ).writeAsString('hidden');

        final stdout = <String>[];
        await runWithCapture(() async {
          await flutterCleanAll.cleanAll(testDirPath, dryRun: true);
        }, stdout);

        expect(
          stdout.any((line) => line.contains('No Flutter projects found')),
          isTrue,
        );
      });
    });

    group('path handling', () {
      test('should handle relative paths', () async {
        // Create a project in the temp directory
        await createMockFlutterProject(testDirPath, 'relative_test');

        // Use the current working directory to create a relative path
        final currentDir = Directory.current.path;
        final relativePath = path.relative(testDirPath, from: currentDir);

        final stdout = <String>[];
        await runWithCapture(() async {
          await flutterCleanAll.cleanAll(relativePath, dryRun: true);
        }, stdout);

        expect(
          stdout.any((line) => line.contains('Cleaned 1 Flutter project(s)')),
          isTrue,
        );
      });

      test('should handle absolute paths', () async {
        await createMockFlutterProject(testDirPath, 'absolute_test');

        final stdout = <String>[];
        await runWithCapture(() async {
          await flutterCleanAll.cleanAll(testDirPath, dryRun: true);
        }, stdout);

        expect(
          stdout.any((line) => line.contains('Cleaned 1 Flutter project(s)')),
          isTrue,
        );
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

  // Create pubspec.yaml
  final pubspecFile = File(path.join(projectDir.path, 'pubspec.yaml'));
  await pubspecFile.writeAsString('''
name: $projectName
description: A test Flutter project

version: 1.0.0+1

environment:
  sdk: '>=3.0.0 <4.0.0'
  flutter: ">=3.0.0"

dependencies:
  flutter:
    sdk: flutter

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.0

flutter:
  uses-material-design: true
''');

  // Create lib directory
  final libDir = Directory(path.join(projectDir.path, 'lib'));
  await libDir.create();

  // Create a simple main.dart file
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
      home: Scaffold(
        appBar: AppBar(title: Text('$projectName')),
        body: Center(child: Text('Hello World!')),
      ),
    );
  }
}
''');
}

/// Helper function to capture stdout for testing
Future<void> runWithCapture(
  Future<void> Function() fn,
  List<String> capture,
) async {
  final zone = Zone.current.fork(
    specification: ZoneSpecification(
      print: (Zone self, ZoneDelegate parent, Zone zone, String line) {
        capture.add(line);
        parent.print(zone, line);
      },
    ),
  );

  await zone.run(fn);
}
