const Sentry = require('@sentry/node');

let isInitialized = false;

const initSentry = (app) => {
  if (!process.env.SENTRY_DSN) {
    console.log('[Sentry] SENTRY_DSN not configured, error monitoring disabled');
    return;
  }

  if (isInitialized) {
    return;
  }

  Sentry.init({
    dsn: process.env.SENTRY_DSN,
    environment: process.env.NODE_ENV || 'development',
    release: process.env.npm_package_version || '1.0.0',
    tracesSampleRate: process.env.NODE_ENV === 'production' ? 0.1 : 1.0,
    profilesSampleRate: process.env.NODE_ENV === 'production' ? 0.1 : 1.0,
    integrations: [
      Sentry.httpIntegration({ tracing: true }),
      Sentry.expressIntegration({ app }),
    ],
    beforeSend(event, hint) {
      if (process.env.NODE_ENV === 'development') {
        console.error('[Sentry] Would send event:', event.message || event.exception);
      }
      
      if (event.request?.headers) {
        delete event.request.headers.authorization;
        delete event.request.headers.cookie;
      }
      
      return event;
    },
    ignoreErrors: [
      'ECONNRESET',
      'ENOTFOUND',
      'ETIMEDOUT',
      'Network request failed',
      'AbortError',
    ],
  });

  isInitialized = true;
  console.log('[Sentry] Error monitoring initialized');
};

const captureException = (error, context = {}) => {
  if (!isInitialized) {
    console.error('[Error]', error.message, context);
    return;
  }

  Sentry.withScope((scope) => {
    if (context.user) {
      scope.setUser({ id: context.user.id, email: context.user.email });
    }
    if (context.tags) {
      Object.entries(context.tags).forEach(([key, value]) => {
        scope.setTag(key, value);
      });
    }
    if (context.extra) {
      Object.entries(context.extra).forEach(([key, value]) => {
        scope.setExtra(key, value);
      });
    }
    Sentry.captureException(error);
  });
};

const captureMessage = (message, level = 'info', context = {}) => {
  if (!isInitialized) {
    console.log(`[${level.toUpperCase()}]`, message, context);
    return;
  }

  Sentry.withScope((scope) => {
    scope.setLevel(level);
    if (context.tags) {
      Object.entries(context.tags).forEach(([key, value]) => {
        scope.setTag(key, value);
      });
    }
    Sentry.captureMessage(message);
  });
};

const errorHandler = () => {
  if (!isInitialized) {
    return (err, req, res, next) => next(err);
  }
  return Sentry.expressErrorHandler();
};

const requestHandler = () => {
  if (!isInitialized) {
    return (req, res, next) => next();
  }
  return Sentry.expressRequestHandler();
};

const setUser = (user) => {
  if (!isInitialized || !user) return;
  Sentry.setUser({ id: user.id, email: user.email, username: user.username });
};

const clearUser = () => {
  if (!isInitialized) return;
  Sentry.setUser(null);
};

module.exports = {
  initSentry,
  captureException,
  captureMessage,
  errorHandler,
  requestHandler,
  setUser,
  clearUser,
  isConfigured: () => isInitialized,
};
