// String formatting functions for Kheti Sahayak

import { WeatherCondition, CropType, OrderStatus, DiagnosisStatus, ContentType, ForumCategory, NotificationType, ActivityType, EquipmentType, BookingStatus, LaborSkill, SchemeType, RecommendationPriority } from '../types/enums';

export const formatTemperature = (temp: number, unit: 'C' | 'F' = 'C'): string => {
  return `${Math.round(temp)}°${unit}`;
};

export const formatHumidity = (humidity: number): string => {
  return `${Math.round(humidity)}%`;
};

export const formatWindSpeed = (speed: number, unit: 'kmh' | 'mph' = 'kmh'): string => {
  return `${Math.round(speed)} ${unit === 'kmh' ? 'km/h' : 'mph'}`;
};

export const formatPrecipitation = (precip: number, unit: 'mm' | 'in' = 'mm'): string => {
  return `${precip.toFixed(1)} ${unit}`;
};

export const formatDate = (date: Date): string => {
  return date.toLocaleDateString('en-IN', {
    day: 'numeric',
    month: 'short',
    year: 'numeric'
  });
};

export const formatTime = (date: Date): string => {
  return date.toLocaleTimeString('en-IN', {
    hour: '2-digit',
    minute: '2-digit',
    hour12: true
  });
};

export const formatDateTime = (date: Date): string => {
  return `${formatDate(date)} at ${formatTime(date)}`;
};

export const formatCurrency = (amount: number): string => {
  return `₹${amount.toLocaleString('en-IN')}`;
};

export const formatWeight = (weight: number, unit: 'kg' | 'g' | 'quintal' = 'kg'): string => {
  return `${weight} ${unit}`;
};

export const formatDistance = (distance: number, unit: 'km' | 'm' = 'km'): string => {
  return `${distance} ${unit}`;
};

export const formatConfidenceScore = (score: number): string => {
  return `${Math.round(score * 100)}% confidence`;
};

export const formatRating = (rating: number): string => {
  return `${rating.toFixed(1)}/5`;
};

export const formatWeatherCondition = (condition: WeatherCondition): string => {
  const conditionMap = {
    [WeatherCondition.SUNNY]: 'Sunny',
    [WeatherCondition.CLOUDY]: 'Cloudy',
    [WeatherCondition.RAINY]: 'Rainy',
    [WeatherCondition.STORMY]: 'Stormy',
    [WeatherCondition.FOGGY]: 'Foggy',
    [WeatherCondition.WINDY]: 'Windy'
  };
  return conditionMap[condition];
};

export const formatOrderStatus = (status: OrderStatus): string => {
  const statusMap = {
    [OrderStatus.PENDING]: 'Pending',
    [OrderStatus.CONFIRMED]: 'Confirmed',
    [OrderStatus.SHIPPED]: 'Shipped',
    [OrderStatus.DELIVERED]: 'Delivered',
    [OrderStatus.CANCELLED]: 'Cancelled',
    [OrderStatus.RETURNED]: 'Returned'
  };
  return statusMap[status];
};

export const formatDiagnosisStatus = (status: DiagnosisStatus): string => {
  const statusMap = {
    [DiagnosisStatus.ANALYZING]: 'Analyzing...',
    [DiagnosisStatus.COMPLETED]: 'Analysis Complete',
    [DiagnosisStatus.FAILED]: 'Analysis Failed',
    [DiagnosisStatus.EXPERT_REVIEW]: 'Under Expert Review'
  };
  return statusMap[status];
};

export const formatActivityType = (activity: ActivityType): string => {
  const activityMap = {
    [ActivityType.PLANTING]: 'Planting',
    [ActivityType.IRRIGATION]: 'Irrigation',
    [ActivityType.FERTILIZING]: 'Fertilizing',
    [ActivityType.PEST_CONTROL]: 'Pest Control',
    [ActivityType.HARVESTING]: 'Harvesting',
    [ActivityType.OBSERVATION]: 'Observation',
    [ActivityType.MAINTENANCE]: 'Maintenance',
    [ActivityType.SALE]: 'Sale'
  };
  return activityMap[activity];
};

export const formatEquipmentType = (equipment: EquipmentType): string => {
  const equipmentMap = {
    [EquipmentType.TRACTOR]: 'Tractor',
    [EquipmentType.HARVESTER]: 'Harvester',
    [EquipmentType.PLOUGH]: 'Plough',
    [EquipmentType.SEEDER]: 'Seeder',
    [EquipmentType.SPRAYER]: 'Sprayer',
    [EquipmentType.CULTIVATOR]: 'Cultivator',
    [EquipmentType.THRESHER]: 'Thresher',
    [EquipmentType.PUMP]: 'Pump',
    [EquipmentType.OTHER]: 'Other'
  };
  return equipmentMap[equipment];
};

export const formatBookingStatus = (status: BookingStatus): string => {
  const statusMap = {
    [BookingStatus.REQUESTED]: 'Requested',
    [BookingStatus.CONFIRMED]: 'Confirmed',
    [BookingStatus.IN_PROGRESS]: 'In Progress',
    [BookingStatus.COMPLETED]: 'Completed',
    [BookingStatus.CANCELLED]: 'Cancelled'
  };
  return statusMap[status];
};

export const formatLaborSkill = (skill: LaborSkill): string => {
  const skillMap = {
    [LaborSkill.PLANTING]: 'Planting',
    [LaborSkill.HARVESTING]: 'Harvesting',
    [LaborSkill.TRACTOR_OPERATION]: 'Tractor Operation',
    [LaborSkill.IRRIGATION]: 'Irrigation',
    [LaborSkill.GENERAL_LABOR]: 'General Labor',
    [LaborSkill.LIVESTOCK_CARE]: 'Livestock Care',
    [LaborSkill.MACHINERY_REPAIR]: 'Machinery Repair'
  };
  return skillMap[skill];
};

export const formatSchemeType = (type: SchemeType): string => {
  const typeMap = {
    [SchemeType.SUBSIDY]: 'Subsidy',
    [SchemeType.LOAN]: 'Loan',
    [SchemeType.INSURANCE]: 'Insurance',
    [SchemeType.TRAINING]: 'Training',
    [SchemeType.EQUIPMENT]: 'Equipment',
    [SchemeType.CROP_SUPPORT]: 'Crop Support',
    [SchemeType.WATER_MANAGEMENT]: 'Water Management'
  };
  return typeMap[type];
};

export const formatRecommendationPriority = (priority: RecommendationPriority): string => {
  const priorityMap = {
    [RecommendationPriority.HIGH]: 'High Priority',
    [RecommendationPriority.MEDIUM]: 'Medium Priority',
    [RecommendationPriority.LOW]: 'Low Priority'
  };
  return priorityMap[priority];
};

export const formatPhoneNumber = (phone: string): string => {
  // Format Indian phone numbers
  if (phone.length === 10) {
    return `+91 ${phone.slice(0, 5)} ${phone.slice(5)}`;
  }
  return phone;
};

export const formatFileSize = (bytes: number): string => {
  if (bytes === 0) return '0 Bytes';
  const k = 1024;
  const sizes = ['Bytes', 'KB', 'MB', 'GB'];
  const i = Math.floor(Math.log(bytes) / Math.log(k));
  return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i];
};