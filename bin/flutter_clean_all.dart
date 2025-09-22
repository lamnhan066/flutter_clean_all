#!/usr/bin/env dart

import 'dart:io';

import 'package:args/args.dart';
import 'package:flutter_clean_all/flutter_clean_all.dart';

void main(List<String> arguments) async {
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
    );

  try {
    final results = parser.parse(arguments);

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
      print('Error: Please provide a directory path to clean.');
      print('');
      showUsage(parser);
      exit(1);
    }

    if (restArgs.length > 1) {
      print('Error: Please provide only one directory path.');
      print('');
      showUsage(parser);
      exit(1);
    }

    final directoryPath = restArgs.first;
    final useFvm = results['fvm'] as bool;
    final dryRun = results['dry-run'] as bool;

    if (dryRun) {
      print(
        '🔍 Running in dry-run mode - no actual cleaning will be performed',
      );
      print('');
    }

    final flutterCleanAll = FlutterCleanAll();
    await flutterCleanAll.cleanAll(
      directoryPath,
      useFvm: useFvm,
      dryRun: dryRun,
    );
  } catch (e) {
    if (e is FormatException) {
      print('Error: ${e.message}');
      print('');
      showUsage(parser);
      exit(1);
    } else {
      print('An unexpected error occurred: $e');
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
  print('Flutter Clean All version 0.0.1');
  print('A tool to recursively clean all Flutter projects in a directory.');
}
