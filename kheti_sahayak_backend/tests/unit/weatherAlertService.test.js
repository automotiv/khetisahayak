const mockAxiosGet = jest.fn();

jest.mock('axios', () => ({
  get: mockAxiosGet
}));

const weatherAlertService = require('../../services/weatherAlertService');

describe('Weather Alert Service', () => {
  const originalEnv = process.env;

  beforeEach(() => {
    jest.clearAllMocks();
    process.env = { ...originalEnv };
  });

  afterAll(() => {
    process.env = originalEnv;
  });

  describe('Constants', () => {
    it('should define ALERT_THRESHOLDS', () => {
      expect(weatherAlertService.ALERT_THRESHOLDS.heat_wave.temp_min).toBe(40);
      expect(weatherAlertService.ALERT_THRESHOLDS.heavy_rain.precipitation_mm).toBe(50);
      expect(weatherAlertService.ALERT_THRESHOLDS.frost.temp_max).toBe(4);
      expect(weatherAlertService.ALERT_THRESHOLDS.storm.wind_speed_kmh).toBe(50);
      expect(weatherAlertService.ALERT_THRESHOLDS.drought.days_without_rain).toBe(14);
    });

    it('should define AlertSeverity', () => {
      expect(weatherAlertService.AlertSeverity.LOW).toBe('low');
      expect(weatherAlertService.AlertSeverity.MODERATE).toBe('moderate');
      expect(weatherAlertService.AlertSeverity.HIGH).toBe('high');
      expect(weatherAlertService.AlertSeverity.SEVERE).toBe('severe');
    });

    it('should define SEASONS', () => {
      expect(weatherAlertService.SEASONS.KHARIF.name).toBe('Kharif');
      expect(weatherAlertService.SEASONS.RABI.name).toBe('Rabi');
      expect(weatherAlertService.SEASONS.ZAID.name).toBe('Zaid');
    });

    it('should define AgriSuitability', () => {
      expect(weatherAlertService.AgriSuitability.GOOD).toBe('good');
      expect(weatherAlertService.AgriSuitability.MODERATE).toBe('moderate');
      expect(weatherAlertService.AgriSuitability.POOR).toBe('poor');
    });
  });

  describe('getSeasonInfo', () => {
    it('should return current season info', () => {
      const seasonInfo = weatherAlertService.getSeasonInfo();

      expect(seasonInfo.name).toBeDefined();
      expect(seasonInfo.key).toBeDefined();
      expect(seasonInfo.crops).toBeDefined();
      expect(seasonInfo.current_month).toBeGreaterThanOrEqual(1);
      expect(seasonInfo.current_month).toBeLessThanOrEqual(12);
    });

    it('should include days_into_season', () => {
      const seasonInfo = weatherAlertService.getSeasonInfo();

      expect(seasonInfo.days_into_season).toBeGreaterThanOrEqual(0);
    });

    it('should include phase information', () => {
      const seasonInfo = weatherAlertService.getSeasonInfo();

      expect(['early', 'mid', 'late']).toContain(seasonInfo.phase);
    });

    it('should have Hindi name for season', () => {
      const seasonInfo = weatherAlertService.getSeasonInfo();

      expect(seasonInfo.name_hi).toBeDefined();
    });
  });

  describe('checkForAlerts', () => {
    it('should detect heat wave alert', async () => {
      const weatherData = {
        temp: 42,
        humidity: 30,
        wind_speed: 10,
        precipitation: 0
      };

      const alerts = await weatherAlertService.checkForAlerts(28.6, 77.2, weatherData);

      expect(alerts).toHaveLength(1);
      expect(alerts[0].alert_type).toBe('heat_wave');
      expect(alerts[0].severity).toBe('high');
    });

    it('should detect severe heat wave', async () => {
      const weatherData = {
        temp: 46,
        humidity: 25,
        wind_speed: 5,
        precipitation: 0
      };

      const alerts = await weatherAlertService.checkForAlerts(28.6, 77.2, weatherData);

      expect(alerts[0].severity).toBe('severe');
    });

    it('should detect frost alert', async () => {
      const weatherData = {
        temp: 2,
        humidity: 80,
        wind_speed: 5,
        precipitation: 0
      };

      const alerts = await weatherAlertService.checkForAlerts(28.6, 77.2, weatherData);

      expect(alerts).toHaveLength(1);
      expect(alerts[0].alert_type).toBe('frost');
    });

    it('should detect storm alert', async () => {
      const weatherData = {
        temp: 25,
        humidity: 60,
        wind_speed: 55,
        precipitation: 10
      };

      const alerts = await weatherAlertService.checkForAlerts(28.6, 77.2, weatherData);

      expect(alerts).toHaveLength(1);
      expect(alerts[0].alert_type).toBe('storm');
    });

    it('should detect heavy rain alert', async () => {
      const weatherData = {
        temp: 25,
        humidity: 90,
        wind_speed: 10,
        precipitation: 60
      };

      const alerts = await weatherAlertService.checkForAlerts(28.6, 77.2, weatherData);

      expect(alerts).toHaveLength(1);
      expect(alerts[0].alert_type).toBe('heavy_rain');
    });

    it('should detect multiple alerts', async () => {
      const weatherData = {
        temp: 42,
        humidity: 30,
        wind_speed: 55,
        precipitation: 0
      };

      const alerts = await weatherAlertService.checkForAlerts(28.6, 77.2, weatherData);

      expect(alerts.length).toBeGreaterThan(1);
      expect(alerts.map(a => a.alert_type)).toContain('heat_wave');
      expect(alerts.map(a => a.alert_type)).toContain('storm');
    });

    it('should return empty array for normal weather', async () => {
      const weatherData = {
        temp: 28,
        humidity: 60,
        wind_speed: 10,
        precipitation: 5
      };

      const alerts = await weatherAlertService.checkForAlerts(28.6, 77.2, weatherData);

      expect(alerts).toHaveLength(0);
    });

    it('should fetch weather data when not provided', async () => {
      process.env.WEATHER_API_KEY = 'test-api-key';
      mockAxiosGet.mockResolvedValueOnce({
        data: {
          main: { temp: 28, humidity: 65 },
          wind: { speed: 4 },
          weather: [{ main: 'Clear' }]
        }
      });

      const alerts = await weatherAlertService.checkForAlerts(28.6, 77.2);

      expect(mockAxiosGet).toHaveBeenCalled();
      expect(Array.isArray(alerts)).toBe(true);
    });

    it('should use mock data when API key not configured', async () => {
      delete process.env.WEATHER_API_KEY;

      const alerts = await weatherAlertService.checkForAlerts(28.6, 77.2);

      expect(Array.isArray(alerts)).toBe(true);
    });

    it('should include recommendations in alerts', async () => {
      const weatherData = { temp: 42, humidity: 30, wind_speed: 10, precipitation: 0 };

      const alerts = await weatherAlertService.checkForAlerts(28.6, 77.2, weatherData);

      expect(alerts[0].recommendations).toBeDefined();
      expect(Array.isArray(alerts[0].recommendations)).toBe(true);
      expect(alerts[0].recommendations.length).toBeGreaterThan(0);
    });

    it('should include Hindi translations in alerts', async () => {
      const weatherData = { temp: 42, humidity: 30, wind_speed: 10, precipitation: 0 };

      const alerts = await weatherAlertService.checkForAlerts(28.6, 77.2, weatherData);

      expect(alerts[0].title_hi).toBeDefined();
      expect(alerts[0].description_hi).toBeDefined();
    });

    it('should handle API errors gracefully', async () => {
      process.env.WEATHER_API_KEY = 'test-key';
      mockAxiosGet.mockRejectedValueOnce(new Error('API Error'));
      const consoleSpy = jest.spyOn(console, 'error').mockImplementation();

      const alerts = await weatherAlertService.checkForAlerts(28.6, 77.2);

      expect(alerts).toEqual([]);
      consoleSpy.mockRestore();
    });
  });

  describe('generateAgricultureAdvisory', () => {
    it('should generate advisory with season info', () => {
      const weather = { temp: 30, humidity: 60, wind_speed: 10, rain_chance: 20 };

      const advisory = weatherAlertService.generateAgricultureAdvisory(weather);

      expect(advisory.season).toBeDefined();
      expect(advisory.general_advisory).toBeDefined();
    });

    it('should add heat advisory for high temperature', () => {
      const weather = { temp: 38, humidity: 40, wind_speed: 10, rain_chance: 10 };

      const advisory = weatherAlertService.generateAgricultureAdvisory(weather);

      const heatAdvisory = advisory.general_advisory.find(a => a.type === 'heat');
      expect(heatAdvisory).toBeDefined();
      expect(heatAdvisory.priority).toBe('high');
    });

    it('should add disease risk advisory for high humidity', () => {
      const weather = { temp: 28, humidity: 85, wind_speed: 5, rain_chance: 30 };

      const advisory = weatherAlertService.generateAgricultureAdvisory(weather);

      const diseaseAdvisory = advisory.general_advisory.find(a => a.type === 'disease_risk');
      expect(diseaseAdvisory).toBeDefined();
    });

    it('should add wind advisory for high wind speed', () => {
      const weather = { temp: 28, humidity: 60, wind_speed: 30, rain_chance: 10 };

      const advisory = weatherAlertService.generateAgricultureAdvisory(weather);

      const windAdvisory = advisory.general_advisory.find(a => a.type === 'wind');
      expect(windAdvisory).toBeDefined();
    });

    it('should add rain advisory for high rain chance', () => {
      const weather = { temp: 25, humidity: 70, wind_speed: 10, rain_chance: 75 };

      const advisory = weatherAlertService.generateAgricultureAdvisory(weather);

      const rainAdvisory = advisory.general_advisory.find(a => a.type === 'rain');
      expect(rainAdvisory).toBeDefined();
    });

    it('should include crop-specific advisory when crop provided', () => {
      const weather = { temp: 28, humidity: 60, wind_speed: 10, rain_chance: 20 };

      const advisory = weatherAlertService.generateAgricultureAdvisory(weather, 'rice');

      expect(advisory.crop_specific).toBeDefined();
      expect(advisory.crop_specific.crop).toBe('rice');
    });

    it('should provide default advisory for unknown crops', () => {
      const weather = { temp: 28, humidity: 60, wind_speed: 10, rain_chance: 20 };

      const advisory = weatherAlertService.generateAgricultureAdvisory(weather, 'unknown_crop');

      expect(advisory.crop_specific).toBeDefined();
      expect(advisory.crop_specific.activities.length).toBeGreaterThan(0);
    });

    it('should include Hindi translations', () => {
      const weather = { temp: 38, humidity: 60, wind_speed: 10, rain_chance: 20 };

      const advisory = weatherAlertService.generateAgricultureAdvisory(weather);

      const heatAdvisory = advisory.general_advisory.find(a => a.type === 'heat');
      expect(heatAdvisory.message_hi).toBeDefined();
    });
  });

  describe('evaluateHourlySuitability', () => {
    it('should evaluate spraying suitability as good', () => {
      const hourData = { temp: 25, humidity: 55, wind_speed: 5, rain_probability: 10 };

      const suitability = weatherAlertService.evaluateHourlySuitability(hourData);

      expect(suitability.spraying).toBe('good');
    });

    it('should evaluate spraying suitability as poor in wind', () => {
      const hourData = { temp: 25, humidity: 55, wind_speed: 20, rain_probability: 10 };

      const suitability = weatherAlertService.evaluateHourlySuitability(hourData);

      expect(suitability.spraying).toBe('poor');
    });

    it('should evaluate irrigation suitability', () => {
      const hourData = { temp: 28, humidity: 60, wind_speed: 10, rain_probability: 20 };

      const suitability = weatherAlertService.evaluateHourlySuitability(hourData);

      expect(suitability.irrigation).toBe('good');
    });

    it('should evaluate harvesting suitability', () => {
      const hourData = { temp: 28, humidity: 50, wind_speed: 10, rain_probability: 10 };

      const suitability = weatherAlertService.evaluateHourlySuitability(hourData);

      expect(suitability.harvesting).toBe('good');
    });

    it('should evaluate field work suitability', () => {
      const hourData = { temp: 28, humidity: 60, wind_speed: 15, rain_probability: 10 };

      const suitability = weatherAlertService.evaluateHourlySuitability(hourData);

      expect(suitability.field_work).toBe('good');
    });

    it('should mark irrigation as poor when rain expected', () => {
      const hourData = { temp: 25, humidity: 80, wind_speed: 10, rain_probability: 60 };

      const suitability = weatherAlertService.evaluateHourlySuitability(hourData);

      expect(suitability.irrigation).toBe('poor');
    });

    it('should mark harvesting as poor in high humidity', () => {
      const hourData = { temp: 25, humidity: 80, wind_speed: 10, rain_probability: 50 };

      const suitability = weatherAlertService.evaluateHourlySuitability(hourData);

      expect(suitability.harvesting).toBe('poor');
    });

    it('should handle missing rain_probability', () => {
      const hourData = { temp: 25, humidity: 55, wind_speed: 5 };

      const suitability = weatherAlertService.evaluateHourlySuitability(hourData);

      expect(suitability.spraying).toBe('good');
    });
  });

  describe('subscribeToAlerts', () => {
    it('should create subscription', () => {
      const subscription = weatherAlertService.subscribeToAlerts(
        'user-1',
        28.6,
        77.2,
        ['heat_wave', 'heavy_rain']
      );

      expect(subscription.id).toBe('user-1_28.6_77.2');
      expect(subscription.user_id).toBe('user-1');
      expect(subscription.location.lat).toBe(28.6);
      expect(subscription.alert_types).toContain('heat_wave');
      expect(subscription.active).toBe(true);
    });

    it('should use default alert types when not specified', () => {
      const subscription = weatherAlertService.subscribeToAlerts('user-1', 28.6, 77.2);

      expect(subscription.alert_types).toContain('heat_wave');
      expect(subscription.alert_types).toContain('drought');
    });

    it('should include created_at timestamp', () => {
      const subscription = weatherAlertService.subscribeToAlerts('user-1', 28.6, 77.2);

      expect(subscription.created_at).toBeDefined();
    });
  });

  describe('unsubscribeFromAlerts', () => {
    it('should unsubscribe from specific location', () => {
      weatherAlertService.subscribeToAlerts('user-unsub-1', 28.6, 77.2);

      const result = weatherAlertService.unsubscribeFromAlerts('user-unsub-1', 28.6, 77.2);

      expect(result).toBe(true);
    });

    it('should unsubscribe from all locations when no coordinates', () => {
      weatherAlertService.subscribeToAlerts('user-unsub-all', 28.6, 77.2);
      weatherAlertService.subscribeToAlerts('user-unsub-all', 19.0, 72.8);

      const result = weatherAlertService.unsubscribeFromAlerts('user-unsub-all');

      expect(result).toBe(true);
    });

    it('should return false when no subscription exists', () => {
      const result = weatherAlertService.unsubscribeFromAlerts('non-existent', 0, 0);

      expect(result).toBe(false);
    });
  });

  describe('getUserSubscriptions', () => {
    it('should return user subscriptions', () => {
      weatherAlertService.subscribeToAlerts('user-subs', 28.6, 77.2);
      weatherAlertService.subscribeToAlerts('user-subs', 19.0, 72.8);

      const subscriptions = weatherAlertService.getUserSubscriptions('user-subs');

      expect(subscriptions.length).toBe(2);
    });

    it('should return empty array for user without subscriptions', () => {
      const subscriptions = weatherAlertService.getUserSubscriptions('no-subs-user');

      expect(subscriptions).toEqual([]);
    });
  });
});
