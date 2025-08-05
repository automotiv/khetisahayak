// Enums for the Kheti Sahayak application

export enum UserRole {
  FARMER = 'farmer',
  EXPERT = 'expert', 
  VENDOR = 'vendor',
  ADMIN = 'admin'
}

export enum CropType {
  RICE = 'rice',
  WHEAT = 'wheat',
  COTTON = 'cotton',
  SUGARCANE = 'sugarcane',
  MAIZE = 'maize',
  SOYBEAN = 'soybean',
  TOMATO = 'tomato',
  POTATO = 'potato',
  ONION = 'onion',
  OTHER = 'other'
}

export enum WeatherCondition {
  SUNNY = 'sunny',
  CLOUDY = 'cloudy',
  RAINY = 'rainy',
  STORMY = 'stormy',
  FOGGY = 'foggy',
  WINDY = 'windy'
}

export enum ProductCategory {
  SEEDS = 'seeds',
  FERTILIZERS = 'fertilizers',
  PESTICIDES = 'pesticides',
  TOOLS = 'tools',
  FRESH_PRODUCE = 'fresh_produce',
  SERVICES = 'services'
}

export enum OrderStatus {
  PENDING = 'pending',
  CONFIRMED = 'confirmed',
  SHIPPED = 'shipped',
  DELIVERED = 'delivered',
  CANCELLED = 'cancelled',
  RETURNED = 'returned'
}

export enum DiagnosisStatus {
  ANALYZING = 'analyzing',
  COMPLETED = 'completed',
  FAILED = 'failed',
  EXPERT_REVIEW = 'expert_review'
}

export enum ContentType {
  ARTICLE = 'article',
  VIDEO = 'video',
  INFOGRAPHIC = 'infographic',
  AUDIO = 'audio'
}

export enum ForumCategory {
  CROP_MANAGEMENT = 'crop_management',
  SOIL_HEALTH = 'soil_health',
  PEST_CONTROL = 'pest_control',
  WATER_MANAGEMENT = 'water_management',
  ORGANIC_FARMING = 'organic_farming',
  MACHINERY = 'machinery',
  MARKET_INFO = 'market_info',
  GENERAL = 'general'
}

export enum NotificationType {
  WEATHER_ALERT = 'weather_alert',
  DIAGNOSIS_COMPLETE = 'diagnosis_complete',
  ORDER_UPDATE = 'order_update',
  EXPERT_MESSAGE = 'expert_message',
  FORUM_REPLY = 'forum_reply',
  WEBINAR_REMINDER = 'webinar_reminder'
}

export enum ActivityType {
  PLANTING = 'planting',
  IRRIGATION = 'irrigation',
  FERTILIZING = 'fertilizing',
  PEST_CONTROL = 'pest_control',
  HARVESTING = 'harvesting',
  OBSERVATION = 'observation',
  MAINTENANCE = 'maintenance',
  SALE = 'sale'
}

export enum EquipmentType {
  TRACTOR = 'tractor',
  HARVESTER = 'harvester',
  PLOUGH = 'plough',
  SEEDER = 'seeder',
  SPRAYER = 'sprayer',
  CULTIVATOR = 'cultivator',
  THRESHER = 'thresher',
  PUMP = 'pump',
  OTHER = 'other'
}

export enum EquipmentStatus {
  AVAILABLE = 'available',
  BOOKED = 'booked',
  MAINTENANCE = 'maintenance',
  UNAVAILABLE = 'unavailable'
}

export enum BookingStatus {
  REQUESTED = 'requested',
  CONFIRMED = 'confirmed',
  IN_PROGRESS = 'in_progress',
  COMPLETED = 'completed',
  CANCELLED = 'cancelled'
}

export enum LaborSkill {
  PLANTING = 'planting',
  HARVESTING = 'harvesting',
  TRACTOR_OPERATION = 'tractor_operation',
  IRRIGATION = 'irrigation',
  GENERAL_LABOR = 'general_labor',
  LIVESTOCK_CARE = 'livestock_care',
  MACHINERY_REPAIR = 'machinery_repair'
}

export enum SchemeType {
  SUBSIDY = 'subsidy',
  LOAN = 'loan',
  INSURANCE = 'insurance',
  TRAINING = 'training',
  EQUIPMENT = 'equipment',
  CROP_SUPPORT = 'crop_support',
  WATER_MANAGEMENT = 'water_management'
}

export enum SchemeLevel {
  CENTRAL = 'central',
  STATE = 'state',
  DISTRICT = 'district'
}

export enum RecommendationType {
  CROP_SELECTION = 'crop_selection',
  IRRIGATION = 'irrigation',
  FERTILIZATION = 'fertilization',
  PEST_MANAGEMENT = 'pest_management',
  HARVESTING = 'harvesting',
  MARKET_TIMING = 'market_timing',
  STORAGE = 'storage'
}

export enum RecommendationPriority {
  HIGH = 'high',
  MEDIUM = 'medium',
  LOW = 'low'
}