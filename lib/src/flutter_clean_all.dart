import 'dart:io';

import 'package:path/path.dart' as path;

import 'logger.dart';

class FlutterCleanAll {
  final Logger _logger;

  /// Create a FlutterCleanAll instance with optional custom logger
  FlutterCleanAll({Logger? logger}) : _logger = logger ?? Logger.instance;

  /// Clean all Flutter projects in the specified directory
  /// Returns a map with 'successful' and 'failed' counts
  Future<Map<String, int>> cleanAll(
    String inputDir, {
    bool useFvm = false,
    bool dryRun = false,
  }) async {
    try {
      final directory = Directory(path.absolute(inputDir));

      if (!await directory.exists()) {
        _logger.error('The provided directory does not exist: $inputDir');
        return {'successful': 0, 'failed': 0};
      }

      // Security check: Ensure it's actually a directory and not a file
      final stat = await directory.stat();
      if (stat.type != FileSystemEntityType.directory) {
        _logger.error('Path is not a directory: $inputDir');
        return {'successful': 0, 'failed': 0};
      }

      // Start scanning animation
      _logger.startAnimation(
        'Scanning for Flutter projects...',
        type: AnimationType.spinner,
      );

      final flutterProjects = await listFlutterDirectories(
        directory: directory,
      );

      // Stop scanning animation
      _logger.stopAnimation();

      if (flutterProjects.isEmpty) {
        _logger.warning(
          'No Flutter projects found in the specified directory.',
        );
        return {'successful': 0, 'failed': 0};
      }

      _logger.success('Found ${flutterProjects.length} Flutter project(s)');

      int cleanedCount = 0;
      int failedCount = 0;

      for (var projectDir in flutterProjects) {
        // Show progress during cleaning
        _logger.showProgress(
          cleanedCount + failedCount + 1,
          flutterProjects.length,
          'Cleaning ${path.basename(projectDir.path)}...',
        );

        final success = await _flutterClean(
          directory: projectDir,
          useFvm: useFvm,
          dryRun: dryRun,
        );

        if (success) {
          cleanedCount++;
        } else {
          failedCount++;
        }
      }

      // Show comprehensive results
      if (failedCount == 0) {
        _logger.animatedSuccess('Cleaned $cleanedCount Flutter project(s)!');
      } else {
        _logger.warning(
          'Completed with $cleanedCount successful and $failedCount failed operations.',
        );
        if (cleanedCount > 0) {
          _logger.success('Successfully cleaned $cleanedCount project(s)');
        }
        if (failedCount > 0) {
          _logger.error('Failed to clean $failedCount project(s)');
        }
      }

      return {'successful': cleanedCount, 'failed': failedCount};
    } catch (e) {
      _logger.error('Unexpected error during cleaning process: $e');
      return {'successful': 0, 'failed': 0};
    }
  }

  Future<bool> _flutterClean({
    required Directory directory,
    required bool useFvm,
    required bool dryRun,
  }) async {
    // Verify flutter/fvm commands exist before execution
    final flutterExists = await Process.run('which', [
      useFvm ? 'fvm' : 'flutter',
    ]);
    if (flutterExists.exitCode != 0) {
      _logger.error('Flutter command not found: ${useFvm ? 'fvm' : 'flutter'}');
      return false;
    }

    final command = useFvm ? 'fvm flutter clean' : 'flutter clean';
    if (dryRun) {
      _logger.dryRun('Dry run: Would execute "$command" in ${directory.path}');
      return true; // Assume success for dry run
    }

    try {
      final result = await Process.run(
        useFvm ? 'fvm' : 'flutter',
        useFvm ? ['flutter', 'clean'] : ['clean'],
        workingDirectory: directory.path,
      );

      if (result.exitCode == 0) {
        _logger.success('Successfully ran "$command" in ${directory.path}');
        return true;
      } else {
        // Handle non-zero exit codes gracefully
        final errorMessage = result.stderr.toString().trim();
        final outputMessage = result.stdout.toString().trim();

        _logger.error(
          'Failed to run "$command" in ${directory.path} (exit code: ${result.exitCode})',
        );

        if (errorMessage.isNotEmpty) {
          _logger.debug('Error output: $errorMessage');
        }

        if (outputMessage.isNotEmpty) {
          _logger.debug('Standard output: $outputMessage');
        }

        return false;
      }
    } catch (e) {
      _logger.error(
        'Exception while running "$command" in ${directory.path}: $e',
      );
      return false;
    }
  }

  Future<List<Directory>> listFlutterDirectories({
    required Directory directory,
  }) async {
    final subDirectories = <Directory>[];

    try {
      await for (var entity in directory.list(
        recursive: true,
        followLinks: false, // Security: Don't follow symlinks to prevent issues
      )) {
        if (entity is Directory) {
          // Additional safety check for symlinks
          final stat = await entity.stat();
          if (stat.type == FileSystemEntityType.link) {
            _logger.debug('Skipping symlink: ${entity.path}');
            continue;
          }

          if (await validateProject(directory: entity)) {
            subDirectories.add(entity);
          }
        }
      }
    } catch (e) {
      _logger.error('Error scanning directory ${directory.path}: $e');
    }

    return subDirectories;
  }

  Future<bool> validateProject({required Directory directory}) async {
    try {
      // Security check: Skip if it's a symlink
      final stat = await directory.stat();
      if (stat.type == FileSystemEntityType.link) {
        return false;
      }

      final pubspecFile = File('${directory.path}/pubspec.yaml');
      final libDir = Directory('${directory.path}/lib');

      // Basic existence checks (original behavior - just check file/directory existence)
      return await pubspecFile.exists() && await libDir.exists();
    } catch (e) {
      _logger.debug('Error validating project ${directory.path}: $e');
      return false;
    }
  }
}
