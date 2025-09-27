const winston = require('winston');

const levels = {
  error: 0,
  warn: 1,
  info: 2,
  http: 3,
  debug: 4,
};

const level = () => {
  const env = process.env.NODE_ENV || 'development';
  return env === 'development' ? 'debug' : 'warn';
};

const colors = {
  error: 'red',
  warn: 'yellow',
  info: 'green',
  http: 'magenta',
  debug: 'white',
};

winston.addColors(colors);

const format = process.env.NODE_ENV === 'production'
  ? winston.format.combine(
      winston.format.timestamp(),
      winston.format.json(),
    )
  : winston.format.combine(
      winston.format.timestamp({ format: 'YYYY-MM-DD HH:mm:ss:ms' }),
      winston.format.colorize({ all: true }),
      winston.format.printf(
        (info) => `${info.timestamp} ${info.level}: ${info.message}`,
      ),
    );

const transports = [new winston.transports.Console()];

// In production, we only want to log to the console (stdout) because logs will be
// captured by the container orchestrator (e.g., CloudWatch via awslogs driver).
// In development, we also log to files for easier local debugging.
if (process.env.NODE_ENV !== 'production') {
  transports.push(new winston.transports.File({
    filename: 'logs/error.log',
    level: 'error',
  }));
  transports.push(new winston.transports.File({ filename: 'logs/all.log' }));
}

const logger = winston.createLogger({
  level: level(),
  levels,
  format,
  transports,
});

module.exports = logger;