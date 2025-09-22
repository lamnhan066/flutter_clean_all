# Flutter Clean All

A powerful command-line tool and Dart library to recursively find and clean all Flutter projects in a directory tree. Perfect for cleaning up large codebases with multiple Flutter projects or monorepos.

## Features

- 🔍 **Recursive Discovery**: Automatically finds all Flutter projects in a directory tree
- 🧹 **Batch Cleaning**: Cleans multiple Flutter projects with a single command
- 🔧 **FVM Support**: Works with Flutter Version Management (FVM)
- 🎯 **Dry Run Mode**: Preview what will be cleaned before executing
- 📁 **Smart Detection**: Identifies Flutter projects by checking for `pubspec.yaml` and `lib/` directory
- 🛡️ **Error Handling**: Continues cleaning other projects even if one fails
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
-h, --help       Show usage information
    --fvm        Use FVM (Flutter Version Management) to run flutter commands
    --dry-run    Show what would be cleaned without actually executing the commands
-v, --version    Show version information
```

### Examples

```bash
# Clean all Flutter projects in ~/projects directory
flutter_clean_all ~/projects

# Dry run to see what would be cleaned
flutter_clean_all . --dry-run

# Clean using FVM
flutter_clean_all ~/flutter-projects --fvm

# Clean current directory and subdirectories
flutter_clean_all .

# Show help
flutter_clean_all --help
```

## Library Usage

You can also use Flutter Clean All as a Dart library in your own projects:

```dart
import 'package:flutter_clean_all/flutter_clean_all.dart';

void main() async {
  final cleaner = FlutterCleanAll();
  
  // Clean all Flutter projects in a directory
  await cleaner.cleanAll('/path/to/projects');
  
  // Clean with options
  await cleaner.cleanAll(
    '/path/to/projects',
    useFvm: true,     // Use FVM
    dryRun: true,     // Dry run mode
  );
  
  // Validate if a directory is a Flutter project
  final isFlutterProject = await cleaner.validateProject(
    directory: Directory('/path/to/project')
  );
  
  // List all Flutter projects in a directory
  final projects = await cleaner.listFlutterDirectories(
    directory: Directory('/path/to/search')
  );
}
```

## How It Works

Flutter Clean All works by:

1. **Recursively scanning** the provided directory for subdirectories
2. **Validating each directory** by checking for both:
   - `pubspec.yaml` file
   - `lib/` directory
3. **Running `flutter clean`** (or `fvm flutter clean`) in each valid Flutter project
4. **Continuing execution** even if some projects fail to clean
5. **Reporting results** with the number of projects successfully cleaned

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

The tool is designed to be robust:

- Continues cleaning other projects if one fails
- Provides clear error messages
- Reports the total number of projects cleaned
- Handles missing directories gracefully
- Validates input parameters

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
