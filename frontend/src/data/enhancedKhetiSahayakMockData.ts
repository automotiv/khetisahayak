// Enhanced mock data for additional Kheti Sahayak features

import { UserRole, CropType, WeatherCondition, ProductCategory, DiagnosisStatus, ContentType, ForumCategory, NotificationType, ActivityType, EquipmentType, EquipmentStatus, LaborSkill, SchemeType, SchemeLevel, RecommendationType, RecommendationPriority } from '../types/enums';

// Data for global state store
export const mockStore = {
  user: {
    id: "user123" as const,
    name: "Ramesh Kumar" as const,
    role: UserRole.FARMER,
    location: {
      village: "Khandala" as const,
      district: "Nashik" as const,
      state: "Maharashtra" as const,
      coordinates: { lat: 19.7515, lng: 73.0169 }
    },
    crops: [CropType.TOMATO, CropType.ONION],
    language: "hindi" as const,
    isVerified: true
  },
  notifications: [
    {
      id: "notif1" as const,
      type: NotificationType.WEATHER_ALERT,
      title: "Heavy Rain Alert" as const,
      message: "Heavy rainfall expected in next 6 hours" as const,
      timestamp: "2024-01-15T10:30:00Z" as const,
      isRead: false
    }
  ]
};

// Data returned by API queries
export const mockQuery = {
  weatherData: {
    current: {
      temperature: 28,
      humidity: 65,
      windSpeed: 12,
      precipitation: 0,
      uvIndex: 6,
      condition: WeatherCondition.CLOUDY
    },
    hourly: [
      {
        time: "2024-01-15T14:00:00Z" as const,
        temperature: 30,
        precipitation: 10,
        condition: WeatherCondition.SUNNY
      },
      {
        time: "2024-01-15T15:00:00Z" as const,
        temperature: 32,
        precipitation: 5,
        condition: WeatherCondition.CLOUDY
      }
    ],
    daily: [
      {
        date: "2024-01-15" as const,
        minTemp: 22,
        maxTemp: 34,
        precipitation: 15,
        condition: WeatherCondition.RAINY
      },
      {
        date: "2024-01-16" as const,
        minTemp: 20,
        maxTemp: 30,
        precipitation: 80,
        condition: WeatherCondition.STORMY
      }
    ]
  },
  marketplaceProducts: [
    {
      id: "prod1" as const,
      title: "Organic Tomato Seeds" as const,
      category: ProductCategory.SEEDS,
      price: 250,
      rating: 4.5,
      vendor: "Green Valley Seeds" as const,
      imageUrl: "https://images.unsplash.com/photo-1592841200221-21e1c9d4b5e9?w=400" as const,
      inStock: true
    },
    {
      id: "prod2" as const,
      title: "NPK Fertilizer 50kg" as const,
      category: ProductCategory.FERTILIZERS,
      price: 1200,
      rating: 4.2,
      vendor: "Farm Inputs Co" as const,
      imageUrl: "https://images.unsplash.com/photo-1416879595882-3373a0480b5b?w=400" as const,
      inStock: true
    }
  ],
  diagnosisHistory: [
    {
      id: "diag1" as const,
      cropType: CropType.TOMATO,
      uploadDate: "2024-01-14T09:30:00Z" as const,
      status: DiagnosisStatus.COMPLETED,
      diagnosis: "Powdery Mildew" as const,
      confidence: 0.87,
      imageUrl: "https://images.unsplash.com/photo-1574323347407-f5e1ad6d020b?w=400" as const
    }
  ],
  experts: [
    {
      id: "expert1" as const,
      name: "Dr. Priya Sharma" as const,
      specialization: "Plant Pathology" as const,
      rating: 4.8,
      languages: ["Hindi", "English"],
      isAvailable: true,
      consultationFee: 500,
      profileImage: "https://i.pravatar.cc/150?img=1" as const
    }
  ],
  educationalContent: [
    {
      id: "content1" as const,
      title: "Organic Farming Techniques" as const,
      type: ContentType.ARTICLE,
      category: "Organic Farming" as const,
      author: "Dr. Rajesh Patel" as const,
      readTime: 8,
      rating: 4.6,
      thumbnail: "https://images.unsplash.com/photo-1500595046743-cd271d694d30?w=400" as const
    }
  ],
  forumPosts: [
    {
      id: "post1" as const,
      title: "Best practices for tomato cultivation in winter" as const,
      category: ForumCategory.CROP_MANAGEMENT,
      author: "Suresh Patil" as const,
      replies: 12,
      upvotes: 25,
      createdAt: "2024-01-14T16:20:00Z" as const,
      hasExpertReply: true
    }
  ]
};

// Additional API query data for new features
export const enhancedMockQuery = {
  ...mockQuery,

  logbookEntries: [
    {
      id: "entry1" as const,
      activityType: ActivityType.PLANTING,
      cropType: "tomato" as const,
      date: "2024-01-10T08:00:00Z" as const,
      notes: "Planted hybrid tomato seedlings in field A" as const,
      inputsUsed: [
        { type: "seeds" as const, quantity: 500, unit: "pieces" as const, cost: 250 }
      ],
      expenses: 750,
      photos: ["https://images.unsplash.com/photo-1592841200221-21e1c9d4b5e9?w=400"]
    },
    {
      id: "entry2" as const,
      activityType: ActivityType.IRRIGATION,
      cropType: "tomato" as const,
      date: "2024-01-12T06:30:00Z" as const,
      notes: "Drip irrigation for 2 hours" as const,
      inputsUsed: [],
      expenses: 50,
      photos: []
    }
  ],

  governmentSchemes: [
    {
      id: "scheme1" as const,
      name: "PM-KISAN Yojana" as const,
      type: SchemeType.SUBSIDY,
      level: SchemeLevel.CENTRAL,
      description: "Income support of ₹6000 per year to farmer families" as const,
      eligibility: "Small and marginal farmers with landholding up to 2 hectares" as const,
      benefits: "₹2000 per installment, 3 times a year" as const,
      deadline: "2024-03-31" as const,
      applicationUrl: "https://pmkisan.gov.in" as const,
      isBookmarked: false
    },
    {
      id: "scheme2" as const,
      name: "Pradhan Mantri Fasal Bima Yojana" as const,
      type: SchemeType.INSURANCE,
      level: SchemeLevel.CENTRAL,
      description: "Crop insurance scheme providing financial support to farmers" as const,
      eligibility: "All farmers growing notified crops in notified areas" as const,
      benefits: "Comprehensive risk cover against yield losses" as const,
      deadline: "2024-02-15" as const,
      applicationUrl: "https://pmfby.gov.in" as const,
      isBookmarked: true
    }
  ],

  recommendations: [
    {
      id: "rec1" as const,
      type: RecommendationType.IRRIGATION,
      priority: RecommendationPriority.HIGH,
      title: "Irrigation Recommended" as const,
      description: "Water your tomato crops today due to high temperature and no rain forecast" as const,
      reasoning: "Temperature will reach 34°C with no rainfall expected for next 3 days" as const,
      actionRequired: true,
      dueDate: "2024-01-15T18:00:00Z" as const,
      isFollowed: false
    },
    {
      id: "rec2" as const,
      type: RecommendationType.FERTILIZATION,
      priority: RecommendationPriority.MEDIUM,
      title: "Apply NPK Fertilizer" as const,
      description: "Apply NPK fertilizer to boost tomato growth in flowering stage" as const,
      reasoning: "Crops are in flowering stage and require additional nutrients" as const,
      actionRequired: false,
      dueDate: "2024-01-18T00:00:00Z" as const,
      isFollowed: false
    }
  ],

  equipmentListings: [
    {
      id: "equip1" as const,
      name: "Mahindra Tractor 575 DI" as const,
      type: EquipmentType.TRACTOR,
      owner: "Rajesh Patel" as const,
      location: "Nashik, Maharashtra" as const,
      hourlyRate: 500,
      dailyRate: 3000,
      securityDeposit: 10000,
      status: EquipmentStatus.AVAILABLE,
      rating: 4.7,
      images: ["https://images.unsplash.com/photo-1581833971358-2c8b550f87b3?w=400"],
      description: "Well-maintained tractor suitable for all farming operations" as const
    }
  ],

  laborProfiles: [
    {
      id: "labor1" as const,
      name: "Suresh Kumar" as const,
      skills: [LaborSkill.PLANTING, LaborSkill.HARVESTING],
      experience: 8,
      location: "Nashik, Maharashtra" as const,
      dailyWage: 400,
      hourlyWage: 50,
      rating: 4.5,
      isAvailable: true,
      profileImage: "https://i.pravatar.cc/150?img=2" as const,
      description: "Experienced farm worker specializing in vegetable crops" as const
    }
  ],

  notifications: [
    {
      id: "notif1" as const,
      type: "weather_alert" as const,
      title: "Heavy Rain Alert" as const,
      message: "Heavy rainfall expected in next 6 hours" as const,
      timestamp: "2024-01-15T10:30:00Z" as const,
      isRead: false,
      priority: "high" as const
    },
    {
      id: "notif2" as const,
      type: "scheme_deadline" as const,
      title: "Scheme Deadline Reminder" as const,
      message: "PM Fasal Bima Yojana application closes in 3 days" as const,
      timestamp: "2024-01-14T09:00:00Z" as const,
      isRead: false,
      priority: "medium" as const
    }
  ]
};

// Enhanced store data
export const enhancedMockStore = {
  user: {
    id: "user123" as const,
    name: "Ramesh Kumar" as const,
    role: UserRole.FARMER,
    location: {
      village: "Khandala" as const,
      district: "Nashik" as const,
      state: "Maharashtra" as const,
      coordinates: { lat: 19.7515, lng: 73.0169 }
    },
    crops: [CropType.TOMATO, CropType.ONION],
    language: "hindi" as const,
    isVerified: true
  },

  farmProfile: {
    farmSize: 2.5,
    soilType: "loamy" as const,
    irrigationType: "drip" as const,
    primaryCrops: ["tomato", "onion"],
    equipment: ["tractor", "sprayer"],
    laborers: 2,
    lastSoilTest: "2023-12-01" as const,
    phLevel: 6.8,
    organicMatter: 2.3
  },

  userPreferences: {
    notificationSettings: {
      weatherAlerts: true,
      schemeUpdates: true,
      marketplaceUpdates: true,
      expertMessages: true,
      forumReplies: false,
      logbookReminders: true
    },
    language: "hindi" as const,
    units: {
      temperature: "celsius" as const,
      distance: "kilometers" as const,
      weight: "kilograms" as const
    }
  }
};

// Data passed as props to the root component
export const mockRootProps = {
  initialRoute: "/dashboard" as const,
  theme: "light" as const,
  language: "english" as const
};