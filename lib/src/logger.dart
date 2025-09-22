import 'dart:async';
import 'dart:io';

/// Log levels for the Flutter Clean All logger
enum LogLevel { debug, info, warning, error }

/// Animation types for the logger
enum AnimationType { none, spinner, dots, pulse, typewriter }

/// A simple logger class to handle all logging in Flutter Clean All
class Logger {
  static Logger? _instance;
  LogLevel _currentLevel;
  bool _enableColors;
  bool _enableAnimations;
  IOSink _output;
  Timer? _animationTimer;
  int _animationFrame = 0;

  Logger._({
    LogLevel level = LogLevel.info,
    bool enableColors = true,
    bool enableAnimations = true,
    IOSink? output,
  }) : _currentLevel = level,
       _enableColors = enableColors,
       _enableAnimations = enableAnimations,
       _output = output ?? stdout;

  /// Get the singleton instance of the logger
  static Logger get instance {
    _instance ??= Logger._();
    return _instance!;
  }

  /// Create a logger instance with custom configuration
  static Logger create({
    LogLevel level = LogLevel.info,
    bool enableColors = true,
    bool enableAnimations = true,
    IOSink? output,
  }) {
    return Logger._(
      level: level,
      enableColors: enableColors,
      enableAnimations: enableAnimations,
      output: output,
    );
  }

  /// Set the current log level
  void setLevel(LogLevel level) {
    _currentLevel = level;
  }

  /// Enable or disable colored output
  void setColorEnabled(bool enabled) {
    _enableColors = enabled;
  }

  /// Enable or disable animations
  void setAnimationsEnabled(bool enabled) {
    _enableAnimations = enabled;
    if (!enabled) {
      _stopAnimation();
    }
  }

  /// Set custom output sink
  void setOutput(IOSink output) {
    _output = output;
  }

  /// Start an animated loading indicator
  void startAnimation(
    String message, {
    AnimationType type = AnimationType.spinner,
  }) {
    if (!_enableAnimations || !_shouldLog(LogLevel.info)) return;

    _stopAnimation(); // Stop any existing animation

    _output.write('\r$message ');
    _animationTimer = Timer.periodic(Duration(milliseconds: 100), (_) {
      _updateAnimation(type);
    });
  }

  /// Stop the current animation
  void stopAnimation([String? finalMessage]) {
    _stopAnimation();
    if (finalMessage != null && _shouldLog(LogLevel.info)) {
      _output.write('\r\x1B[K'); // Clear the line
      _output.writeln(finalMessage);
    }
  }

  /// Update the animation frame
  void _updateAnimation(AnimationType type) {
    String frame;

    switch (type) {
      case AnimationType.spinner:
        final frames = ['⠋', '⠙', '⠹', '⠸', '⠼', '⠴', '⠦', '⠧', '⠇', '⠏'];
        frame = frames[_animationFrame % frames.length];
        break;
      case AnimationType.dots:
        final frames = ['   ', '.  ', '.. ', '...'];
        frame = frames[_animationFrame % frames.length];
        break;
      case AnimationType.pulse:
        final frames = ['💙', '💚', '💛', '🧡', '❤️', '💜'];
        frame = frames[_animationFrame % frames.length];
        break;
      case AnimationType.none:
      case AnimationType.typewriter:
        frame = '⠋';
        break;
    }

    if (_enableColors) {
      frame = '\x1B[36m$frame\x1B[0m'; // Cyan color for animation
    }

    _output.write('\b$frame');
    _animationFrame++;
  }

  /// Stop animation timer
  void _stopAnimation() {
    _animationTimer?.cancel();
    _animationTimer = null;
    _animationFrame = 0;
  }

  /// Log a debug message
  void debug(String message) {
    _log(LogLevel.debug, message);
  }

  /// Log an info message
  void info(String message) {
    _log(LogLevel.info, message);
  }

  /// Log a warning message
  void warning(String message) {
    _log(LogLevel.warning, message);
  }

  /// Log an error message
  void error(String message) {
    _log(LogLevel.error, message);
  }

  /// Log a message with specific level
  void _log(LogLevel level, String message) {
    if (_shouldLog(level)) {
      final formattedMessage = _formatMessage(level, message);
      _output.writeln(formattedMessage);
    }
  }

  /// Check if a message should be logged based on current level
  bool _shouldLog(LogLevel level) {
    return level.index >= _currentLevel.index;
  }

  /// Format the log message with level and optional colors
  String _formatMessage(LogLevel level, String message) {
    if (!_enableColors) {
      return message;
    }

    switch (level) {
      case LogLevel.debug:
        return '\x1B[90m$message\x1B[0m'; // Gray
      case LogLevel.info:
        return message; // No color for info
      case LogLevel.warning:
        return '\x1B[33m$message\x1B[0m'; // Yellow
      case LogLevel.error:
        return '\x1B[31m$message\x1B[0m'; // Red
    }
  }

  /// Log a success message (special case of info with green color)
  void success(String message) {
    if (_shouldLog(LogLevel.info)) {
      final formattedMessage = _enableColors
          ? '\x1B[32m$message\x1B[0m' // Green
          : message;
      _output.writeln(formattedMessage);
    }
  }

  /// Log a dry run message (special case with specific formatting)
  void dryRun(String message) {
    if (_shouldLog(LogLevel.info)) {
      final formattedMessage = _enableColors
          ? '\x1B[36m$message\x1B[0m' // Cyan
          : message;
      _output.writeln(formattedMessage);
    }
  }

  /// Log an empty line
  void newLine() {
    if (_shouldLog(LogLevel.info)) {
      _output.writeln('');
    }
  }

  /// Log with typewriter animation effect
  Future<void> typewrite(
    String message, {
    LogLevel level = LogLevel.info,
    int delayMs = 50,
  }) async {
    if (!_shouldLog(level) || !_enableAnimations) {
      _log(level, message);
      return;
    }

    final formattedMessage = _formatMessage(level, message);
    for (int i = 0; i < formattedMessage.length; i++) {
      _output.write(formattedMessage[i]);
      await Future.delayed(Duration(milliseconds: delayMs));
    }
    _output.writeln();
  }

  /// Show animated progress bar
  void showProgress(int current, int total, String message) {
    if (!_shouldLog(LogLevel.info)) return;

    final percentage = (current / total * 100).round();
    final barLength = 20;
    final filledLength = (current / total * barLength).round();

    final bar = '[${'=' * filledLength}${' ' * (barLength - filledLength)}]';
    final progressText = '$bar $percentage% ($current/$total) $message';

    if (_enableColors) {
      final coloredBar =
          '[\x1B[32m${'=' * filledLength}\x1B[0m${' ' * (barLength - filledLength)}]';
      final coloredText =
          '$coloredBar \x1B[33m$percentage%\x1B[0m (\x1B[36m$current\x1B[0m/\x1B[36m$total\x1B[0m) $message';
      _output.write('\r\x1B[K$coloredText');
    } else {
      _output.write('\r\x1B[K$progressText');
    }

    if (current == total) {
      _output.writeln(); // New line when complete
    }
  }

  /// Show animated success message with checkmark
  void animatedSuccess(String message) {
    if (!_shouldLog(LogLevel.info)) return;

    if (_enableAnimations) {
      _output.write('⏳ ');
      Future.delayed(Duration(milliseconds: 300), () {
        _output.write('\b\b✅ ');
        if (_enableColors) {
          _output.writeln('\x1B[32m$message\x1B[0m');
        } else {
          _output.writeln(message);
        }
      });
    } else {
      success(message);
    }
  }

  /// Show animated error message with cross mark
  void animatedError(String message) {
    if (!_shouldLog(LogLevel.error)) return;

    if (_enableAnimations) {
      _output.write('⏳ ');
      Future.delayed(Duration(milliseconds: 300), () {
        _output.write('\b\b❌ ');
        if (_enableColors) {
          _output.writeln('\x1B[31m$message\x1B[0m');
        } else {
          _output.writeln(message);
        }
      });
    } else {
      error(message);
    }
  }

  /// Cleanup method to stop any running animations
  void dispose() {
    _stopAnimation();
  }
}

/// Global logger instance for easy access
final logger = Logger.instance;
