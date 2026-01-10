const crypto = require('crypto');
const db = require('../db');
const pushNotificationService = require('./pushNotificationService');

const ConsultationStatus = {
  PENDING: 'pending',
  CONFIRMED: 'confirmed',
  IN_PROGRESS: 'in_progress',
  COMPLETED: 'completed',
  CANCELLED: 'cancelled',
  NO_SHOW: 'no_show'
};

const PaymentStatus = {
  PENDING: 'pending',
  PAID: 'paid',
  REFUNDED: 'refunded',
  FAILED: 'failed'
};

const ConsultationType = {
  VIDEO: 'video',
  AUDIO: 'audio',
  CHAT: 'chat'
};

const CancellationPolicy = {
  FREE_CANCELLATION_HOURS: 24,
  PARTIAL_REFUND_HOURS: 12,
  PARTIAL_REFUND_PERCENT: 50
};

const BookingRules = {
  MIN_ADVANCE_HOURS: 24,
  PAYMENT_TIMEOUT_MINUTES: 30
};

const parseTime = (timeStr) => {
  const parts = timeStr.split(':');
  return {
    hours: parseInt(parts[0], 10),
    minutes: parseInt(parts[1], 10)
  };
};

const getExpertBookingsForDate = async (expertId, dateStr) => {
  const result = await db.query(
    `SELECT scheduled_at, duration_minutes, status
     FROM consultations
     WHERE expert_id = $1
     AND DATE(scheduled_at) = $2
     AND status NOT IN ('cancelled', 'no_show')`,
    [expertId, dateStr]
  );
  return result.rows;
};

const generateTimeSlots = async (availability, dateStr, expertId) => {
  const date = new Date(dateStr);
  const dayOfWeek = date.getDay();
  
  const dayAvailability = availability.filter(
    a => a.day_of_week === dayOfWeek && a.is_available
  );
  
  if (dayAvailability.length === 0) {
    return [];
  }
  
  const slots = [];
  const now = new Date();
  const minBookingTime = new Date(now.getTime() + BookingRules.MIN_ADVANCE_HOURS * 60 * 60 * 1000);
  
  const existingBookings = await getExpertBookingsForDate(expertId, dateStr);
  const bookedSlots = new Set(
    existingBookings.map(b => new Date(b.scheduled_at).toISOString())
  );
  
  for (const avail of dayAvailability) {
    const startTime = parseTime(avail.start_time);
    const endTime = parseTime(avail.end_time);
    const slotDuration = avail.slot_duration_minutes || 30;
    
    let currentSlot = new Date(date);
    currentSlot.setHours(startTime.hours, startTime.minutes, 0, 0);
    
    const endSlotTime = new Date(date);
    endSlotTime.setHours(endTime.hours, endTime.minutes, 0, 0);
    
    while (currentSlot < endSlotTime) {
      const slotEnd = new Date(currentSlot.getTime() + slotDuration * 60 * 1000);
      const isInFuture = currentSlot >= minBookingTime;
      const isNotBooked = !bookedSlots.has(currentSlot.toISOString());
      
      if (isInFuture && isNotBooked) {
        slots.push({
          start_time: currentSlot.toISOString(),
          end_time: slotEnd.toISOString(),
          duration_minutes: slotDuration,
          is_available: true
        });
      }
      
      currentSlot = slotEnd;
    }
  }
  
  return slots;
};

const isSlotAvailable = async (expertId, dateTime, durationMinutes = 30) => {
  const requestedTime = new Date(dateTime);
  const now = new Date();
  
  const minBookingTime = new Date(now.getTime() + BookingRules.MIN_ADVANCE_HOURS * 60 * 60 * 1000);
  if (requestedTime < minBookingTime) {
    return {
      available: false,
      reason: `Bookings must be made at least ${BookingRules.MIN_ADVANCE_HOURS} hours in advance`
    };
  }
  
  const dayOfWeek = requestedTime.getDay();
  const timeStr = requestedTime.toTimeString().slice(0, 5);
  
  const availabilityResult = await db.query(
    `SELECT * FROM expert_availability
     WHERE expert_id = $1
     AND day_of_week = $2
     AND is_available = true
     AND start_time <= $3::time
     AND end_time >= $3::time + ($4 || ' minutes')::interval`,
    [expertId, dayOfWeek, timeStr, durationMinutes]
  );
  
  if (availabilityResult.rows.length === 0) {
    return {
      available: false,
      reason: 'Expert is not available at the requested time'
    };
  }
  
  const conflictResult = await db.query(
    `SELECT id FROM consultations
     WHERE expert_id = $1
     AND status NOT IN ('cancelled', 'no_show')
     AND (
       (scheduled_at <= $2 AND scheduled_at + (duration_minutes || ' minutes')::interval > $2)
       OR
       (scheduled_at < $3 AND scheduled_at + (duration_minutes || ' minutes')::interval >= $3)
       OR
       (scheduled_at >= $2 AND scheduled_at + (duration_minutes || ' minutes')::interval <= $3)
     )`,
    [
      expertId,
      requestedTime.toISOString(),
      new Date(requestedTime.getTime() + durationMinutes * 60 * 1000).toISOString()
    ]
  );
  
  if (conflictResult.rows.length > 0) {
    return {
      available: false,
      reason: 'Time slot is already booked'
    };
  }
  
  return { available: true };
};

const calculateConsultationFee = async (expertId, durationMinutes = 30) => {
  const expertResult = await db.query(
    `SELECT consultation_fee FROM expert_profiles WHERE user_id = $1`,
    [expertId]
  );
  
  if (expertResult.rows.length === 0) {
    throw new Error('Expert profile not found');
  }
  
  const baseFeePerSlot = parseFloat(expertResult.rows[0].consultation_fee);
  const slots = Math.ceil(durationMinutes / 30);
  const baseFee = baseFeePerSlot * slots;
  
  const platformFeePercent = 0.10;
  const platformFee = Math.round(baseFee * platformFeePercent * 100) / 100;
  
  const gstPercent = 0.18;
  const gst = Math.round(platformFee * gstPercent * 100) / 100;
  
  const totalFee = baseFee + platformFee + gst;
  
  return {
    base_fee: baseFee,
    platform_fee: platformFee,
    gst: gst,
    total_fee: Math.round(totalFee * 100) / 100,
    currency: 'INR',
    breakdown: {
      expert_earnings: baseFee - platformFee,
      platform_earnings: platformFee + gst
    }
  };
};

const generateCallRoomId = () => {
  const timestamp = Date.now().toString(36);
  const randomPart = crypto.randomBytes(8).toString('hex');
  return `ks-call-${timestamp}-${randomPart}`;
};

const generateCallJoinUrl = (roomId, userType, userId) => {
  const baseUrl = process.env.VIDEO_CALL_BASE_URL || 'https://meet.khetisahayak.com';
  const token = crypto
    .createHash('sha256')
    .update(`${roomId}:${userId}:${process.env.JWT_SECRET || 'secret'}`)
    .digest('hex')
    .slice(0, 16);
  
  return `${baseUrl}/room/${roomId}?token=${token}&role=${userType}`;
};

const sendConsultationReminder = async (consultationId) => {
  try {
    const consultation = await db.query(
      `SELECT c.*, 
              f.username as farmer_name, f.email as farmer_email,
              e.username as expert_name, e.email as expert_email,
              ep.specialization
       FROM consultations c
       JOIN users f ON c.farmer_id = f.id
       JOIN users e ON c.expert_id = e.id
       JOIN expert_profiles ep ON c.expert_id = ep.user_id
       WHERE c.id = $1`,
      [consultationId]
    );
    
    if (consultation.rows.length === 0) {
      return { success: false, message: 'Consultation not found' };
    }
    
    const data = consultation.rows[0];
    const scheduledTime = new Date(data.scheduled_at);
    const formattedTime = scheduledTime.toLocaleString('en-IN', {
      dateStyle: 'medium',
      timeStyle: 'short',
      timeZone: 'Asia/Kolkata'
    });
    
    const farmerTitle = 'Consultation Reminder';
    const farmerBody = `Your consultation with ${data.expert_name} (${data.specialization}) is scheduled for ${formattedTime}`;
    
    await pushNotificationService.sendToUser(data.farmer_id, farmerTitle, farmerBody, {
      type: 'consultation_reminder',
      consultation_id: consultationId,
      scheduled_at: data.scheduled_at
    });
    
    const expertTitle = 'Upcoming Consultation';
    const expertBody = `You have a consultation with ${data.farmer_name} scheduled for ${formattedTime}`;
    
    await pushNotificationService.sendToUser(data.expert_id, expertTitle, expertBody, {
      type: 'consultation_reminder',
      consultation_id: consultationId,
      scheduled_at: data.scheduled_at
    });
    
    return { success: true, message: 'Reminders sent' };
  } catch (error) {
    console.error('Error sending consultation reminder:', error);
    return { success: false, error: error.message };
  }
};

const sendStatusNotification = async (consultationId, status, recipientType = 'both') => {
  try {
    const consultation = await db.query(
      `SELECT c.*, 
              f.username as farmer_name, f.email as farmer_email,
              e.username as expert_name
       FROM consultations c
       JOIN users f ON c.farmer_id = f.id
       JOIN users e ON c.expert_id = e.id
       WHERE c.id = $1`,
      [consultationId]
    );
    
    if (consultation.rows.length === 0) {
      return { success: false, message: 'Consultation not found' };
    }
    
    const data = consultation.rows[0];
    const statusMessages = {
      [ConsultationStatus.CONFIRMED]: {
        farmer: `Your consultation with ${data.expert_name} has been confirmed`,
        expert: `Consultation with ${data.farmer_name} has been confirmed`
      },
      [ConsultationStatus.IN_PROGRESS]: {
        farmer: `Your consultation with ${data.expert_name} is starting now`,
        expert: `Your consultation with ${data.farmer_name} is starting`
      },
      [ConsultationStatus.COMPLETED]: {
        farmer: `Your consultation with ${data.expert_name} is complete. Please rate your experience!`,
        expert: `Your consultation with ${data.farmer_name} is complete`
      },
      [ConsultationStatus.CANCELLED]: {
        farmer: `Your consultation has been cancelled`,
        expert: `Consultation with ${data.farmer_name} has been cancelled`
      }
    };
    
    const messages = statusMessages[status] || {
      farmer: `Consultation status updated to: ${status}`,
      expert: `Consultation status updated to: ${status}`
    };
    
    const results = [];
    
    if (recipientType === 'farmer' || recipientType === 'both') {
      const result = await pushNotificationService.sendToUser(
        data.farmer_id,
        'Consultation Update',
        messages.farmer,
        { type: 'consultation_status', consultation_id: consultationId, status }
      );
      results.push({ recipient: 'farmer', ...result });
    }
    
    if (recipientType === 'expert' || recipientType === 'both') {
      const result = await pushNotificationService.sendToUser(
        data.expert_id,
        'Consultation Update',
        messages.expert,
        { type: 'consultation_status', consultation_id: consultationId, status }
      );
      results.push({ recipient: 'expert', ...result });
    }
    
    return { success: true, results };
  } catch (error) {
    console.error('Error sending status notification:', error);
    return { success: false, error: error.message };
  }
};

const calculateRefundAmount = (scheduledAt, amount) => {
  const now = new Date();
  const scheduled = new Date(scheduledAt);
  const hoursUntilConsultation = (scheduled - now) / (1000 * 60 * 60);
  
  if (hoursUntilConsultation >= CancellationPolicy.FREE_CANCELLATION_HOURS) {
    return {
      refund_amount: amount,
      refund_percent: 100,
      reason: 'Full refund - cancelled more than 24 hours before scheduled time'
    };
  } else if (hoursUntilConsultation >= CancellationPolicy.PARTIAL_REFUND_HOURS) {
    const refundAmount = Math.round(amount * CancellationPolicy.PARTIAL_REFUND_PERCENT / 100 * 100) / 100;
    return {
      refund_amount: refundAmount,
      refund_percent: CancellationPolicy.PARTIAL_REFUND_PERCENT,
      reason: 'Partial refund - cancelled between 12-24 hours before scheduled time'
    };
  } else {
    return {
      refund_amount: 0,
      refund_percent: 0,
      reason: 'No refund - cancelled less than 12 hours before scheduled time'
    };
  }
};

const updateExpertRating = async (expertId, newRating) => {
  // Rating formula: (old_rating * total_reviews + new_rating) / (total_reviews + 1)
  const result = await db.query(
    `UPDATE expert_profiles
     SET rating = (rating * total_reviews + $2) / (total_reviews + 1),
         total_reviews = total_reviews + 1,
         updated_at = CURRENT_TIMESTAMP
     WHERE user_id = $1
     RETURNING rating, total_reviews`,
    [expertId, newRating]
  );
  
  if (result.rows.length === 0) {
    throw new Error('Expert profile not found');
  }
  
  return result.rows[0];
};

const incrementExpertConsultations = async (expertId) => {
  await db.query(
    `UPDATE expert_profiles
     SET total_consultations = total_consultations + 1,
         updated_at = CURRENT_TIMESTAMP
     WHERE user_id = $1`,
    [expertId]
  );
};

module.exports = {
  ConsultationStatus,
  PaymentStatus,
  ConsultationType,
  CancellationPolicy,
  BookingRules,
  generateTimeSlots,
  isSlotAvailable,
  getExpertBookingsForDate,
  calculateConsultationFee,
  generateCallRoomId,
  generateCallJoinUrl,
  sendConsultationReminder,
  sendStatusNotification,
  calculateRefundAmount,
  updateExpertRating,
  incrementExpertConsultations
};
