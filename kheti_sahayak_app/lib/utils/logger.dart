import 'package:logger/logger.dart';

class LoggerHelper {
  static final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 0,
      errorMethodCount: 5,
      lineLength: 50,
      colors: true,
      printEmojis: true,
      printTime: true,
    ),
  );

  static void debug(String message) {
    _logger.d(message);
  }

  static void info(String message) {
    _logger.i(message);
  }

  static void warning(String message) {
    _logger.w(message);
  }

  static void error(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.e(message, error: error, stackTrace: stackTrace);
  }

  static void verbose(String message) {
    _logger.v(message);
  }

  static void wtf(String message) {
    _logger.wtf(message);
  }
}

class Logger {
  static void init() {
    // Initialize any logger configurations here
  }

  static void debug(String message) => LoggerHelper.debug(message);
  static void info(String message) => LoggerHelper.info(message);
  static void warning(String message) => LoggerHelper.warning(message);
  static void error(String message, [dynamic error, StackTrace? stackTrace]) => 
      LoggerHelper.error(message, error, stackTrace);
  static void verbose(String message) => LoggerHelper.verbose(message);
  static void wtf(String message) => LoggerHelper.wtf(message);
}
