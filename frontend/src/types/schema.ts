// Type definitions for Kheti Sahayak application

import { UserRole, CropType, WeatherCondition, ProductCategory, OrderStatus, DiagnosisStatus, ContentType, ForumCategory, NotificationType } from './enums';

// Props types (data passed to components)
export interface PropTypes {
  initialRoute: string;
  theme: 'light' | 'dark';
  language: string;
}

// Store types (global state data)
export interface StoreTypes {
  user: {
    id: string;
    name: string;
    role: UserRole;
    location: {
      village: string;
      district: string;
      state: string;
      coordinates: { lat: number; lng: number };
    };
    crops: CropType[];
    language: string;
    isVerified: boolean;
  };
  notifications: Array<{
    id: string;
    type: NotificationType;
    title: string;
    message: string;
    timestamp: string;
    isRead: boolean;
  }>;
}

// Query types (API response data)
export interface QueryTypes {
  weatherData: {
    current: {
      temperature: number;
      humidity: number;
      windSpeed: number;
      precipitation: number;
      uvIndex: number;
      condition: WeatherCondition;
    };
    hourly: Array<{
      time: string;
      temperature: number;
      precipitation: number;
      condition: WeatherCondition;
    }>;
    daily: Array<{
      date: string;
      minTemp: number;
      maxTemp: number;
      precipitation: number;
      condition: WeatherCondition;
    }>;
  };
  marketplaceProducts: Array<{
    id: string;
    title: string;
    category: ProductCategory;
    price: number;
    rating: number;
    vendor: string;
    imageUrl: string;
    inStock: boolean;
  }>;
  diagnosisHistory: Array<{
    id: string;
    cropType: CropType;
    uploadDate: string;
    status: DiagnosisStatus;
    diagnosis: string;
    confidence: number;
    imageUrl: string;
  }>;
  experts: Array<{
    id: string;
    name: string;
    specialization: string;
    rating: number;
    languages: string[];
    isAvailable: boolean;
    consultationFee: number;
    profileImage: string;
  }>;
  educationalContent: Array<{
    id: string;
    title: string;
    type: ContentType;
    category: string;
    author: string;
    readTime: number;
    rating: number;
    thumbnail: string;
  }>;
  forumPosts: Array<{
    id: string;
    title: string;
    category: ForumCategory;
    author: string;
    replies: number;
    upvotes: number;
    createdAt: string;
    hasExpertReply: boolean;
  }>;
}