const mockAxiosGet = jest.fn();
const mockDbQuery = jest.fn();
const mockSendToUser = jest.fn();
const mockSendSMS = jest.fn();

jest.mock('axios', () => ({
  get: mockAxiosGet
}));

jest.mock('../../db', () => ({
  query: mockDbQuery,
  pool: { connect: jest.fn() }
}));

jest.mock('../../services/pushNotificationService', () => ({
  sendToUser: mockSendToUser
}));

jest.mock('../../services/smsService', () => ({
  sendSMS: mockSendSMS
}));

const weatherAlertNotificationService = require('../../services/weatherAlertNotificationService');

describe('Weather Alert Notification Service', () => {
  const originalEnv = process.env;

  beforeEach(() => {
    jest.clearAllMocks();
    process.env = { ...originalEnv };
    mockSendToUser.mockResolvedValue({ success: true });
    mockSendSMS.mockResolvedValue({ success: true });
  });

  afterAll(() => {
    process.env = originalEnv;
  });

  describe('SEVERITY_LEVELS', () => {
    it('should define severity level values', () => {
      expect(weatherAlertNotificationService.SEVERITY_LEVELS.low).toBe(1);
      expect(weatherAlertNotificationService.SEVERITY_LEVELS.moderate).toBe(2);
      expect(weatherAlertNotificationService.SEVERITY_LEVELS.high).toBe(3);
      expect(weatherAlertNotificationService.SEVERITY_LEVELS.severe).toBe(4);
      expect(weatherAlertNotificationService.SEVERITY_LEVELS.extreme).toBe(5);
    });
  });

  describe('getAlertRules', () => {
    it('should fetch active alert rules from database', async () => {
      const mockRules = [
        { id: '1', alert_type: 'heat_wave', name: 'Heat Wave Alert', is_active: true },
        { id: '2', alert_type: 'frost', name: 'Frost Warning', is_active: true }
      ];
      mockDbQuery.mockResolvedValueOnce({ rows: mockRules });

      const rules = await weatherAlertNotificationService.getAlertRules();

      expect(mockDbQuery).toHaveBeenCalledWith(
        'SELECT * FROM weather_alert_rules WHERE is_active = true ORDER BY priority ASC'
      );
      expect(rules).toEqual(mockRules);
    });
  });

  describe('getUserAlertPreferences', () => {
    it('should return user preferences when found', async () => {
      const mockPrefs = {
        user_id: 'user-1',
        enabled_alerts: ['heat_wave', 'frost'],
        min_severity: 'high',
        sms_enabled: true
      };
      mockDbQuery.mockResolvedValueOnce({ rows: [mockPrefs] });

      const prefs = await weatherAlertNotificationService.getUserAlertPreferences('user-1');

      expect(prefs).toEqual(mockPrefs);
    });

    it('should return default preferences when not found', async () => {
      mockDbQuery.mockResolvedValueOnce({ rows: [] });

      const prefs = await weatherAlertNotificationService.getUserAlertPreferences('user-1');

      expect(prefs.enabled_alerts).toContain('heat_wave');
      expect(prefs.min_severity).toBe('moderate');
      expect(prefs.sms_enabled).toBe(false);
    });
  });

  describe('getUserSubscriptions', () => {
    it('should fetch user subscriptions', async () => {
      const mockSubs = [
        { id: '1', user_id: 'user-1', latitude: 28.6, longitude: 77.2 }
      ];
      mockDbQuery.mockResolvedValueOnce({ rows: mockSubs });

      const subs = await weatherAlertNotificationService.getUserSubscriptions('user-1');

      expect(subs).toEqual(mockSubs);
    });
  });

  describe('fetchWeatherData', () => {
    it('should fetch weather from API when key is configured', async () => {
      process.env.WEATHER_API_KEY = 'test-key';
      mockAxiosGet.mockResolvedValueOnce({
        data: {
          main: { temp: 30, humidity: 65 },
          wind: { speed: 5 },
          visibility: 10000,
          weather: [{ main: 'Clear', description: 'clear sky' }]
        }
      });

      const weather = await weatherAlertNotificationService.fetchWeatherData(28.6, 77.2);

      expect(weather.temp).toBe(30);
      expect(weather.humidity).toBe(65);
      expect(weather.wind_speed).toBe(18);
    });

    it('should return mock data when API key not configured', async () => {
      delete process.env.WEATHER_API_KEY;

      const weather = await weatherAlertNotificationService.fetchWeatherData(28.6, 77.2);

      expect(weather.temp).toBe(28);
      expect(weather.humidity).toBe(65);
    });
  });

  describe('checkAndTriggerAlerts', () => {
    it('should check weather and return triggered alerts', async () => {
      const mockRules = [{
        alert_type: 'heat_wave',
        name: 'Heat Wave Alert',
        name_hi: 'लू की चेतावनी',
        conditions: { temp_min: 40 },
        severity_thresholds: { moderate: { temp_min: 40 }, high: { temp_min: 42 } },
        recommendations: ['Stay hydrated'],
        recommendations_hi: ['हाइड्रेटेड रहें'],
        sms_enabled: true,
        priority: 1
      }];

      mockDbQuery.mockResolvedValueOnce({ rows: mockRules });

      const weatherData = { temp: 43, humidity: 30, wind_speed: 10 };
      const alerts = await weatherAlertNotificationService.checkAndTriggerAlerts(28.6, 77.2, weatherData);

      expect(alerts.length).toBe(1);
      expect(alerts[0].alert_type).toBe('heat_wave');
      expect(alerts[0].severity).toBe('high');
    });

    it('should return empty array when no conditions met', async () => {
      const mockRules = [{
        alert_type: 'heat_wave',
        conditions: { temp_min: 40 },
        severity_thresholds: { moderate: { temp_min: 40 } }
      }];

      mockDbQuery.mockResolvedValueOnce({ rows: mockRules });

      const weatherData = { temp: 28, humidity: 60, wind_speed: 10 };
      const alerts = await weatherAlertNotificationService.checkAndTriggerAlerts(28.6, 77.2, weatherData);

      expect(alerts.length).toBe(0);
    });
  });

  describe('createSubscription', () => {
    it('should create new subscription', async () => {
      const mockSub = {
        id: 'sub-1',
        user_id: 'user-1',
        latitude: 28.6,
        longitude: 77.2,
        location_name: 'Delhi',
        is_primary: true
      };

      mockDbQuery
        .mockResolvedValueOnce({ rows: [] })
        .mockResolvedValueOnce({ rows: [mockSub] });

      const sub = await weatherAlertNotificationService.createSubscription(
        'user-1', 28.6, 77.2, 'Delhi', null, true
      );

      expect(sub.location_name).toBe('Delhi');
      expect(sub.is_primary).toBe(true);
    });
  });

  describe('updateAlertPreferences', () => {
    it('should update user preferences', async () => {
      const mockUpdatedPrefs = {
        user_id: 'user-1',
        enabled_alerts: ['heat_wave', 'frost'],
        min_severity: 'high',
        sms_enabled: true
      };

      mockDbQuery.mockResolvedValueOnce({ rows: [mockUpdatedPrefs] });

      const prefs = await weatherAlertNotificationService.updateAlertPreferences('user-1', {
        enabled_alerts: ['heat_wave', 'frost'],
        min_severity: 'high',
        sms_enabled: true
      });

      expect(prefs.min_severity).toBe('high');
      expect(prefs.sms_enabled).toBe(true);
    });
  });

  describe('getAlertHistory', () => {
    it('should fetch alert history with pagination', async () => {
      const mockAlerts = [
        { id: '1', alert_type: 'heat_wave', severity: 'high' },
        { id: '2', alert_type: 'frost', severity: 'moderate' }
      ];

      mockDbQuery.mockResolvedValueOnce({ rows: mockAlerts });

      const alerts = await weatherAlertNotificationService.getAlertHistory('user-1', {
        limit: 10,
        offset: 0
      });

      expect(alerts).toEqual(mockAlerts);
    });

    it('should filter by alert type', async () => {
      mockDbQuery.mockResolvedValueOnce({ rows: [] });

      await weatherAlertNotificationService.getAlertHistory('user-1', {
        alertType: 'heat_wave'
      });

      expect(mockDbQuery).toHaveBeenCalledWith(
        expect.stringContaining('alert_type'),
        expect.arrayContaining(['user-1', 'heat_wave'])
      );
    });
  });

  describe('markAlertAsRead', () => {
    it('should mark alert as read', async () => {
      const mockAlert = { id: 'alert-1', is_read: true, read_at: new Date() };
      mockDbQuery.mockResolvedValueOnce({ rows: [mockAlert] });

      const alert = await weatherAlertNotificationService.markAlertAsRead('user-1', 'alert-1');

      expect(alert.is_read).toBe(true);
    });

    it('should return undefined when alert not found', async () => {
      mockDbQuery.mockResolvedValueOnce({ rows: [] });

      const alert = await weatherAlertNotificationService.markAlertAsRead('user-1', 'non-existent');

      expect(alert).toBeUndefined();
    });
  });

  describe('deleteSubscription', () => {
    it('should delete subscription', async () => {
      mockDbQuery.mockResolvedValueOnce({ rows: [{ id: 'sub-1' }] });

      const result = await weatherAlertNotificationService.deleteSubscription('user-1', 'sub-1');

      expect(result).toBe(true);
    });

    it('should return false when subscription not found', async () => {
      mockDbQuery.mockResolvedValueOnce({ rows: [] });

      const result = await weatherAlertNotificationService.deleteSubscription('user-1', 'non-existent');

      expect(result).toBe(false);
    });
  });
});
