// Mock data for Kheti Sahayak application

import { UserRole, CropType, WeatherCondition, ProductCategory, DiagnosisStatus, ContentType, ForumCategory, NotificationType } from '../types/enums';

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

// Data passed as props to the root component
export const mockRootProps = {
  initialRoute: "/dashboard" as const,
  theme: "light" as const,
  language: "english" as const
};