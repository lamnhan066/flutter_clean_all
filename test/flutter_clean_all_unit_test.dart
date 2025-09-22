import 'dart:io';

import 'package:flutter_clean_all/flutter_clean_all.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

void main() {
  group('FlutterCleanAll Unit Tests', () {
    late FlutterCleanAll flutterCleanAll;
    late Directory tempDir;
    late String testDirPath;

    setUp(() async {
      flutterCleanAll = FlutterCleanAll();
      tempDir = await Directory.systemTemp.createTemp(
        'flutter_clean_all_unit_test',
      );
      testDirPath = tempDir.path;
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    group('validateProject', () {
      test('should return true for valid Flutter project', () async {
        final projectDir = Directory(path.join(testDirPath, 'valid_project'));
        await projectDir.create();

        // Create pubspec.yaml
        final pubspecFile = File(path.join(projectDir.path, 'pubspec.yaml'));
        await pubspecFile.writeAsString('name: valid_project\n');

        // Create lib directory
        final libDir = Directory(path.join(projectDir.path, 'lib'));
        await libDir.create();

        final result = await flutterCleanAll.validateProject(
          directory: projectDir,
        );
        expect(result, isTrue);
      });

      test('should return false for project without pubspec.yaml', () async {
        final projectDir = Directory(path.join(testDirPath, 'no_pubspec'));
        await projectDir.create();

        // Create lib directory only
        final libDir = Directory(path.join(projectDir.path, 'lib'));
        await libDir.create();

        final result = await flutterCleanAll.validateProject(
          directory: projectDir,
        );
        expect(result, isFalse);
      });

      test('should return false for project without lib directory', () async {
        final projectDir = Directory(path.join(testDirPath, 'no_lib'));
        await projectDir.create();

        // Create pubspec.yaml only
        final pubspecFile = File(path.join(projectDir.path, 'pubspec.yaml'));
        await pubspecFile.writeAsString('name: no_lib\n');

        final result = await flutterCleanAll.validateProject(
          directory: projectDir,
        );
        expect(result, isFalse);
      });

      test('should return false for empty directory', () async {
        final projectDir = Directory(path.join(testDirPath, 'empty'));
        await projectDir.create();

        final result = await flutterCleanAll.validateProject(
          directory: projectDir,
        );
        expect(result, isFalse);
      });

      test(
        'should return true for project with additional Flutter files',
        () async {
          final projectDir = Directory(
            path.join(testDirPath, 'flutter_project'),
          );
          await projectDir.create();

          // Create pubspec.yaml
          final pubspecFile = File(path.join(projectDir.path, 'pubspec.yaml'));
          await pubspecFile.writeAsString('''
name: flutter_project
description: A Flutter project

dependencies:
  flutter:
    sdk: flutter
''');

          // Create lib directory with main.dart
          final libDir = Directory(path.join(projectDir.path, 'lib'));
          await libDir.create();
          final mainFile = File(path.join(libDir.path, 'main.dart'));
          await mainFile.writeAsString('void main() {}');

          // Create additional Flutter directories
          final testDir = Directory(path.join(projectDir.path, 'test'));
          await testDir.create();

          final androidDir = Directory(path.join(projectDir.path, 'android'));
          await androidDir.create();

          final iosDir = Directory(path.join(projectDir.path, 'ios'));
          await iosDir.create();

          final result = await flutterCleanAll.validateProject(
            directory: projectDir,
          );
          expect(result, isTrue);
        },
      );
    });

    group('listFlutterDirectories', () {
      test(
        'should return empty list for directory with no Flutter projects',
        () async {
          final result = await flutterCleanAll.listFlutterDirectories(
            directory: Directory(testDirPath),
          );
          expect(result, isEmpty);
        },
      );

      test('should find single Flutter project', () async {
        await createValidFlutterProject(testDirPath, 'single_project');

        final result = await flutterCleanAll.listFlutterDirectories(
          directory: Directory(testDirPath),
        );

        expect(result.length, equals(1));
        expect(result.first.path.contains('single_project'), isTrue);
      });

      test('should find multiple Flutter projects at same level', () async {
        await createValidFlutterProject(testDirPath, 'project1');
        await createValidFlutterProject(testDirPath, 'project2');
        await createValidFlutterProject(testDirPath, 'project3');

        final result = await flutterCleanAll.listFlutterDirectories(
          directory: Directory(testDirPath),
        );

        expect(result.length, equals(3));
        expect(result.any((dir) => dir.path.contains('project1')), isTrue);
        expect(result.any((dir) => dir.path.contains('project2')), isTrue);
        expect(result.any((dir) => dir.path.contains('project3')), isTrue);
      });

      test('should find nested Flutter projects', () async {
        await createValidFlutterProject(testDirPath, 'parent');
        await createValidFlutterProject(
          path.join(testDirPath, 'parent'),
          'child',
        );
        await createValidFlutterProject(
          path.join(testDirPath, 'parent', 'child'),
          'grandchild',
        );

        final result = await flutterCleanAll.listFlutterDirectories(
          directory: Directory(testDirPath),
        );

        expect(result.length, equals(3));
        expect(
          result.any(
            (dir) => dir.path.contains('parent') && !dir.path.contains('child'),
          ),
          isTrue,
        );
        expect(
          result.any(
            (dir) =>
                dir.path.contains('child') && !dir.path.contains('grandchild'),
          ),
          isTrue,
        );
        expect(result.any((dir) => dir.path.contains('grandchild')), isTrue);
      });

      test('should ignore non-Flutter directories', () async {
        await createValidFlutterProject(testDirPath, 'flutter_project');

        // Create non-Flutter directories
        final regularDir = Directory(path.join(testDirPath, 'regular_dir'));
        await regularDir.create();

        final onlyPubspecDir = Directory(
          path.join(testDirPath, 'only_pubspec'),
        );
        await onlyPubspecDir.create();
        await File(
          path.join(onlyPubspecDir.path, 'pubspec.yaml'),
        ).writeAsString('name: only_pubspec');

        final onlyLibDir = Directory(path.join(testDirPath, 'only_lib'));
        await onlyLibDir.create();
        await Directory(path.join(onlyLibDir.path, 'lib')).create();

        final result = await flutterCleanAll.listFlutterDirectories(
          directory: Directory(testDirPath),
        );

        expect(result.length, equals(1));
        expect(result.first.path.contains('flutter_project'), isTrue);
      });

      test('should handle directory with mixed content types', () async {
        await createValidFlutterProject(testDirPath, 'flutter_app');

        // Create regular files
        await File(
          path.join(testDirPath, 'readme.txt'),
        ).writeAsString('readme');
        await File(path.join(testDirPath, 'config.json')).writeAsString('{}');

        // Create empty directory
        await Directory(path.join(testDirPath, 'empty_dir')).create();

        // Create directory with files but not Flutter project
        final dataDir = Directory(path.join(testDirPath, 'data'));
        await dataDir.create();
        await File(
          path.join(dataDir.path, 'data.csv'),
        ).writeAsString('csv,data');

        final result = await flutterCleanAll.listFlutterDirectories(
          directory: Directory(testDirPath),
        );

        expect(result.length, equals(1));
        expect(result.first.path.contains('flutter_app'), isTrue);
      });
    });

    group('edge case validation', () {
      test('should handle pubspec.yaml with different content types', () async {
        final testCases = [
          'name: test_project',
          'name: test_project\ndescription: A test project',
          '# Comment only pubspec',
          'invalid: yaml: content:',
          '', // empty file
        ];

        for (int i = 0; i < testCases.length; i++) {
          final projectDir = Directory(path.join(testDirPath, 'test_$i'));
          await projectDir.create();

          // Create pubspec.yaml with test content
          final pubspecFile = File(path.join(projectDir.path, 'pubspec.yaml'));
          await pubspecFile.writeAsString(testCases[i]);

          // Create lib directory
          final libDir = Directory(path.join(projectDir.path, 'lib'));
          await libDir.create();

          final result = await flutterCleanAll.validateProject(
            directory: projectDir,
          );
          expect(
            result,
            isTrue,
            reason: 'Failed for test case $i: "${testCases[i]}"',
          );

          // Clean up for next iteration
          await projectDir.delete(recursive: true);
        }
      });

      test('should handle lib directory with various contents', () async {
        final projectDir = Directory(
          path.join(testDirPath, 'lib_content_test'),
        );
        await projectDir.create();

        // Create pubspec.yaml
        final pubspecFile = File(path.join(projectDir.path, 'pubspec.yaml'));
        await pubspecFile.writeAsString('name: lib_content_test');

        // Create lib directory with various content
        final libDir = Directory(path.join(projectDir.path, 'lib'));
        await libDir.create();

        // Add some files to lib
        await File(
          path.join(libDir.path, 'main.dart'),
        ).writeAsString('void main() {}');
        await File(
          path.join(libDir.path, 'utils.dart'),
        ).writeAsString('class Utils {}');

        // Add subdirectory in lib
        final modelsDir = Directory(path.join(libDir.path, 'models'));
        await modelsDir.create();
        await File(
          path.join(modelsDir.path, 'user.dart'),
        ).writeAsString('class User {}');

        final result = await flutterCleanAll.validateProject(
          directory: projectDir,
        );
        expect(result, isTrue);
      });
    });
  });
}

/// Helper function to create a valid Flutter project for unit testing
Future<void> createValidFlutterProject(
  String basePath,
  String projectName,
) async {
  final projectDir = Directory(path.join(basePath, projectName));
  await projectDir.create(recursive: true);

  // Create pubspec.yaml
  final pubspecFile = File(path.join(projectDir.path, 'pubspec.yaml'));
  await pubspecFile.writeAsString(
    'name: $projectName\ndescription: A test Flutter project\n',
  );

  // Create lib directory
  final libDir = Directory(path.join(projectDir.path, 'lib'));
  await libDir.create();
}
