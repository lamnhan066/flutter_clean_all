import 'dart:io';

import 'package:path/path.dart' as path;

import 'logger.dart';

class FlutterCleanAll {
  final Logger _logger;

  /// Create a FlutterCleanAll instance with optional custom logger
  FlutterCleanAll({Logger? logger}) : _logger = logger ?? Logger.instance;

  Future<void> cleanAll(
    String inputDir, {
    bool useFvm = false,
    bool dryRun = false,
  }) async {
    final directory = Directory(path.absolute(inputDir));

    if (!await directory.exists()) {
      _logger.error('The provided directory does not exist: $inputDir');
      return;
    }

    // Check if directory is readable before processing
    if (!await directory.stat().then((s) => s.mode & 0x4 != 0)) {
      _logger.error('Directory not accessible: ${directory.path}');
      return;
    }

    // Start scanning animation
    _logger.startAnimation(
      'Scanning for Flutter projects...',
      type: AnimationType.spinner,
    );

    final flutterProjects = await listFlutterDirectories(directory: directory);

    // Stop scanning animation
    _logger.stopAnimation();

    if (flutterProjects.isEmpty) {
      _logger.warning('No Flutter projects found in the specified directory.');
      return;
    }

    _logger.success('Found ${flutterProjects.length} Flutter project(s)');

    int cleanedCount = 0;
    for (var projectDir in flutterProjects) {
      try {
        // Show progress during cleaning
        _logger.showProgress(
          cleanedCount + 1,
          flutterProjects.length,
          'Cleaning ${path.basename(projectDir.path)}...',
        );

        await _flutterClean(
          directory: projectDir,
          useFvm: useFvm,
          dryRun: dryRun,
        );
        cleanedCount++;
      } catch (e) {
        _logger.error('Error cleaning project at ${projectDir.path}: $e');
      }
    }

    // Show animated success message
    _logger.animatedSuccess('Cleaned $cleanedCount Flutter project(s)!');
  }

  Future<void> _flutterClean({
    required Directory directory,
    required bool useFvm,
    required bool dryRun,
  }) async {
    // Verify flutter/fvm commands exist before execution
    final flutterExists = await Process.run('which', [
      useFvm ? 'fvm' : 'flutter',
    ]);
    if (flutterExists.exitCode != 0) {
      _logger.error('Flutter command not found');
      return;
    }

    final command = useFvm ? 'fvm flutter clean' : 'flutter clean';
    if (dryRun) {
      _logger.dryRun('Dry run: Would execute "$command" in ${directory.path}');
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
    _logger.success('Successfully ran "$command" in ${directory.path}');
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
