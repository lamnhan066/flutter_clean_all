## 0.0.1

### ✨ Features

- **Command-line interface**: Added `flutter_clean_all` executable for global usage
- **Recursive project discovery**: Automatically finds all Flutter projects in directory trees
- **Batch cleaning**: Clean multiple Flutter projects with a single command
- **FVM support**: Use Flutter Version Management with `--fvm` flag
- **Dry run mode**: Preview what will be cleaned with `--dry-run` flag
- **Smart project detection**: Validates Flutter projects by checking for `pubspec.yaml` and `lib/` directory
- **Robust error handling**: Continues execution even if individual projects fail
- **Cross-platform support**: Works on Windows, macOS, and Linux

### 📚 Library API

- `FlutterCleanAll.cleanAll()`: Main method to clean Flutter projects
- `FlutterCleanAll.validateProject()`: Check if a directory is a Flutter project
- `FlutterCleanAll.listFlutterDirectories()`: Find all Flutter projects in a directory

### 🧪 Testing

- Comprehensive test suite with 33 tests covering all functionality
- Integration tests for command-line interface
- Unit tests for individual methods
- Edge case testing for various project structures

### 📖 Documentation

- Complete README with usage examples
- Command-line help documentation
- Library usage examples
- Installation instructions
