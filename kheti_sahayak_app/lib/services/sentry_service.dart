import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:kheti_sahayak_app/models/user.dart';

class SentryService {
  static bool _isInitialized = false;

  static Future<void> init() async {
    final dsn = dotenv.env['SENTRY_DSN'];
    
    if (dsn == null || dsn.isEmpty) {
      if (kDebugMode) {
        print('[Sentry] SENTRY_DSN not configured, error monitoring disabled');
      }
      return;
    }

    await SentryFlutter.init(
      (options) {
        options.dsn = dsn;
        options.environment = kReleaseMode ? 'production' : 'development';
        options.tracesSampleRate = kReleaseMode ? 0.1 : 1.0;
        options.attachScreenshot = true;
        options.attachViewHierarchy = true;
        options.sendDefaultPii = false;
        
        options.beforeSend = (event, hint) {
          if (kDebugMode) {
            print('[Sentry] Would send event: ${event.message ?? event.exceptions?.first.value}');
          }
          return event;
        };
      },
    );

    _isInitialized = true;
    if (kDebugMode) {
      print('[Sentry] Error monitoring initialized');
    }
  }

  static void setUser(User? user) {
    if (!_isInitialized || user == null) {
      Sentry.configureScope((scope) => scope.setUser(null));
      return;
    }

    Sentry.configureScope((scope) {
      scope.setUser(SentryUser(
        id: user.id,
        email: user.email,
        username: user.username,
      ));
    });
  }

  static void clearUser() {
    if (!_isInitialized) return;
    Sentry.configureScope((scope) => scope.setUser(null));
  }

  static Future<void> captureException(
    dynamic exception, {
    dynamic stackTrace,
    Map<String, dynamic>? extra,
    Map<String, String>? tags,
  }) async {
    if (!_isInitialized) {
      if (kDebugMode) {
        print('[Error] $exception');
        if (stackTrace != null) print(stackTrace);
      }
      return;
    }

    await Sentry.captureException(
      exception,
      stackTrace: stackTrace,
      withScope: (scope) {
        if (extra != null) {
          extra.forEach((key, value) {
            scope.setExtra(key, value);
          });
        }
        if (tags != null) {
          tags.forEach((key, value) {
            scope.setTag(key, value);
          });
        }
      },
    );
  }

  static Future<void> captureMessage(
    String message, {
    SentryLevel level = SentryLevel.info,
    Map<String, String>? tags,
  }) async {
    if (!_isInitialized) {
      if (kDebugMode) {
        print('[${level.name.toUpperCase()}] $message');
      }
      return;
    }

    await Sentry.captureMessage(
      message,
      level: level,
      withScope: (scope) {
        if (tags != null) {
          tags.forEach((key, value) {
            scope.setTag(key, value);
          });
        }
      },
    );
  }

  static void addBreadcrumb(String message, {String? category, Map<String, dynamic>? data}) {
    if (!_isInitialized) return;
    
    Sentry.addBreadcrumb(Breadcrumb(
      message: message,
      category: category,
      data: data,
      timestamp: DateTime.now(),
    ));
  }

  static Future<T> wrap<T>(Future<T> Function() fn, {String? operation}) async {
    if (!_isInitialized) {
      return fn();
    }

    final transaction = Sentry.startTransaction(
      operation ?? 'custom',
      'task',
    );

    try {
      final result = await fn();
      transaction.status = const SpanStatus.ok();
      return result;
    } catch (e, stackTrace) {
      transaction.status = const SpanStatus.internalError();
      await captureException(e, stackTrace: stackTrace);
      rethrow;
    } finally {
      await transaction.finish();
    }
  }

  static bool get isConfigured => _isInitialized;
}
