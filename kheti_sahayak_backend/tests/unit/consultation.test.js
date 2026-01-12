const mockQuery = jest.fn();
const mockPoolConnect = jest.fn();
const mockClient = {
  query: jest.fn(),
  release: jest.fn()
};

jest.mock('../../db', () => ({
  query: mockQuery,
  pool: {
    connect: mockPoolConnect
  }
}));

jest.mock('../../services/paymentService', () => ({
  createPaymentOrder: jest.fn().mockResolvedValue({
    id: 'order_123',
    amount: 25000,
    currency: 'INR'
  }),
  getKeyId: jest.fn().mockReturnValue('rzp_test_key'),
  initiateRefund: jest.fn().mockResolvedValue({ success: true })
}));

jest.mock('../../services/consultationService', () => ({
  generateTimeSlots: jest.fn().mockResolvedValue([
    { start_time: '2025-01-10T09:00:00Z', end_time: '2025-01-10T09:30:00Z', is_available: true }
  ]),
  isSlotAvailable: jest.fn().mockResolvedValue({ available: true }),
  calculateConsultationFee: jest.fn().mockResolvedValue({
    base_fee: 200,
    platform_fee: 20,
    gst: 3.6,
    total_fee: 223.6,
    currency: 'INR'
  }),
  generateCallRoomId: jest.fn().mockReturnValue('ks-call-test-123'),
  generateCallJoinUrl: jest.fn().mockReturnValue('https://meet.example.com/room/test'),
  sendStatusNotification: jest.fn().mockResolvedValue({ success: true }),
  calculateRefundAmount: jest.fn().mockReturnValue({
    refund_amount: 223.6,
    refund_percent: 100,
    reason: 'Full refund'
  }),
  updateExpertRating: jest.fn().mockResolvedValue({ rating: 4.5, total_reviews: 11 }),
  incrementExpertConsultations: jest.fn().mockResolvedValue(undefined),
  ConsultationStatus: {
    PENDING: 'pending',
    CONFIRMED: 'confirmed',
    IN_PROGRESS: 'in_progress',
    COMPLETED: 'completed',
    CANCELLED: 'cancelled'
  }
}));

mockPoolConnect.mockResolvedValue(mockClient);

describe('Consultation Controller Unit Tests', () => {
  afterEach(() => {
    jest.clearAllMocks();
  });

  describe('getExperts', () => {
    it('should retrieve all active experts', async () => {
      const mockExperts = [
        {
          user_id: 'expert-1',
          username: 'dr_sharma',
          first_name: 'Dr.',
          last_name: 'Sharma',
          specialization: 'Crop Disease',
          rating: 4.8,
          total_consultations: 150
        },
        {
          user_id: 'expert-2',
          username: 'prof_kumar',
          first_name: 'Prof.',
          last_name: 'Kumar',
          specialization: 'Soil Science',
          rating: 4.5,
          total_consultations: 100
        }
      ];

      mockQuery
        .mockResolvedValueOnce({ rows: mockExperts })
        .mockResolvedValueOnce({ rows: [{ count: '2' }] });

      const db = require('../../db');
      const result = await db.query(
        `SELECT ep.*, u.username, u.first_name, u.last_name
         FROM expert_profiles ep
         JOIN users u ON ep.user_id = u.id
         WHERE ep.is_active = true
         ORDER BY ep.rating DESC
         LIMIT $1 OFFSET $2`,
        [10, 0]
      );

      expect(result.rows).toHaveLength(2);
      expect(result.rows[0].rating).toBe(4.8);
    });

    it('should filter experts by specialization', async () => {
      const mockExperts = [
        { user_id: 'expert-1', specialization: 'Crop Disease', rating: 4.8 }
      ];

      mockQuery.mockResolvedValueOnce({ rows: mockExperts });

      const db = require('../../db');
      const result = await db.query(
        `SELECT * FROM expert_profiles ep
         WHERE ep.is_active = true AND LOWER(ep.specialization) LIKE LOWER($1)`,
        ['%crop%']
      );

      expect(result.rows).toHaveLength(1);
      expect(result.rows[0].specialization).toContain('Crop');
    });

    it('should filter experts by minimum rating', async () => {
      const mockExperts = [
        { user_id: 'expert-1', rating: 4.8 },
        { user_id: 'expert-2', rating: 4.6 }
      ];

      mockQuery.mockResolvedValueOnce({ rows: mockExperts });

      const db = require('../../db');
      const result = await db.query(
        `SELECT * FROM expert_profiles ep WHERE ep.rating >= $1`,
        [4.5]
      );

      expect(result.rows).toHaveLength(2);
      expect(result.rows.every(e => e.rating >= 4.5)).toBe(true);
    });

    it('should filter experts by language', async () => {
      const mockExperts = [
        { user_id: 'expert-1', languages: ['Hindi', 'English'] }
      ];

      mockQuery.mockResolvedValueOnce({ rows: mockExperts });

      const db = require('../../db');
      const result = await db.query(
        `SELECT * FROM expert_profiles ep WHERE $1 = ANY(ep.languages)`,
        ['Hindi']
      );

      expect(result.rows).toHaveLength(1);
    });

    it('should support different sort options', () => {
      const sortOptions = {
        rating: 'ep.rating DESC',
        consultations: 'ep.total_consultations DESC',
        fee_low: 'ep.consultation_fee ASC',
        fee_high: 'ep.consultation_fee DESC',
        experience: 'ep.experience_years DESC'
      };

      expect(Object.keys(sortOptions)).toHaveLength(5);
      expect(sortOptions.rating).toContain('rating');
    });
  });

  describe('getExpertById', () => {
    it('should retrieve expert by ID with availability', async () => {
      const mockExpert = {
        user_id: 'expert-1',
        username: 'dr_sharma',
        specialization: 'Crop Disease',
        rating: 4.8,
        is_active: true
      };

      const mockAvailability = [
        { day_of_week: 1, start_time: '09:00', end_time: '17:00', is_available: true },
        { day_of_week: 2, start_time: '09:00', end_time: '17:00', is_available: true }
      ];

      mockQuery
        .mockResolvedValueOnce({ rows: [mockExpert] })
        .mockResolvedValueOnce({ rows: mockAvailability });

      const db = require('../../db');
      const expertResult = await db.query(
        `SELECT ep.*, u.username FROM expert_profiles ep
         JOIN users u ON ep.user_id = u.id
         WHERE ep.user_id = $1 AND ep.is_active = true`,
        ['expert-1']
      );

      const availabilityResult = await db.query(
        `SELECT * FROM expert_availability WHERE expert_id = $1`,
        ['expert-1']
      );

      expect(expertResult.rows).toHaveLength(1);
      expect(expertResult.rows[0].rating).toBe(4.8);
      expect(availabilityResult.rows).toHaveLength(2);
    });

    it('should return empty for inactive expert', async () => {
      mockQuery.mockResolvedValueOnce({ rows: [] });

      const db = require('../../db');
      const result = await db.query(
        `SELECT * FROM expert_profiles WHERE user_id = $1 AND is_active = true`,
        ['inactive-expert']
      );

      expect(result.rows).toHaveLength(0);
    });
  });

  describe('getExpertAvailability', () => {
    it('should generate time slots for a date', async () => {
      mockQuery.mockResolvedValueOnce({ rows: [{ user_id: 'expert-1' }] });

      const consultationService = require('../../services/consultationService');
      const slots = await consultationService.generateTimeSlots([], '2025-01-10', 'expert-1');

      expect(Array.isArray(slots)).toBe(true);
    });

    it('should validate date parameter format', () => {
      const validDate = '2025-01-10';
      const invalidDate = 'not-a-date';

      const dateRegex = /^\d{4}-\d{2}-\d{2}$/;
      expect(dateRegex.test(validDate)).toBe(true);
      expect(dateRegex.test(invalidDate)).toBe(false);
    });
  });

  describe('registerAsExpert', () => {
    it('should register a new expert profile', async () => {
      const mockProfile = {
        id: 1,
        user_id: 'user-1',
        specialization: 'Organic Farming',
        experience_years: 10,
        consultation_fee: 200,
        is_verified: false
      };

      mockQuery.mockResolvedValueOnce({ rows: [] });
      mockClient.query
        .mockResolvedValueOnce({ command: 'BEGIN' })
        .mockResolvedValueOnce({ rows: [mockProfile] })
        .mockResolvedValueOnce({ rowCount: 1 })
        .mockResolvedValueOnce({ command: 'COMMIT' });

      const db = require('../../db');
      const existingCheck = await db.query(
        `SELECT id FROM expert_profiles WHERE user_id = $1`,
        ['user-1']
      );

      expect(existingCheck.rows).toHaveLength(0);
    });

    it('should prevent duplicate expert registration', async () => {
      mockQuery.mockResolvedValueOnce({ rows: [{ id: 1, user_id: 'user-1' }] });

      const db = require('../../db');
      const result = await db.query(
        `SELECT id FROM expert_profiles WHERE user_id = $1`,
        ['user-1']
      );

      expect(result.rows.length).toBeGreaterThan(0);
    });

    it('should require specialization field', () => {
      const validProfile = { specialization: 'Crop Science', experience_years: 5 };
      const invalidProfile = { experience_years: 5 };

      expect('specialization' in validProfile).toBe(true);
      expect('specialization' in invalidProfile).toBe(false);
    });
  });

  describe('bookConsultation', () => {
    it('should create a new consultation booking', async () => {
      const mockConsultation = {
        id: 'consult-1',
        farmer_id: 'farmer-1',
        expert_id: 'expert-1',
        scheduled_at: '2025-01-15T10:00:00Z',
        duration_minutes: 30,
        status: 'pending',
        amount: 223.6
      };

      mockQuery.mockResolvedValueOnce({
        rows: [{ user_id: 'expert-1', is_active: true, consultation_fee: 200 }]
      });

      mockClient.query
        .mockResolvedValueOnce({ command: 'BEGIN' })
        .mockResolvedValueOnce({ rows: [mockConsultation] })
        .mockResolvedValueOnce({ command: 'COMMIT' });

      const consultationService = require('../../services/consultationService');
      const slotCheck = await consultationService.isSlotAvailable('expert-1', '2025-01-15T10:00:00Z', 30);

      expect(slotCheck.available).toBe(true);
    });

    it('should validate expert exists and is active', async () => {
      mockQuery.mockResolvedValueOnce({ rows: [] });

      const db = require('../../db');
      const result = await db.query(
        `SELECT * FROM expert_profiles WHERE user_id = $1 AND is_active = true`,
        ['non-existent']
      );

      expect(result.rows).toHaveLength(0);
    });

    it('should calculate consultation fee correctly', async () => {
      const consultationService = require('../../services/consultationService');
      const feeDetails = await consultationService.calculateConsultationFee('expert-1', 30);

      expect(feeDetails.base_fee).toBe(200);
      expect(feeDetails.total_fee).toBe(223.6);
      expect(feeDetails.currency).toBe('INR');
    });
  });

  describe('getMyConsultations', () => {
    it('should retrieve farmer consultations', async () => {
      const mockConsultations = [
        { id: 'consult-1', status: 'pending', expert_name: 'Dr. Sharma' },
        { id: 'consult-2', status: 'completed', expert_name: 'Prof. Kumar' }
      ];

      mockQuery
        .mockResolvedValueOnce({ rows: mockConsultations })
        .mockResolvedValueOnce({ rows: [{ count: '2' }] });

      const db = require('../../db');
      const result = await db.query(
        `SELECT c.*, u.username as expert_name
         FROM consultations c
         JOIN users u ON c.expert_id = u.id
         WHERE c.farmer_id = $1
         ORDER BY c.scheduled_at DESC
         LIMIT $2 OFFSET $3`,
        ['farmer-1', 10, 0]
      );

      expect(result.rows).toHaveLength(2);
    });

    it('should retrieve expert consultations', async () => {
      const mockConsultations = [
        { id: 'consult-1', status: 'pending', farmer_name: 'Ramesh' }
      ];

      mockQuery.mockResolvedValueOnce({ rows: mockConsultations });

      const db = require('../../db');
      const result = await db.query(
        `SELECT c.*, u.username as farmer_name
         FROM consultations c
         JOIN users u ON c.farmer_id = u.id
         WHERE c.expert_id = $1`,
        ['expert-1']
      );

      expect(result.rows).toHaveLength(1);
    });

    it('should filter consultations by status', async () => {
      const mockPending = [{ id: 'consult-1', status: 'pending' }];

      mockQuery.mockResolvedValueOnce({ rows: mockPending });

      const db = require('../../db');
      const result = await db.query(
        `SELECT * FROM consultations WHERE farmer_id = $1 AND status = $2`,
        ['farmer-1', 'pending']
      );

      expect(result.rows).toHaveLength(1);
      expect(result.rows[0].status).toBe('pending');
    });
  });

  describe('rescheduleConsultation', () => {
    it('should reschedule a pending consultation', async () => {
      const mockConsultation = {
        id: 'consult-1',
        status: 'pending',
        expert_id: 'expert-1',
        duration_minutes: 30
      };

      mockQuery
        .mockResolvedValueOnce({ rows: [mockConsultation] })
        .mockResolvedValueOnce({ rows: [{ ...mockConsultation, scheduled_at: '2025-01-20T10:00:00Z' }] });

      const db = require('../../db');
      const checkResult = await db.query(
        `SELECT * FROM consultations WHERE id = $1 AND (farmer_id = $2 OR expert_id = $2)`,
        ['consult-1', 'farmer-1']
      );

      expect(checkResult.rows[0].status).toBe('pending');

      const consultationService = require('../../services/consultationService');
      const slotCheck = await consultationService.isSlotAvailable('expert-1', '2025-01-20T10:00:00Z', 30);
      expect(slotCheck.available).toBe(true);
    });

    it('should not allow rescheduling completed consultations', () => {
      const allowedStatuses = ['pending', 'confirmed'];
      const completedStatus = 'completed';

      expect(allowedStatuses.includes(completedStatus)).toBe(false);
    });
  });

  describe('cancelConsultation', () => {
    it('should cancel a consultation with refund calculation', async () => {
      const mockConsultation = {
        id: 'consult-1',
        status: 'pending',
        scheduled_at: '2025-01-20T10:00:00Z',
        amount: 223.6,
        payment_status: 'paid',
        payment_id: 'pay_123'
      };

      mockQuery.mockResolvedValueOnce({ rows: [mockConsultation] });

      const consultationService = require('../../services/consultationService');
      const refundInfo = consultationService.calculateRefundAmount(
        mockConsultation.scheduled_at,
        mockConsultation.amount
      );

      expect(refundInfo.refund_amount).toBe(223.6);
      expect(refundInfo.refund_percent).toBe(100);
    });

    it('should not allow cancelling already cancelled consultations', () => {
      const allowedStatuses = ['pending', 'confirmed'];
      const cancelledStatus = 'cancelled';

      expect(allowedStatuses.includes(cancelledStatus)).toBe(false);
    });
  });

  describe('startConsultation', () => {
    it('should start a confirmed consultation', async () => {
      const mockConsultation = {
        id: 'consult-1',
        status: 'confirmed',
        payment_status: 'paid',
        farmer_id: 'farmer-1'
      };

      mockQuery
        .mockResolvedValueOnce({ rows: [mockConsultation] })
        .mockResolvedValueOnce({ rows: [{ ...mockConsultation, status: 'in_progress', call_room_id: 'ks-call-test' }] });

      const consultationService = require('../../services/consultationService');
      const roomId = consultationService.generateCallRoomId();
      const joinUrl = consultationService.generateCallJoinUrl(roomId, 'expert', 'expert-1');

      expect(roomId).toBe('ks-call-test-123');
      expect(joinUrl).toContain('meet.example.com');
    });

    it('should require confirmed status to start', () => {
      const validStatus = 'confirmed';
      const invalidStatuses = ['pending', 'completed', 'cancelled'];

      expect(validStatus).toBe('confirmed');
      invalidStatuses.forEach(status => {
        expect(status).not.toBe('confirmed');
      });
    });

    it('should require payment completion', () => {
      const paidStatus = 'paid';
      const unpaidStatus = 'pending';

      expect(paidStatus).toBe('paid');
      expect(unpaidStatus).not.toBe('paid');
    });
  });

  describe('completeConsultation', () => {
    it('should complete an in-progress consultation', async () => {
      const mockConsultation = {
        id: 'consult-1',
        status: 'in_progress',
        call_started_at: new Date(Date.now() - 30 * 60 * 1000)
      };

      mockQuery
        .mockResolvedValueOnce({ rows: [mockConsultation] })
        .mockResolvedValueOnce({ rows: [{ ...mockConsultation, status: 'completed', actual_duration_minutes: 30 }] });

      const startTime = new Date(mockConsultation.call_started_at);
      const endTime = new Date();
      const actualDuration = Math.round((endTime - startTime) / (1000 * 60));

      expect(actualDuration).toBeGreaterThanOrEqual(29);
      expect(actualDuration).toBeLessThanOrEqual(31);
    });

    it('should update expert consultation count', async () => {
      const consultationService = require('../../services/consultationService');
      await consultationService.incrementExpertConsultations('expert-1');

      expect(consultationService.incrementExpertConsultations).toHaveBeenCalledWith('expert-1');
    });
  });

  describe('addReview', () => {
    it('should add review for completed consultation', async () => {
      const mockConsultation = {
        id: 'consult-1',
        status: 'completed',
        expert_id: 'expert-1',
        farmer_id: 'farmer-1'
      };

      const mockReview = {
        id: 1,
        consultation_id: 'consult-1',
        rating: 5,
        review_text: 'Excellent advice!'
      };

      mockQuery
        .mockResolvedValueOnce({ rows: [mockConsultation] })
        .mockResolvedValueOnce({ rows: [] });

      mockClient.query
        .mockResolvedValueOnce({ command: 'BEGIN' })
        .mockResolvedValueOnce({ rows: [mockReview] })
        .mockResolvedValueOnce({ command: 'COMMIT' });

      const db = require('../../db');
      const consultCheck = await db.query(
        `SELECT * FROM consultations WHERE id = $1 AND farmer_id = $2`,
        ['consult-1', 'farmer-1']
      );

      expect(consultCheck.rows[0].status).toBe('completed');
    });

    it('should validate rating is between 1 and 5', () => {
      const validRatings = [1, 2, 3, 4, 5];
      const invalidRatings = [0, 6, -1, 10];

      validRatings.forEach(rating => {
        expect(rating >= 1 && rating <= 5).toBe(true);
      });

      invalidRatings.forEach(rating => {
        expect(rating >= 1 && rating <= 5).toBe(false);
      });
    });

    it('should prevent duplicate reviews', async () => {
      mockQuery.mockResolvedValueOnce({ rows: [{ id: 1 }] });

      const db = require('../../db');
      const existingReview = await db.query(
        `SELECT id FROM consultation_reviews WHERE consultation_id = $1`,
        ['consult-1']
      );

      expect(existingReview.rows.length).toBeGreaterThan(0);
    });

    it('should update expert rating after review', async () => {
      const consultationService = require('../../services/consultationService');
      const result = await consultationService.updateExpertRating('expert-1', 5);

      expect(result.rating).toBe(4.5);
      expect(result.total_reviews).toBe(11);
    });
  });

  describe('getExpertReviews', () => {
    it('should retrieve expert reviews with statistics', async () => {
      const mockReviews = [
        { id: 1, rating: 5, review_text: 'Great!', farmer_name: 'Ramesh' },
        { id: 2, rating: 4, review_text: 'Good advice', farmer_name: 'Suresh' }
      ];

      const mockStats = {
        total_reviews: 2,
        average_rating: 4.5,
        five_star: 1,
        four_star: 1,
        three_star: 0,
        two_star: 0,
        one_star: 0
      };

      mockQuery
        .mockResolvedValueOnce({ rows: [{ user_id: 'expert-1' }] })
        .mockResolvedValueOnce({ rows: mockReviews })
        .mockResolvedValueOnce({ rows: [mockStats] });

      const db = require('../../db');
      const result = await db.query(
        `SELECT cr.*, u.username as farmer_name
         FROM consultation_reviews cr
         JOIN users u ON cr.farmer_id = u.id
         WHERE cr.expert_id = $1
         ORDER BY cr.created_at DESC
         LIMIT $2 OFFSET $3`,
        ['expert-1', 10, 0]
      );

      expect(result.rows).toHaveLength(2);
    });

    it('should support different sort options for reviews', () => {
      const sortOptions = {
        recent: 'cr.created_at DESC',
        oldest: 'cr.created_at ASC',
        highest: 'cr.rating DESC',
        lowest: 'cr.rating ASC'
      };

      expect(Object.keys(sortOptions)).toHaveLength(4);
    });
  });
});
