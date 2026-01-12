/**
 * Unit Tests for Consultation Service
 */

const mockQuery = jest.fn();
jest.mock('../../db', () => ({
  query: mockQuery
}));

const mockSendToUser = jest.fn();
jest.mock('../../services/pushNotificationService', () => ({
  sendToUser: mockSendToUser
}));

const consultationService = require('../../services/consultationService');

describe('Consultation Service', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  describe('Constants', () => {
    it('should define ConsultationStatus enum', () => {
      expect(consultationService.ConsultationStatus.PENDING).toBe('pending');
      expect(consultationService.ConsultationStatus.CONFIRMED).toBe('confirmed');
      expect(consultationService.ConsultationStatus.IN_PROGRESS).toBe('in_progress');
      expect(consultationService.ConsultationStatus.COMPLETED).toBe('completed');
      expect(consultationService.ConsultationStatus.CANCELLED).toBe('cancelled');
      expect(consultationService.ConsultationStatus.NO_SHOW).toBe('no_show');
    });

    it('should define PaymentStatus enum', () => {
      expect(consultationService.PaymentStatus.PENDING).toBe('pending');
      expect(consultationService.PaymentStatus.PAID).toBe('paid');
      expect(consultationService.PaymentStatus.REFUNDED).toBe('refunded');
      expect(consultationService.PaymentStatus.FAILED).toBe('failed');
    });

    it('should define ConsultationType enum', () => {
      expect(consultationService.ConsultationType.VIDEO).toBe('video');
      expect(consultationService.ConsultationType.AUDIO).toBe('audio');
      expect(consultationService.ConsultationType.CHAT).toBe('chat');
    });

    it('should define CancellationPolicy', () => {
      expect(consultationService.CancellationPolicy.FREE_CANCELLATION_HOURS).toBe(24);
      expect(consultationService.CancellationPolicy.PARTIAL_REFUND_HOURS).toBe(12);
      expect(consultationService.CancellationPolicy.PARTIAL_REFUND_PERCENT).toBe(50);
    });

    it('should define BookingRules', () => {
      expect(consultationService.BookingRules.MIN_ADVANCE_HOURS).toBe(24);
      expect(consultationService.BookingRules.PAYMENT_TIMEOUT_MINUTES).toBe(30);
    });
  });

  describe('getExpertBookingsForDate', () => {
    it('should return expert bookings for a specific date', async () => {
      const mockBookings = [
        { scheduled_at: new Date(), duration_minutes: 30, status: 'confirmed' },
        { scheduled_at: new Date(), duration_minutes: 60, status: 'pending' }
      ];
      mockQuery.mockResolvedValueOnce({ rows: mockBookings });

      const result = await consultationService.getExpertBookingsForDate('expert-1', '2025-01-15');

      expect(mockQuery).toHaveBeenCalledWith(
        expect.stringContaining('SELECT scheduled_at'),
        ['expert-1', '2025-01-15']
      );
      expect(result).toHaveLength(2);
    });

    it('should return empty array when no bookings', async () => {
      mockQuery.mockResolvedValueOnce({ rows: [] });

      const result = await consultationService.getExpertBookingsForDate('expert-1', '2025-01-20');

      expect(result).toHaveLength(0);
    });
  });

  describe('generateTimeSlots', () => {
    it('should return empty array when no availability for day', async () => {
      const availability = [
        { day_of_week: 1, is_available: true, start_time: '09:00', end_time: '17:00', slot_duration_minutes: 30 }
      ];
      const dateStr = '2025-01-12'; // Sunday (day 0)

      const result = await consultationService.generateTimeSlots(availability, dateStr, 'expert-1');

      expect(result).toEqual([]);
    });

    it('should generate time slots for available day', async () => {
      mockQuery.mockResolvedValueOnce({ rows: [] }); // No existing bookings

      const availability = [
        { day_of_week: 1, is_available: true, start_time: '09:00', end_time: '11:00', slot_duration_minutes: 30 }
      ];
      // Use a future date that is Monday (day 1)
      const futureDate = new Date();
      futureDate.setDate(futureDate.getDate() + 30);
      while (futureDate.getDay() !== 1) {
        futureDate.setDate(futureDate.getDate() + 1);
      }
      const dateStr = futureDate.toISOString().split('T')[0];

      const result = await consultationService.generateTimeSlots(availability, dateStr, 'expert-1');

      expect(Array.isArray(result)).toBe(true);
    });

    it('should exclude already booked slots', async () => {
      const bookedTime = new Date();
      bookedTime.setDate(bookedTime.getDate() + 2);
      bookedTime.setHours(10, 0, 0, 0);

      mockQuery.mockResolvedValueOnce({
        rows: [{ scheduled_at: bookedTime, duration_minutes: 30, status: 'confirmed' }]
      });

      const availability = [
        { day_of_week: bookedTime.getDay(), is_available: true, start_time: '09:00', end_time: '12:00', slot_duration_minutes: 30 }
      ];

      const result = await consultationService.generateTimeSlots(
        availability,
        bookedTime.toISOString().split('T')[0],
        'expert-1'
      );

      const bookedSlotExists = result.some(
        slot => new Date(slot.start_time).getTime() === bookedTime.getTime()
      );
      expect(bookedSlotExists).toBe(false);
    });
  });

  describe('isSlotAvailable', () => {
    it('should return unavailable if booking is too soon', async () => {
      const now = new Date();
      const tooSoon = new Date(now.getTime() + 12 * 60 * 60 * 1000); // 12 hours from now

      const result = await consultationService.isSlotAvailable('expert-1', tooSoon.toISOString());

      expect(result.available).toBe(false);
      expect(result.reason).toContain('24 hours in advance');
    });

    it('should return unavailable when expert not available at time', async () => {
      const futureDate = new Date();
      futureDate.setDate(futureDate.getDate() + 3);

      mockQuery.mockResolvedValueOnce({ rows: [] }); // No availability

      const result = await consultationService.isSlotAvailable('expert-1', futureDate.toISOString());

      expect(result.available).toBe(false);
      expect(result.reason).toContain('not available');
    });

    it('should return unavailable when slot already booked', async () => {
      const futureDate = new Date();
      futureDate.setDate(futureDate.getDate() + 3);

      mockQuery
        .mockResolvedValueOnce({ rows: [{ id: 'avail-1' }] }) // Availability exists
        .mockResolvedValueOnce({ rows: [{ id: 'booking-1' }] }); // Conflicting booking

      const result = await consultationService.isSlotAvailable('expert-1', futureDate.toISOString());

      expect(result.available).toBe(false);
      expect(result.reason).toContain('already booked');
    });

    it('should return available when slot is free', async () => {
      const futureDate = new Date();
      futureDate.setDate(futureDate.getDate() + 3);

      mockQuery
        .mockResolvedValueOnce({ rows: [{ id: 'avail-1' }] }) // Availability exists
        .mockResolvedValueOnce({ rows: [] }); // No conflicting bookings

      const result = await consultationService.isSlotAvailable('expert-1', futureDate.toISOString());

      expect(result.available).toBe(true);
    });
  });

  describe('calculateConsultationFee', () => {
    it('should calculate fee for 30-minute consultation', async () => {
      mockQuery.mockResolvedValueOnce({
        rows: [{ consultation_fee: '500' }]
      });

      const result = await consultationService.calculateConsultationFee('expert-1', 30);

      expect(result.base_fee).toBe(500);
      expect(result.platform_fee).toBe(50); // 10% of 500
      expect(result.gst).toBe(9); // 18% of platform fee
      expect(result.total_fee).toBe(559);
      expect(result.currency).toBe('INR');
    });

    it('should calculate fee for 60-minute consultation (2 slots)', async () => {
      mockQuery.mockResolvedValueOnce({
        rows: [{ consultation_fee: '500' }]
      });

      const result = await consultationService.calculateConsultationFee('expert-1', 60);

      expect(result.base_fee).toBe(1000); // 2 slots * 500
    });

    it('should throw error when expert not found', async () => {
      mockQuery.mockResolvedValueOnce({ rows: [] });

      await expect(
        consultationService.calculateConsultationFee('non-existent', 30)
      ).rejects.toThrow('Expert profile not found');
    });

    it('should include fee breakdown', async () => {
      mockQuery.mockResolvedValueOnce({
        rows: [{ consultation_fee: '1000' }]
      });

      const result = await consultationService.calculateConsultationFee('expert-1', 30);

      expect(result.breakdown).toBeDefined();
      expect(result.breakdown.expert_earnings).toBeDefined();
      expect(result.breakdown.platform_earnings).toBeDefined();
    });
  });

  describe('generateCallRoomId', () => {
    it('should generate unique room IDs', () => {
      const roomId1 = consultationService.generateCallRoomId();
      const roomId2 = consultationService.generateCallRoomId();

      expect(roomId1).not.toBe(roomId2);
      expect(roomId1).toMatch(/^ks-call-/);
      expect(roomId2).toMatch(/^ks-call-/);
    });

    it('should include timestamp in room ID', () => {
      const roomId = consultationService.generateCallRoomId();
      const parts = roomId.split('-');

      expect(parts.length).toBeGreaterThanOrEqual(4);
    });
  });

  describe('generateCallJoinUrl', () => {
    it('should generate join URL with token and role', () => {
      const roomId = 'ks-call-test-123';
      const userId = 'user-1';

      const url = consultationService.generateCallJoinUrl(roomId, 'farmer', userId);

      expect(url).toContain(roomId);
      expect(url).toContain('token=');
      expect(url).toContain('role=farmer');
    });

    it('should generate different tokens for different users', () => {
      const roomId = 'ks-call-test-123';

      const farmerUrl = consultationService.generateCallJoinUrl(roomId, 'farmer', 'farmer-1');
      const expertUrl = consultationService.generateCallJoinUrl(roomId, 'expert', 'expert-1');

      const farmerToken = farmerUrl.match(/token=([^&]+)/)[1];
      const expertToken = expertUrl.match(/token=([^&]+)/)[1];

      expect(farmerToken).not.toBe(expertToken);
    });
  });

  describe('sendConsultationReminder', () => {
    it('should send reminders to both farmer and expert', async () => {
      mockQuery.mockResolvedValueOnce({
        rows: [{
          farmer_id: 'farmer-1',
          expert_id: 'expert-1',
          farmer_name: 'Farmer John',
          expert_name: 'Expert Jane',
          farmer_email: 'farmer@example.com',
          expert_email: 'expert@example.com',
          specialization: 'Crop Disease',
          scheduled_at: new Date()
        }]
      });
      mockSendToUser.mockResolvedValue({ success: true });

      const result = await consultationService.sendConsultationReminder('consultation-1');

      expect(result.success).toBe(true);
      expect(mockSendToUser).toHaveBeenCalledTimes(2);
    });

    it('should return failure when consultation not found', async () => {
      mockQuery.mockResolvedValueOnce({ rows: [] });

      const result = await consultationService.sendConsultationReminder('non-existent');

      expect(result.success).toBe(false);
      expect(result.message).toBe('Consultation not found');
    });

    it('should handle notification errors', async () => {
      mockQuery.mockResolvedValueOnce({
        rows: [{ farmer_id: 'f1', expert_id: 'e1', farmer_name: 'F', expert_name: 'E', scheduled_at: new Date() }]
      });
      mockSendToUser.mockRejectedValue(new Error('Push failed'));
      const consoleSpy = jest.spyOn(console, 'error').mockImplementation();

      const result = await consultationService.sendConsultationReminder('consultation-1');

      expect(result.success).toBe(false);
      consoleSpy.mockRestore();
    });
  });

  describe('sendStatusNotification', () => {
    const mockConsultation = {
      farmer_id: 'farmer-1',
      expert_id: 'expert-1',
      farmer_name: 'Farmer John',
      expert_name: 'Expert Jane',
      farmer_email: 'farmer@example.com'
    };

    it('should send notifications for confirmed status', async () => {
      mockQuery.mockResolvedValueOnce({ rows: [mockConsultation] });
      mockSendToUser.mockResolvedValue({ success: true });

      const result = await consultationService.sendStatusNotification(
        'consultation-1',
        consultationService.ConsultationStatus.CONFIRMED
      );

      expect(result.success).toBe(true);
      expect(mockSendToUser).toHaveBeenCalledTimes(2);
    });

    it('should send notification only to farmer', async () => {
      mockQuery.mockResolvedValueOnce({ rows: [mockConsultation] });
      mockSendToUser.mockResolvedValue({ success: true });

      const result = await consultationService.sendStatusNotification(
        'consultation-1',
        consultationService.ConsultationStatus.COMPLETED,
        'farmer'
      );

      expect(result.results).toHaveLength(1);
      expect(result.results[0].recipient).toBe('farmer');
    });

    it('should send notification only to expert', async () => {
      mockQuery.mockResolvedValueOnce({ rows: [mockConsultation] });
      mockSendToUser.mockResolvedValue({ success: true });

      const result = await consultationService.sendStatusNotification(
        'consultation-1',
        consultationService.ConsultationStatus.CANCELLED,
        'expert'
      );

      expect(result.results).toHaveLength(1);
      expect(result.results[0].recipient).toBe('expert');
    });

    it('should return failure when consultation not found', async () => {
      mockQuery.mockResolvedValueOnce({ rows: [] });

      const result = await consultationService.sendStatusNotification('non-existent', 'confirmed');

      expect(result.success).toBe(false);
    });
  });

  describe('calculateRefundAmount', () => {
    it('should give full refund when cancelled 24+ hours before', () => {
      const scheduledAt = new Date();
      scheduledAt.setHours(scheduledAt.getHours() + 48); // 48 hours from now

      const result = consultationService.calculateRefundAmount(scheduledAt, 1000);

      expect(result.refund_amount).toBe(1000);
      expect(result.refund_percent).toBe(100);
    });

    it('should give partial refund when cancelled 12-24 hours before', () => {
      const scheduledAt = new Date();
      scheduledAt.setHours(scheduledAt.getHours() + 18); // 18 hours from now

      const result = consultationService.calculateRefundAmount(scheduledAt, 1000);

      expect(result.refund_amount).toBe(500);
      expect(result.refund_percent).toBe(50);
    });

    it('should give no refund when cancelled less than 12 hours before', () => {
      const scheduledAt = new Date();
      scheduledAt.setHours(scheduledAt.getHours() + 6); // 6 hours from now

      const result = consultationService.calculateRefundAmount(scheduledAt, 1000);

      expect(result.refund_amount).toBe(0);
      expect(result.refund_percent).toBe(0);
    });

    it('should include reason in refund response', () => {
      const scheduledAt = new Date();
      scheduledAt.setHours(scheduledAt.getHours() + 48);

      const result = consultationService.calculateRefundAmount(scheduledAt, 500);

      expect(result.reason).toBeDefined();
      expect(result.reason).toContain('Full refund');
    });
  });

  describe('updateExpertRating', () => {
    it('should update expert rating', async () => {
      mockQuery.mockResolvedValueOnce({
        rows: [{ rating: 4.5, total_reviews: 11 }]
      });

      const result = await consultationService.updateExpertRating('expert-1', 5);

      expect(mockQuery).toHaveBeenCalledWith(
        expect.stringContaining('UPDATE expert_profiles'),
        ['expert-1', 5]
      );
      expect(result.rating).toBe(4.5);
      expect(result.total_reviews).toBe(11);
    });

    it('should throw error when expert not found', async () => {
      mockQuery.mockResolvedValueOnce({ rows: [] });

      await expect(
        consultationService.updateExpertRating('non-existent', 4)
      ).rejects.toThrow('Expert profile not found');
    });
  });

  describe('incrementExpertConsultations', () => {
    it('should increment consultation count', async () => {
      mockQuery.mockResolvedValueOnce({ rowCount: 1 });

      await consultationService.incrementExpertConsultations('expert-1');

      expect(mockQuery).toHaveBeenCalledWith(
        expect.stringContaining('total_consultations = total_consultations + 1'),
        ['expert-1']
      );
    });
  });
});
