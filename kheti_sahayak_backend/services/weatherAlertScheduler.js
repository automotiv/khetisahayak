const weatherAlertNotificationService = require('./weatherAlertNotificationService');

let alertCheckInterval = null;
const DEFAULT_CHECK_INTERVAL_MS = 30 * 60 * 1000;

async function runAlertCheck() {
  console.log('[WeatherAlertScheduler] Starting scheduled alert check...');
  
  try {
    const results = await weatherAlertNotificationService.processAllSubscriptions();
    console.log(`[WeatherAlertScheduler] Completed: processed=${results.processed}, alerts=${results.alertsSent}, errors=${results.errors.length}`);
    return results;
  } catch (error) {
    console.error('[WeatherAlertScheduler] Error during alert check:', error.message);
    return { error: error.message };
  }
}

function startScheduler(intervalMs = DEFAULT_CHECK_INTERVAL_MS) {
  if (alertCheckInterval) {
    console.log('[WeatherAlertScheduler] Scheduler already running');
    return;
  }
  
  console.log(`[WeatherAlertScheduler] Starting scheduler with ${intervalMs / 1000 / 60} minute interval`);
  
  runAlertCheck();
  
  alertCheckInterval = setInterval(runAlertCheck, intervalMs);
}

function stopScheduler() {
  if (alertCheckInterval) {
    clearInterval(alertCheckInterval);
    alertCheckInterval = null;
    console.log('[WeatherAlertScheduler] Scheduler stopped');
  }
}

function isRunning() {
  return alertCheckInterval !== null;
}

module.exports = {
  startScheduler,
  stopScheduler,
  runAlertCheck,
  isRunning,
  DEFAULT_CHECK_INTERVAL_MS
};
