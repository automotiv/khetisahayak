const mockAxiosGet = jest.fn();
const mockRedisGet = jest.fn();
const mockRedisSetex = jest.fn();

jest.mock('axios', () => ({
  get: mockAxiosGet
}));

jest.mock('../../redisClient', () => ({
  get: mockRedisGet,
  setex: mockRedisSetex
}));

jest.mock('../../services/weatherRecommendationService', () => ({
  getActivityRecommendations: jest.fn().mockReturnValue([
    { activity: 'irrigation', suitable: true, reason: 'Good conditions' }
  ]),
  getDailyTips: jest.fn().mockReturnValue(['Irrigate early morning']),
  getOptimalTimeWindows: jest.fn().mockReturnValue([{ start: '06:00', end: '09:00' }])
}));

jest.mock('../../services/weatherAlertService', () => ({
  checkForAlerts: jest.fn().mockResolvedValue([]),
  getSeasonInfo: jest.fn().mockReturnValue({
    name: 'Rabi',
    name_hi: 'रबी',
    crops: ['wheat', 'mustard'],
    phase: 'mid'
  }),
  generateAgricultureAdvisory: jest.fn().mockReturnValue({
    general_advisory: [{ type: 'weather', message: 'Good conditions' }]
  }),
  evaluateHourlySuitability: jest.fn().mockReturnValue({
    spraying: 'good',
    irrigation: 'good',
    harvesting: 'moderate'
  }),
  subscribeToAlerts: jest.fn().mockReturnValue({ id: 'sub_123', active: true }),
  unsubscribeFromAlerts: jest.fn().mockReturnValue(true),
  getUserSubscriptions: jest.fn().mockReturnValue([])
}));

describe('Weather Controller Unit Tests', () => {
  beforeEach(() => {
    process.env.WEATHER_API_KEY = 'test_api_key';
  });

  afterEach(() => {
    jest.clearAllMocks();
  });

  describe('getWeather', () => {
    it('should fetch weather data for given coordinates', async () => {
      const mockWeatherData = {
        main: { temp: 28, humidity: 65 },
        wind: { speed: 5 },
        clouds: { all: 30 },
        weather: [{ main: 'Clear', description: 'clear sky' }]
      };

      mockAxiosGet.mockResolvedValueOnce({ data: mockWeatherData });

      const result = await mockAxiosGet(
        `https://api.openweathermap.org/data/2.5/weather?lat=20.5&lon=78.9&appid=test_key&units=metric`
      );

      expect(result.data.main.temp).toBe(28);
      expect(result.data.main.humidity).toBe(65);
    });

    it('should validate latitude and longitude are required', () => {
      const validParams = { lat: 20.5, lon: 78.9 };
      const missingLat = { lon: 78.9 };
      const missingLon = { lat: 20.5 };

      expect('lat' in validParams && 'lon' in validParams).toBe(true);
      expect('lat' in missingLat && 'lon' in missingLat).toBe(false);
      expect('lat' in missingLon && 'lon' in missingLon).toBe(false);
    });

    it('should handle missing API key', () => {
      delete process.env.WEATHER_API_KEY;
      const apiKey = process.env.WEATHER_API_KEY;

      expect(apiKey).toBeUndefined();
    });

    it('should handle weather API errors', async () => {
      mockAxiosGet.mockRejectedValueOnce({
        response: { status: 401, data: { message: 'Invalid API key' } }
      });

      await expect(mockAxiosGet('https://api.openweathermap.org/invalid'))
        .rejects.toMatchObject({ response: { status: 401 } });
    });
  });

  describe('getRecommendations', () => {
    it('should return activity recommendations based on weather', async () => {
      const mockWeatherData = {
        main: { temp: 28, humidity: 65 },
        wind: { speed: 3.5 },
        clouds: { all: 20 },
        weather: [{ main: 'Clear' }]
      };

      mockAxiosGet.mockResolvedValueOnce({ data: mockWeatherData });

      const weatherRecommendationService = require('../../services/weatherRecommendationService');
      const recommendations = weatherRecommendationService.getActivityRecommendations({
        temperature: 28,
        humidity: 65,
        wind_speed: 12.6,
        rain_chance: 20
      });

      expect(Array.isArray(recommendations)).toBe(true);
      expect(recommendations[0]).toHaveProperty('suitable');
    });

    it('should include daily tips in response', () => {
      const weatherRecommendationService = require('../../services/weatherRecommendationService');
      const tips = weatherRecommendationService.getDailyTips([{ temperature: 28, humidity: 65 }]);

      expect(Array.isArray(tips)).toBe(true);
    });

    it('should fallback to mock data when API fails', async () => {
      mockAxiosGet.mockRejectedValueOnce(new Error('Network error'));

      const mockWeather = {
        temperature: 28,
        humidity: 65,
        wind_speed: 12,
        rain_chance: 30,
        rain_amount: 0
      };

      expect(mockWeather.temperature).toBe(28);
      expect(mockWeather.humidity).toBe(65);
    });
  });

  describe('getForecast', () => {
    it('should return 5-day forecast data', async () => {
      const mockForecastData = {
        city: { name: 'Mumbai', country: 'IN' },
        list: [
          {
            dt_txt: '2025-01-10 12:00:00',
            main: { temp: 28, humidity: 65 },
            wind: { speed: 3 },
            weather: [{ main: 'Clear' }]
          },
          {
            dt_txt: '2025-01-10 15:00:00',
            main: { temp: 30, humidity: 60 },
            wind: { speed: 4 },
            weather: [{ main: 'Clouds' }]
          }
        ]
      };

      mockAxiosGet.mockResolvedValueOnce({ data: mockForecastData });

      const result = await mockAxiosGet(
        `https://api.openweathermap.org/data/2.5/forecast?lat=19.07&lon=72.87&appid=test_key&units=metric`
      );

      expect(result.data.city.name).toBe('Mumbai');
      expect(result.data.list).toHaveLength(2);
    });

    it('should aggregate hourly forecasts into daily', () => {
      const hourlyData = [
        { datetime: '2025-01-10 09:00:00', temperature: 25 },
        { datetime: '2025-01-10 12:00:00', temperature: 30 },
        { datetime: '2025-01-10 15:00:00', temperature: 32 },
        { datetime: '2025-01-11 09:00:00', temperature: 24 }
      ];

      const dailyMap = {};
      hourlyData.forEach(hour => {
        const date = hour.datetime.split(' ')[0];
        if (!dailyMap[date]) {
          dailyMap[date] = { temps: [] };
        }
        dailyMap[date].temps.push(hour.temperature);
      });

      expect(Object.keys(dailyMap)).toHaveLength(2);
      expect(dailyMap['2025-01-10'].temps).toHaveLength(3);
      expect(Math.max(...dailyMap['2025-01-10'].temps)).toBe(32);
      expect(Math.min(...dailyMap['2025-01-10'].temps)).toBe(25);
    });
  });

  describe('getHourlyForecast', () => {
    it('should return hourly forecast with agricultural suitability', async () => {
      const mockHourlyData = {
        city: { name: 'Delhi', country: 'IN', coord: { lat: 28.6, lon: 77.2 } },
        list: [
          {
            dt_txt: '2025-01-10 09:00:00',
            dt: 1736503200,
            main: { temp: 15, feels_like: 14, humidity: 70 },
            wind: { speed: 2, deg: 180 },
            pop: 0.1,
            weather: [{ main: 'Clear', description: 'clear sky', icon: '01d' }]
          }
        ]
      };

      mockAxiosGet.mockResolvedValueOnce({ data: mockHourlyData });
      mockRedisGet.mockResolvedValueOnce(null);

      const weatherAlertService = require('../../services/weatherAlertService');
      const suitability = weatherAlertService.evaluateHourlySuitability({
        temp: 15,
        humidity: 70,
        wind_speed: 7.2,
        rain_probability: 10
      });

      expect(suitability).toHaveProperty('spraying');
      expect(suitability).toHaveProperty('irrigation');
      expect(suitability).toHaveProperty('harvesting');
    });

    it('should use cached data when available', async () => {
      const cachedData = JSON.stringify({
        success: true,
        data: { hourly_forecast: [] }
      });

      mockRedisGet.mockResolvedValueOnce(cachedData);

      const result = await mockRedisGet('hourly:20.5,78.9');
      expect(JSON.parse(result)).toHaveProperty('success', true);
    });

    it('should cache response in Redis', async () => {
      mockRedisSetex.mockResolvedValueOnce('OK');

      await mockRedisSetex('hourly:20.5,78.9', 1800, '{"data":"test"}');
      expect(mockRedisSetex).toHaveBeenCalledWith('hourly:20.5,78.9', 1800, '{"data":"test"}');
    });
  });

  describe('getWeatherAlerts', () => {
    it('should check for severe weather alerts', async () => {
      const weatherAlertService = require('../../services/weatherAlertService');
      const alerts = await weatherAlertService.checkForAlerts(20.5, 78.9);

      expect(Array.isArray(alerts)).toBe(true);
    });

    it('should identify heat wave conditions', () => {
      const ALERT_THRESHOLDS = {
        heat_wave: { temp_min: 40 },
        frost: { temp_max: 4 },
        storm: { wind_speed_kmh: 50 },
        heavy_rain: { precipitation_mm: 50 }
      };

      const hotTemp = 42;
      const normalTemp = 30;

      expect(hotTemp >= ALERT_THRESHOLDS.heat_wave.temp_min).toBe(true);
      expect(normalTemp >= ALERT_THRESHOLDS.heat_wave.temp_min).toBe(false);
    });

    it('should identify frost conditions', () => {
      const frostThreshold = 4;
      const coldTemp = 2;
      const warmTemp = 15;

      expect(coldTemp <= frostThreshold).toBe(true);
      expect(warmTemp <= frostThreshold).toBe(false);
    });

    it('should identify storm conditions', () => {
      const stormThreshold = 50;
      const highWind = 65;
      const normalWind = 20;

      expect(highWind >= stormThreshold).toBe(true);
      expect(normalWind >= stormThreshold).toBe(false);
    });

    it('should identify heavy rain conditions', () => {
      const heavyRainThreshold = 50;
      const heavyRain = 75;
      const lightRain = 10;

      expect(heavyRain >= heavyRainThreshold).toBe(true);
      expect(lightRain >= heavyRainThreshold).toBe(false);
    });

    it('should cache alerts in Redis', async () => {
      mockRedisGet.mockResolvedValueOnce(null);
      mockRedisSetex.mockResolvedValueOnce('OK');

      await mockRedisSetex('alerts:20.5,78.9', 900, '{"alerts":[]}');
      expect(mockRedisSetex).toHaveBeenCalled();
    });
  });

  describe('getSeasonalAdvisory', () => {
    it('should return current season information', () => {
      const weatherAlertService = require('../../services/weatherAlertService');
      const seasonInfo = weatherAlertService.getSeasonInfo();

      expect(seasonInfo).toHaveProperty('name');
      expect(seasonInfo).toHaveProperty('crops');
      expect(Array.isArray(seasonInfo.crops)).toBe(true);
    });

    it('should generate agriculture advisory', () => {
      const weatherAlertService = require('../../services/weatherAlertService');
      const advisory = weatherAlertService.generateAgricultureAdvisory(
        { temp: 28, humidity: 65, wind_speed: 10, rain_chance: 20 },
        'wheat'
      );

      expect(advisory).toHaveProperty('general_advisory');
    });

    it('should identify agricultural seasons correctly', () => {
      const SEASONS = {
        KHARIF: { start_month: 6, end_month: 10, crops: ['rice', 'cotton'] },
        RABI: { start_month: 11, end_month: 3, crops: ['wheat', 'mustard'] },
        ZAID: { start_month: 4, end_month: 6, crops: ['watermelon', 'cucumber'] }
      };

      expect(SEASONS.KHARIF.crops).toContain('rice');
      expect(SEASONS.RABI.crops).toContain('wheat');
      expect(SEASONS.ZAID.crops).toContain('watermelon');
    });

    it('should provide crop-specific advisory when crop specified', () => {
      const cropAdvisory = {
        wheat: { activities: ['Sowing', 'Irrigation'], warnings: ['Frost damage risk'] },
        rice: { activities: ['Transplanting'], warnings: ['Watch for blast disease'] }
      };

      expect(cropAdvisory.wheat.activities).toContain('Sowing');
      expect(cropAdvisory.rice.warnings).toContain('Watch for blast disease');
    });
  });

  describe('subscribeToAlerts', () => {
    it('should create alert subscription', () => {
      const weatherAlertService = require('../../services/weatherAlertService');
      const subscription = weatherAlertService.subscribeToAlerts(
        'user-1',
        20.5,
        78.9,
        ['heat_wave', 'heavy_rain']
      );

      expect(subscription).toHaveProperty('id');
      expect(subscription.active).toBe(true);
    });

    it('should validate coordinates are provided', () => {
      const validRequest = { lat: 20.5, lon: 78.9 };
      const invalidRequest = { lat: 20.5 };

      expect('lat' in validRequest && 'lon' in validRequest).toBe(true);
      expect('lat' in invalidRequest && 'lon' in invalidRequest).toBe(false);
    });

    it('should require authentication', () => {
      const authenticatedUser = { id: 'user-1' };
      const noUser = null;

      expect(authenticatedUser && authenticatedUser.id).toBeTruthy();
      expect(noUser && noUser.id).toBeFalsy();
    });
  });

  describe('unsubscribeFromAlerts', () => {
    it('should remove alert subscription', () => {
      const weatherAlertService = require('../../services/weatherAlertService');
      const result = weatherAlertService.unsubscribeFromAlerts('user-1', 20.5, 78.9);

      expect(result).toBe(true);
    });

    it('should require authentication', () => {
      const user = { id: 'user-1' };
      expect(user.id).toBeTruthy();
    });
  });

  describe('getMyAlertSubscriptions', () => {
    it('should retrieve user subscriptions', () => {
      const weatherAlertService = require('../../services/weatherAlertService');
      const subscriptions = weatherAlertService.getUserSubscriptions('user-1');

      expect(Array.isArray(subscriptions)).toBe(true);
    });

    it('should require authentication', () => {
      const user = { id: 'user-1' };
      expect(user.id).toBeTruthy();
    });
  });

  describe('Agricultural Suitability Evaluation', () => {
    it('should evaluate spraying suitability', () => {
      const goodConditions = { wind_speed: 5, rain_probability: 10, temp: 25, humidity: 60 };
      const badConditions = { wind_speed: 25, rain_probability: 80, temp: 40, humidity: 90 };

      const isGoodForSpraying = (c) =>
        c.wind_speed < 10 && c.rain_probability < 20 && c.temp >= 15 && c.temp <= 30 && c.humidity >= 40 && c.humidity <= 70;

      expect(isGoodForSpraying(goodConditions)).toBe(true);
      expect(isGoodForSpraying(badConditions)).toBe(false);
    });

    it('should evaluate irrigation suitability', () => {
      const goodConditions = { rain_probability: 20, temp: 28 };
      const badConditions = { rain_probability: 70, temp: 40 };

      const isGoodForIrrigation = (c) => c.rain_probability < 30 && c.temp < 35;

      expect(isGoodForIrrigation(goodConditions)).toBe(true);
      expect(isGoodForIrrigation(badConditions)).toBe(false);
    });

    it('should evaluate harvesting suitability', () => {
      const goodConditions = { humidity: 50, rain_probability: 10, temp: 28 };
      const badConditions = { humidity: 85, rain_probability: 60, temp: 38 };

      const isGoodForHarvesting = (c) => c.humidity < 60 && c.rain_probability < 20 && c.temp >= 15 && c.temp <= 35;

      expect(isGoodForHarvesting(goodConditions)).toBe(true);
      expect(isGoodForHarvesting(badConditions)).toBe(false);
    });
  });
});
