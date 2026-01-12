const mockAxiosGet = jest.fn();
const mockAxiosPost = jest.fn();
const mockRedisGet = jest.fn();
const mockRedisSetex = jest.fn();
const mockDbQuery = jest.fn();

jest.mock('axios', () => ({
  get: mockAxiosGet,
  post: mockAxiosPost
}));

jest.mock('../../redisClient', () => ({
  get: mockRedisGet,
  setex: mockRedisSetex
}));

jest.mock('../../db', () => ({
  query: mockDbQuery
}));

const mandiPriceService = require('../../services/mandiPriceService');

describe('Mandi Price Service Unit Tests', () => {
  beforeEach(() => {
    jest.clearAllMocks();
    mockRedisGet.mockResolvedValue(null);
    mockRedisSetex.mockResolvedValue('OK');
  });

  describe('getMandiPrices', () => {
    it('should return cached data if available', async () => {
      const cachedData = {
        success: true,
        source: 'Cached',
        data: [{ commodity: 'Rice', modal_price: 2800 }]
      };
      mockRedisGet.mockResolvedValue(JSON.stringify(cachedData));

      const result = await mandiPriceService.getMandiPrices({ state: 'Maharashtra' });

      expect(result).toEqual(cachedData);
      expect(mockRedisGet).toHaveBeenCalled();
    });

    it('should generate mock data when external APIs fail', async () => {
      mockRedisGet.mockResolvedValue(null);
      mockAxiosGet.mockRejectedValue(new Error('API Error'));
      mockDbQuery.mockResolvedValue({ rows: [] });

      const result = await mandiPriceService.getMandiPrices({ 
        state: 'Maharashtra', 
        commodity: 'Rice' 
      });

      expect(result.success).toBe(true);
      expect(result.data).toBeDefined();
      expect(result.data.length).toBeGreaterThan(0);
      expect(result.data[0].commodity).toBe('Rice');
    });

    it('should filter by market when provided', async () => {
      mockRedisGet.mockResolvedValue(null);
      mockDbQuery.mockResolvedValue({ rows: [] });

      const result = await mandiPriceService.getMandiPrices({ 
        state: 'Maharashtra',
        market: 'Nashik'
      });

      expect(result.success).toBe(true);
      const nashikResults = result.data.filter(p => 
        p.market.toLowerCase().includes('nashik')
      );
      expect(nashikResults.length).toBeGreaterThan(0);
    });

    it('should cache results with proper TTL', async () => {
      mockRedisGet.mockResolvedValue(null);
      mockDbQuery.mockResolvedValue({ rows: [] });

      await mandiPriceService.getMandiPrices({ state: 'Maharashtra' });

      expect(mockRedisSetex).toHaveBeenCalled();
      const [key, ttl] = mockRedisSetex.mock.calls[0];
      expect(key).toContain('mandi:prices');
      expect(ttl).toBe(900);
    });
  });

  describe('getPriceTrends', () => {
    it('should return trend data from database', async () => {
      const mockTrendData = [
        { arrival_date: '2025-01-10', commodity: 'Rice', state: 'Maharashtra', avg_price: 2800, min_price: 2600, max_price: 3000, market_count: 5 },
        { arrival_date: '2025-01-11', commodity: 'Rice', state: 'Maharashtra', avg_price: 2850, min_price: 2650, max_price: 3050, market_count: 5 }
      ];
      mockRedisGet.mockResolvedValue(null);
      mockDbQuery.mockResolvedValue({ rows: mockTrendData });

      const result = await mandiPriceService.getPriceTrends({ 
        commodity: 'Rice', 
        period: 'weekly' 
      });

      expect(result.success).toBe(true);
      expect(result.trends).toBeDefined();
      expect(result.price_change).toBeDefined();
      expect(result.price_change_percent).toBeDefined();
    });

    it('should calculate price change percentage correctly', async () => {
      const mockTrendData = [
        { arrival_date: '2025-01-10', commodity: 'Rice', state: 'MH', avg_price: '1000', min_price: 900, max_price: 1100, market_count: 5 },
        { arrival_date: '2025-01-11', commodity: 'Rice', state: 'MH', avg_price: '1100', min_price: 1000, max_price: 1200, market_count: 5 }
      ];
      mockRedisGet.mockResolvedValue(null);
      mockDbQuery.mockResolvedValue({ rows: mockTrendData });

      const result = await mandiPriceService.getPriceTrends({ commodity: 'Rice' });

      expect(result.price_change).toBe(100);
      expect(result.price_change_percent).toBe(10);
    });
  });

  describe('getMSPPrices', () => {
    it('should return MSP data for specified crop', async () => {
      const mockMSP = [
        { crop_name: 'Rice', msp_price: 2300, year: 2025, variety: 'Common' }
      ];
      mockRedisGet.mockResolvedValue(null);
      mockDbQuery.mockResolvedValue({ rows: mockMSP });

      const result = await mandiPriceService.getMSPPrices({ crop: 'Rice', year: 2025 });

      expect(result.success).toBe(true);
      expect(result.data).toEqual(mockMSP);
      expect(result.year).toBe(2025);
    });

    it('should return all MSP data when no crop specified', async () => {
      const mockMSP = [
        { crop_name: 'Rice', msp_price: 2300, year: 2025 },
        { crop_name: 'Wheat', msp_price: 2275, year: 2025 }
      ];
      mockRedisGet.mockResolvedValue(null);
      mockDbQuery.mockResolvedValue({ rows: mockMSP });

      const result = await mandiPriceService.getMSPPrices({ year: 2025 });

      expect(result.success).toBe(true);
      expect(result.count).toBe(2);
    });
  });

  describe('comparePriceWithMSP', () => {
    it('should compare market prices with MSP correctly', async () => {
      const mockMSP = [{ crop_name: 'Rice', msp_price: 2300, year: 2025 }];
      const cachedMandiData = {
        success: true,
        data: [
          { commodity: 'Rice', modal_price: 2500, market: 'Nashik APMC', state: 'Maharashtra' }
        ]
      };

      mockRedisGet
        .mockResolvedValueOnce(null)
        .mockResolvedValueOnce(JSON.stringify(cachedMandiData));
      mockDbQuery.mockResolvedValue({ rows: mockMSP });

      const result = await mandiPriceService.comparePriceWithMSP({ 
        commodity: 'Rice', 
        state: 'Maharashtra' 
      });

      expect(result.success).toBe(true);
      expect(result.msp_available).toBe(true);
      expect(result.msp_price).toBe(2300);
      expect(result.comparisons[0].status).toBe('ABOVE_MSP');
    });

    it('should return appropriate message when MSP not available', async () => {
      mockRedisGet.mockResolvedValue(null);
      mockDbQuery.mockResolvedValue({ rows: [] });

      const result = await mandiPriceService.comparePriceWithMSP({ 
        commodity: 'Tomato'
      });

      expect(result.success).toBe(true);
      expect(result.msp_available).toBe(false);
    });

    it('should require commodity parameter', async () => {
      const result = await mandiPriceService.comparePriceWithMSP({});

      expect(result.success).toBe(false);
      expect(result.error).toBe('Commodity is required');
    });
  });

  describe('Price Alert Functions', () => {
    const mockUserId = 'user-123';

    describe('createPriceAlert', () => {
      it('should create a price alert successfully', async () => {
        const alertData = {
          commodity: 'Rice',
          state: 'Maharashtra',
          threshold_price: 2500,
          threshold_direction: 'above'
        };

        mockDbQuery.mockResolvedValue({ 
          rows: [{ id: 'alert-1', ...alertData, user_id: mockUserId }]
        });

        const result = await mandiPriceService.createPriceAlert(mockUserId, alertData);

        expect(result.success).toBe(true);
        expect(result.data.commodity).toBe('Rice');
        expect(mockDbQuery).toHaveBeenCalled();
      });

      it('should require commodity', async () => {
        const result = await mandiPriceService.createPriceAlert(mockUserId, {});

        expect(result.success).toBe(false);
        expect(result.error).toBe('Commodity is required');
      });
    });

    describe('getUserPriceAlerts', () => {
      it('should return user alerts', async () => {
        const mockAlerts = [
          { id: 'alert-1', commodity: 'Rice', threshold_price: 2500 },
          { id: 'alert-2', commodity: 'Wheat', threshold_price: 2200 }
        ];
        mockDbQuery.mockResolvedValue({ rows: mockAlerts });

        const result = await mandiPriceService.getUserPriceAlerts(mockUserId);

        expect(result.success).toBe(true);
        expect(result.count).toBe(2);
        expect(result.data).toEqual(mockAlerts);
      });
    });

    describe('updatePriceAlert', () => {
      it('should update alert successfully', async () => {
        mockDbQuery.mockResolvedValue({ 
          rows: [{ id: 'alert-1', threshold_price: 3000 }]
        });

        const result = await mandiPriceService.updatePriceAlert(
          mockUserId, 
          'alert-1', 
          { threshold_price: 3000 }
        );

        expect(result.success).toBe(true);
        expect(result.data.threshold_price).toBe(3000);
      });

      it('should return error for invalid fields', async () => {
        const result = await mandiPriceService.updatePriceAlert(
          mockUserId, 
          'alert-1', 
          { invalid_field: 'value' }
        );

        expect(result.success).toBe(false);
        expect(result.error).toBe('No valid fields to update');
      });
    });

    describe('deletePriceAlert', () => {
      it('should delete alert successfully', async () => {
        mockDbQuery.mockResolvedValue({ rows: [{ id: 'alert-1' }] });

        const result = await mandiPriceService.deletePriceAlert(mockUserId, 'alert-1');

        expect(result.success).toBe(true);
      });

      it('should return error when alert not found', async () => {
        mockDbQuery.mockResolvedValue({ rows: [] });

        const result = await mandiPriceService.deletePriceAlert(mockUserId, 'invalid-id');

        expect(result.success).toBe(false);
        expect(result.error).toBe('Alert not found or unauthorized');
      });
    });
  });

  describe('Helper Functions', () => {
    describe('getStates', () => {
      it('should return list of Indian states', () => {
        const states = mandiPriceService.getStates();

        expect(Array.isArray(states)).toBe(true);
        expect(states).toContain('Maharashtra');
        expect(states).toContain('Punjab');
        expect(states).toContain('Uttar Pradesh');
      });
    });

    describe('getSupportedCommodities', () => {
      it('should return list of commodities with Hindi names', () => {
        const commodities = mandiPriceService.getSupportedCommodities();

        expect(Array.isArray(commodities)).toBe(true);
        expect(commodities.length).toBeGreaterThan(0);
        
        const rice = commodities.find(c => c.name === 'Rice');
        expect(rice).toBeDefined();
        expect(rice.name_hi).toBeDefined();
        expect(rice.category).toBeDefined();
      });
    });
  });
});
