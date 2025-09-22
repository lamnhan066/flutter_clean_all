import 'dart:io';

import 'package:flutter_clean_all/flutter_clean_all.dart';

/// Example demonstrating how to use the FlutterCleanAll library
void main() async {
  print('Flutter Clean All Example');
  print('========================');

  final cleaner = FlutterCleanAll();

  // Example 1: Basic usage - clean all Flutter projects in current directory
  print('\n1. Basic Usage:');
  print('   Cleaning Flutter projects in current directory...');
  await cleaner.cleanAll('.', dryRun: true); // Using dry run for demo

  // Example 2: Clean with FVM support
  print('\n2. FVM Usage:');
  print('   Cleaning with FVM support...');
  await cleaner.cleanAll(
    '.',
    useFvm: true,
    dryRun: true, // Using dry run for demo
  );

  // Example 3: Validate if a directory is a Flutter project
  print('\n3. Project Validation:');
  final currentDir = Directory('.');
  final isFlutterProject = await cleaner.validateProject(directory: currentDir);
  print('   Is current directory a Flutter project? $isFlutterProject');

  // Example 4: List all Flutter projects in a directory
  print('\n4. Project Discovery:');
  final projects = await cleaner.listFlutterDirectories(directory: currentDir);
  print('   Found ${projects.length} Flutter project(s):');
  for (final project in projects) {
    print('   - ${project.path}');
  }

  print('\nExample completed!');
}
