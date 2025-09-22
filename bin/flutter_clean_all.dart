#!/usr/bin/env dart

import 'dart:io';

import 'package:args/args.dart';
import 'package:flutter_clean_all/flutter_clean_all.dart';

void main(List<String> arguments) async {
  // Configure logger for CLI usage
  final cliLogger = Logger.create(
    level: LogLevel.info,
    enableColors: stdout.hasTerminal,
  );

  final parser = ArgParser()
    ..addFlag(
      'help',
      abbr: 'h',
      negatable: false,
      help: 'Show usage information.',
    )
    ..addFlag(
      'fvm',
      negatable: false,
      help: 'Use FVM (Flutter Version Management) to run flutter commands.',
    )
    ..addFlag(
      'dry-run',
      negatable: false,
      help:
          'Show what would be cleaned without actually executing the commands.',
    )
    ..addFlag(
      'version',
      abbr: 'v',
      negatable: false,
      help: 'Show version information.',
    )
    ..addFlag(
      'verbose',
      negatable: false,
      help: 'Enable verbose output with debug information.',
    )
    ..addFlag('no-color', negatable: false, help: 'Disable colored output.')
    ..addFlag(
      'no-animations',
      negatable: false,
      help: 'Disable animated output and progress indicators.',
    );

  try {
    final results = parser.parse(arguments);

    // Configure logger based on CLI flags
    final verbose = results['verbose'] as bool;
    final noColor = results['no-color'] as bool;
    final noAnimations = results['no-animations'] as bool;

    cliLogger.setLevel(verbose ? LogLevel.debug : LogLevel.info);
    cliLogger.setColorEnabled(!noColor && stdout.hasTerminal);
    cliLogger.setAnimationsEnabled(!noAnimations && stdout.hasTerminal);

    if (results['help'] as bool) {
      showHelp(parser);
      return;
    }

    if (results['version'] as bool) {
      showVersion();
      return;
    }

    final restArgs = results.rest;
    if (restArgs.isEmpty) {
      cliLogger.error('Error: Please provide a directory path to clean.');
      cliLogger.newLine();
      showUsage(parser);
      exit(1);
    }

    if (restArgs.length > 1) {
      cliLogger.error('Error: Please provide only one directory path.');
      cliLogger.newLine();
      showUsage(parser);
      exit(1);
    }

    final directoryPath = restArgs.first;
    final useFvm = results['fvm'] as bool;
    final dryRun = results['dry-run'] as bool;

    if (dryRun) {
      cliLogger.info(
        '🔍 Running in dry-run mode - no actual cleaning will be performed',
      );
      cliLogger.newLine();
    }

    if (verbose) {
      cliLogger.debug('Starting Flutter Clean All...');
      cliLogger.debug('Target directory: $directoryPath');
      cliLogger.debug('Use FVM: $useFvm');
      cliLogger.debug('Dry run: $dryRun');
      cliLogger.newLine();
    }

    final flutterCleanAll = FlutterCleanAll(logger: cliLogger);
    final result = await flutterCleanAll.cleanAll(
      directoryPath,
      useFvm: useFvm,
      dryRun: dryRun,
    );

    // Exit with appropriate code based on results
    final failed = result['failed'] ?? 0;

    if (failed > 0) {
      // Exit code 1 if any projects failed to clean
      exit(1);
    } else {
      // Exit code 0 for complete success
      exit(0);
    }
  } catch (e) {
    if (e is FormatException) {
      cliLogger.error('Error: ${e.message}');
      cliLogger.newLine();
      showUsage(parser);
      exit(1);
    } else {
      cliLogger.error('An unexpected error occurred: $e');
      exit(1);
    }
  }
}

void showHelp(ArgParser parser) {
  print(
    'Flutter Clean All - Recursively clean all Flutter projects in a directory',
  );
  print('');
  showUsage(parser);
  print('');
  print('Examples:');
  print(
    '  flutter_clean_all /path/to/projects       # Clean all Flutter projects',
  );
  print(
    '  flutter_clean_all . --dry-run             # Show what would be cleaned',
  );
  print('  flutter_clean_all ~/projects --fvm        # Use FVM for cleaning');
  print('  flutter_clean_all . --verbose             # Enable debug output');
  print('  flutter_clean_all . --no-color            # Disable colored output');
  print('  flutter_clean_all . --no-animations       # Disable animations');
  print('  flutter_clean_all --help                  # Show this help');
  print('');
  print(
    'The tool will recursively search for Flutter projects (directories with',
  );
  print(
    'both pubspec.yaml and lib/ folder) and run "flutter clean" in each one.',
  );
}

void showUsage(ArgParser parser) {
  print('Usage: flutter_clean_all [options] <directory>');
  print('');
  print('Options:');
  print(parser.usage);
}

void showVersion() {
  print('Flutter Clean All version 0.0.2');
  print('A tool to recursively clean all Flutter projects in a directory.');
}
