import 'dart:io';

import 'package:path/path.dart' as path;

import 'logger.dart';

class FlutterCleanAll {
  final Logger _logger;

  /// Create a FlutterCleanAll instance with optional custom logger
  FlutterCleanAll({Logger? logger}) : _logger = logger ?? Logger.instance;

  /// Clean all Flutter projects in the specified directory
  /// Returns a map with 'successful', 'failed', and 'freedBytes' counts
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
      int totalFreedBytes = 0;

      for (var projectDir in flutterProjects) {
        // Calculate size before cleaning
        final sizeBefore = dryRun
            ? 0
            : await _calculateCleanableSize(projectDir);

        // Show progress during cleaning
        final projectName = path.basename(projectDir.path);
        if (!dryRun && sizeBefore > 0) {
          _logger.showProgress(
            cleanedCount + failedCount + 1,
            flutterProjects.length,
            'Cleaning $projectName (${_formatBytes(sizeBefore)})...',
          );
        } else {
          _logger.showProgress(
            cleanedCount + failedCount + 1,
            flutterProjects.length,
            'Cleaning $projectName...',
          );
        }

        final success = await _flutterClean(
          directory: projectDir,
          useFvm: useFvm,
          dryRun: dryRun,
        );

        if (success) {
          cleanedCount++;
          if (!dryRun) {
            // Calculate freed space (sizeBefore - sizeAfter)
            final sizeAfter = await _calculateCleanableSize(projectDir);
            final freedBytes = (sizeBefore - sizeAfter).abs();
            totalFreedBytes += freedBytes;
          }
        } else {
          failedCount++;
        }
      }

      // Show comprehensive results
      if (failedCount == 0) {
        if (!dryRun && totalFreedBytes > 0) {
          _logger.animatedSuccess(
            'Cleaned $cleanedCount Flutter project(s)! Freed ${_formatBytes(totalFreedBytes)}',
          );
        } else {
          _logger.animatedSuccess('Cleaned $cleanedCount Flutter project(s)!');
        }
      } else {
        _logger.warning(
          'Completed with $cleanedCount successful and $failedCount failed operations.',
        );
        if (cleanedCount > 0) {
          if (!dryRun && totalFreedBytes > 0) {
            _logger.success(
              'Successfully cleaned $cleanedCount project(s), freed ${_formatBytes(totalFreedBytes)}',
            );
          } else {
            _logger.success('Successfully cleaned $cleanedCount project(s)');
          }
        }
        if (failedCount > 0) {
          _logger.error('Failed to clean $failedCount project(s)');
        }
      }

      return {
        'successful': cleanedCount,
        'failed': failedCount,
        'freedBytes': totalFreedBytes,
      };
    } catch (e) {
      _logger.error('Unexpected error during cleaning process: $e');
      return {'successful': 0, 'failed': 0, 'freedBytes': 0};
    }
  }

  /// Calculate the size of cleanable files/directories in a Flutter project
  Future<int> _calculateCleanableSize(Directory projectDir) async {
    int totalSize = 0;

    try {
      // List of directories/files that flutter clean removes
      final cleanableItems = [
        'build',
        '.dart_tool',
        'android/.gradle',
        'android/build',
        'ios/build',
        'ios/.symlinks',
        'ios/Flutter/Flutter.framework',
        'ios/Flutter/Flutter.podspec',
        'macos/build',
        'linux/build',
        'windows/build',
        'web/build',
      ];

      for (final item in cleanableItems) {
        final itemPath = path.join(projectDir.path, item);
        final entity = FileSystemEntity.typeSync(itemPath);

        if (entity == FileSystemEntityType.directory) {
          totalSize += await _calculateDirectorySize(Directory(itemPath));
        } else if (entity == FileSystemEntityType.file) {
          final file = File(itemPath);
          final stat = await file.stat();
          totalSize += stat.size;
        }
      }
    } catch (e) {
      _logger.debug('Error calculating size for ${projectDir.path}: $e');
    }

    return totalSize;
  }

  /// Recursively calculate the size of a directory
  Future<int> _calculateDirectorySize(Directory directory) async {
    int size = 0;

    try {
      if (!await directory.exists()) return 0;

      await for (final entity in directory.list(
        recursive: true,
        followLinks: false,
      )) {
        if (entity is File) {
          try {
            final stat = await entity.stat();
            size += stat.size;
          } catch (e) {
            // Skip files that can't be accessed
            _logger.debug('Could not access file ${entity.path}: $e');
          }
        }
      }
    } catch (e) {
      _logger.debug(
        'Error calculating directory size for ${directory.path}: $e',
      );
    }

    return size;
  }

  /// Format bytes into human-readable format (B, KB, MB, GB)
  String _formatBytes(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)}GB';
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
