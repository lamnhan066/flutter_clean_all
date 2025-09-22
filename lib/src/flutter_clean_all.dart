import 'dart:io';

import 'package:path/path.dart' as path;

class FlutterCleanAll {
  Future<void> cleanAll(
    String inputDir, {
    bool useFvm = false,
    bool dryRun = false,
  }) async {
    final directory = Directory(path.absolute(inputDir));

    if (!await directory.exists()) {
      print('The provided directory does not exist: $inputDir');
      return;
    }

    final flutterProjects = await listFlutterDirectories(directory: directory);

    if (flutterProjects.isEmpty) {
      print('No Flutter projects found in the specified directory.');
      return;
    }

    int cleanedCount = 0;
    for (var projectDir in flutterProjects) {
      try {
        await _flutterClean(
          directory: projectDir,
          useFvm: useFvm,
          dryRun: dryRun,
        );
      } catch (e) {
        print('Error cleaning project at ${projectDir.path}: $e');
      }
      cleanedCount++;
    }

    print('Cleaned $cleanedCount Flutter project(s).');
  }

  Future<void> _flutterClean({
    required Directory directory,
    required bool useFvm,
    required bool dryRun,
  }) async {
    final command = useFvm ? 'fvm flutter clean' : 'flutter clean';
    if (dryRun) {
      print('Dry run: Would execute "$command" in ${directory.path}');
      return;
    }
    final result = await Process.run(useFvm ? 'fvm flutter' : 'flutter', [
      'clean',
    ], workingDirectory: directory.path);
    if (result.exitCode != 0) {
      throw Exception(
        'Failed to run "$command" in ${directory.path}: ${result.stderr}',
      );
    }
    print('Successfully ran "$command" in ${directory.path}');
  }

  Future<List<Directory>> listFlutterDirectories({
    required Directory directory,
  }) async {
    final subDirectories = <Directory>[];

    await for (var entity in directory.list(
      recursive: true,
      followLinks: false,
    )) {
      if (entity is Directory && await validateProject(directory: entity)) {
        subDirectories.add(entity);
      }
    }

    return subDirectories;
  }

  Future<bool> validateProject({required Directory directory}) async {
    final pubspecFile = File('${directory.path}/pubspec.yaml');
    final libDir = Directory('${directory.path}/lib');
    bool pubspecFileExists = await pubspecFile.exists();
    bool libDirExists = await libDir.exists();
    return pubspecFileExists && libDirExists;
  }
}
