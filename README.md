# Flutter Clean All

A powerful command-line tool and Dart library to recursively find and clean all Flutter projects in a directory tree. Perfect for cleaning up large codebases with multiple Flutter projects or monorepos.

## Features

- 🔍 **Recursive Discovery**: Automatically finds all Flutter projects in a directory tree
- 🧹 **Batch Cleaning**: Cleans multiple Flutter projects with a single command
- 🔧 **FVM Support**: Works with Flutter Version Management (FVM)
- 🎯 **Dry Run Mode**: Preview what will be cleaned before executing
- 📁 **Smart Detection**: Identifies Flutter projects by checking for `pubspec.yaml` and `lib/` directory
- 🛡️ **Enhanced Error Handling**: Continues cleaning other projects even if one fails with detailed error reporting
- 🎨 **Animated Feedback**: Beautiful animated progress indicators and status updates
- 📊 **Progress Tracking**: Real-time progress bars and completion statistics
- 🚀 **Smart Exit Codes**: Returns appropriate exit codes for CI/CD integration
- 🔒 **Security Features**: Built-in protection against symlink attacks and directory traversal
- 🎛️ **Customizable Output**: Control colors, animations, and verbosity levels
- 💻 **Cross-Platform**: Works on Windows, macOS, and Linux

## Installation

### Global Installation (Recommended)

Install the tool globally to use it from anywhere:

```bash
dart pub global activate flutter_clean_all
```

After installation, you can use the `flutter_clean_all` command from anywhere in your terminal.

### Local Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  flutter_clean_all: ^0.0.1
```

Then run:

```bash
dart pub get
```

## Command Line Usage

### Basic Usage

```bash
# Clean all Flutter projects in current directory
flutter_clean_all .

# Clean all Flutter projects in a specific directory
flutter_clean_all /path/to/your/projects

# Preview what would be cleaned (dry run)
flutter_clean_all /path/to/projects --dry-run

# Use FVM instead of regular Flutter
flutter_clean_all /path/to/projects --fvm
```

### Command Options

```bash
Usage: flutter_clean_all [options] <directory>

Options:
-h, --help          Show usage information
    --fvm           Use FVM (Flutter Version Management) to run flutter commands
    --dry-run       Show what would be cleaned without actually executing the commands
-v, --version       Show version information
    --verbose       Enable verbose output with detailed logging
    --no-color      Disable colored output (useful for CI/CD)
    --no-animations Disable animated progress indicators
```

### Advanced Examples

```bash
# Clean all Flutter projects in ~/projects directory
flutter_clean_all ~/projects

# Dry run to see what would be cleaned with verbose output
flutter_clean_all . --dry-run --verbose

# Clean using FVM with animations disabled (for CI/CD)
flutter_clean_all ~/flutter-projects --fvm --no-animations --no-color

# Clean current directory with full customization
flutter_clean_all . --verbose --no-color

# Clean with minimal output (no animations, no colors)
flutter_clean_all /path/to/projects --no-animations --no-color

# Show help
flutter_clean_all --help
```

### Exit Codes

The tool returns appropriate exit codes for integration with CI/CD pipelines:

- `0`: Success - All projects cleaned successfully
- `1`: Failure - One or more projects failed to clean
- `2`: Error - Invalid arguments or system error

## Library Usage

You can also use Flutter Clean All as a Dart library in your own projects:

### Simple Library Usage

```dart
import 'package:flutter_clean_all/flutter_clean_all.dart';

void main() async {
  final cleaner = FlutterCleanAll();
  
  // Clean all Flutter projects in a directory
  final result = await cleaner.cleanAll('/path/to/projects');
  
  print('Successfully cleaned: ${result['successful']} projects');
  print('Failed to clean: ${result['failed']} projects');
}
```

### Advanced Usage with Custom Logger

```dart
import 'package:flutter_clean_all/flutter_clean_all.dart';

void main() async {
  // Create custom logger with specific settings
  final logger = Logger.create(
    level: LogLevel.verbose,    // Set log level
    enableColors: true,         // Enable colored output
    enableAnimations: true,     // Enable animations
    output: stdout,             // Custom output stream
  );
  
  final cleaner = FlutterCleanAll(logger: logger);
  
  // Clean with options
  final result = await cleaner.cleanAll(
    '/path/to/projects',
    useFvm: true,     // Use FVM
    dryRun: true,     // Dry run mode
  );
  
  // Handle results
  if (result['failed']! > 0) {
    print('Some projects failed to clean');
    exit(1);
  } else {
    print('All projects cleaned successfully!');
  }
}
```

### Validation and Project Discovery

```dart
import 'package:flutter_clean_all/flutter_clean_all.dart';
import 'dart:io';

void main() async {
  final cleaner = FlutterCleanAll();
  
  // Validate if a directory is a Flutter project
  final isFlutterProject = await cleaner.validateProject(
    directory: Directory('/path/to/project')
  );
  
  if (isFlutterProject) {
    print('Valid Flutter project found!');
  }
  
  // List all Flutter projects in a directory
  final projects = await cleaner.listFlutterDirectories(
    directory: Directory('/path/to/search')
  );
  
  print('Found ${projects.length} Flutter projects:');
  for (final project in projects) {
    print('  - ${project.path}');
  }
}
```

## How It Works

Flutter Clean All works by:

1. **Recursively scanning** the provided directory for subdirectories with animated progress feedback
2. **Validating each directory** by checking for both:
   - `pubspec.yaml` file
   - `lib/` directory
3. **Running `flutter clean`** (or `fvm flutter clean`) in each valid Flutter project with real-time progress tracking
4. **Continuing execution** even if some projects fail to clean
5. **Reporting comprehensive results** with success/failure counts and detailed error information

## Animation and Visual Feedback

The tool provides rich visual feedback during operation:

### Animation Types

- **Spinner**: Rotating spinner during directory scanning
- **Progress Bar**: Real-time progress tracking during cleaning
- **Dots**: Pulsing dots for ongoing operations
- **Typewriter**: Character-by-character text animation for results

### Customization Options

```bash
# Disable all animations (useful for CI/CD)
flutter_clean_all /path --no-animations

# Disable colors but keep animations
flutter_clean_all /path --no-color

# Enable verbose logging with full details
flutter_clean_all /path --verbose

# Minimal output for automation
flutter_clean_all /path --no-animations --no-color
```

### Logger Configuration

When using as a library, you can customize the logger:

```dart
final logger = Logger.create(
  level: LogLevel.verbose,      // debug, info, warning, error, verbose
  enableColors: true,           // Colored output
  enableAnimations: true,       // Animated feedback
  output: stdout,              // Custom output stream
);

final cleaner = FlutterCleanAll(logger: logger);
```

## Security Features

The tool includes several security enhancements:

- **Symlink Protection**: Automatically detects and skips symbolic links to prevent directory traversal attacks
- **Path Validation**: Validates that target paths are actual directories
- **Safe Recursion**: Implements safe directory traversal with error handling
- **Input Sanitization**: Validates command-line arguments and file paths

## Project Structure Detection

A directory is considered a Flutter project if it contains:

- ✅ `pubspec.yaml` file
- ✅ `lib/` directory

This ensures compatibility with:

- Flutter apps
- Flutter packages
- Flutter plugins
- Dart packages with Flutter dependencies

## Error Handling

The tool is designed to be robust and production-ready:

### Error Recovery

- **Graceful Failures**: Continues cleaning other projects if one fails
- **Detailed Error Messages**: Provides clear, actionable error information
- **Exit Code Management**: Returns appropriate exit codes for automation
- **Timeout Handling**: Manages long-running operations safely

### Error Types Handled

- Missing directories or files
- Permission denied errors
- Flutter/FVM command not found
- Corrupted or invalid pubspec.yaml files
- Network or filesystem errors during cleaning

### CI/CD Integration

```yaml
# GitHub Actions example
- name: Clean Flutter Projects
  run: flutter_clean_all . --no-animations --no-color
  continue-on-error: false

# The tool will exit with code 1 if any projects fail to clean
# Use continue-on-error: true if you want the workflow to continue
```

## Development

### Running Tests

```bash
# Run all tests
dart test

# Run specific test file
dart test test/flutter_clean_all_test.dart

# Run with coverage
dart test --coverage=coverage
```

### Building

```bash
# Get dependencies
dart pub get

# Run the CLI locally
dart bin/flutter_clean_all.dart --help

# Compile to executable
dart compile exe bin/flutter_clean_all.dart -o flutter_clean_all
```

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request. For major changes, please open an issue first to discuss what you would like to change.

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

If you find this tool helpful, please consider:

- ⭐ Starring the repository
- 🐛 Reporting issues
- 💡 Suggesting new features
- 🤝 Contributing to the codebase
