# 🌾 Kheti Sahayak - Frontend Application

**Your Digital Agricultural Assistant**

A comprehensive React-based web application designed to empower Indian farmers through digital solutions, bridging informational and transactional gaps in the agricultural sector.

## 🚀 Features

### Core Features
- 🌤️ **Weather Dashboard** - Hyperlocal weather forecasts and alerts
- 🔬 **Crop Diagnostics** - AI-powered disease detection with image analysis
- 🛒 **Agricultural Marketplace** - Buy/sell agricultural products and services
- 👨‍🌾 **Expert Connect** - Consultation with agricultural specialists
- 📚 **Educational Hub** - Learning resources and tutorials
- 💬 **Community Forum** - Peer-to-peer knowledge sharing

### Enhanced Features
- 🔐 **OTP Authentication** - Secure mobile-based login system
- 📖 **Digital Logbook** - Farm activity tracking and expense management
- 🏛️ **Government Schemes** - Access to agricultural subsidies and programs
- 💡 **Smart Recommendations** - Personalized farming advice
- 🚜 **Equipment Sharing** - Rent/lend agricultural equipment
- 👷 **Labor Marketplace** - Hire farm workers and services
- 🔔 **Notification Center** - Comprehensive alert system
- 👤 **Profile Management** - User and farm profile settings

## 🛠️ Technology Stack

- **Frontend Framework**: React 18 with TypeScript
- **UI Library**: Material-UI (MUI) v7
- **Styling**: Emotion CSS-in-JS with MUI theme system
- **State Management**: Redux Toolkit (RTK)
- **Data Fetching**: RTK Query
- **Build Tool**: Vite
- **Icons**: Material-UI Icons
- **Fonts**: Inter (Google Fonts)

## 📁 Project Structure

```
frontend/
├── src/
│   ├── components/           # React components organized by feature
│   │   ├── auth/            # Authentication components
│   │   ├── dashboard/       # Main dashboard
│   │   ├── diagnostics/     # Crop disease detection
│   │   ├── education/       # Educational content
│   │   ├── experts/         # Expert consultation
│   │   ├── forum/           # Community discussions
│   │   ├── layout/          # App layout and navigation
│   │   ├── logbook/         # Digital farm logbook
│   │   ├── marketplace/     # Agricultural marketplace
│   │   ├── notifications/   # Notification system
│   │   ├── profile/         # User profile management
│   │   ├── recommendations/ # Farming recommendations
│   │   ├── schemes/         # Government schemes
│   │   ├── sharing/         # Equipment & labor sharing
│   │   └── weather/         # Weather forecasts
│   ├── data/                # Mock data for development
│   ├── theme/               # MUI theme configuration
│   ├── types/               # TypeScript type definitions
│   ├── utils/               # Utility functions
│   ├── App.tsx              # Main application component
│   ├── main.tsx             # Application entry point
│   └── index.css            # Global styles
├── index.html               # HTML template
├── package.json             # Dependencies and scripts
├── vite.config.ts           # Vite configuration
└── tsconfig.json            # TypeScript configuration
```

## 🚀 Getting Started

### Prerequisites
- Node.js (v18 or higher)
- npm or yarn package manager

### Installation

1. **Navigate to the frontend directory:**
   ```bash
   cd frontend
   ```

2. **Install dependencies:**
   ```bash
   npm install
   ```

3. **Start the development server:**
   ```bash
   npm run dev
   ```

4. **Open your browser:**
   Navigate to `http://localhost:3000`

### Available Scripts

- `npm run dev` - Start development server
- `npm run build` - Build for production
- `npm run preview` - Preview production build
- `npm run start` - Alias for dev command

## 🎨 Design System

### Theme
The application uses a custom MUI theme with:
- **Primary Color**: Fresh Green (#4CAF50) - representing agriculture
- **Secondary Color**: Warm Orange (#FF9800) - representing harvest/sun
- **Typography**: Inter font family for modern readability
- **Border Radius**: 12px for friendly, approachable design
- **Shadows**: Layered elevation system for depth

### Component Architecture
- **Atomic Design**: Components are organized from simple to complex
- **Reusability**: Common UI patterns extracted into reusable components
- **Accessibility**: WCAG AA compliant with screen reader support
- **Mobile-First**: Responsive design optimized for mobile devices

## 📱 User Interface

### Navigation
- **Bottom Navigation**: Primary features (Dashboard, Weather, Diagnostics, Marketplace, Education, More)
- **Side Drawer**: Extended features (Logbook, Schemes, Recommendations, Sharing, Notifications, Profile)
- **Top App Bar**: App title, notifications, and user menu

### Key Screens
1. **Dashboard** - Overview with weather, quick actions, and recent activity
2. **Weather** - Current conditions, hourly/daily forecasts, and alerts
3. **Diagnostics** - Image upload for crop disease detection
4. **Marketplace** - Product browsing with search and filters
5. **Education** - Learning content with bookmarking
6. **Experts** - Professional consultation platform
7. **Community** - Discussion forums with voting
8. **Logbook** - Farm activity tracking and reporting
9. **Schemes** - Government program discovery
10. **Recommendations** - Personalized farming advice
11. **Sharing** - Equipment and labor marketplace
12. **Notifications** - Alert management center
13. **Profile** - User and farm settings

## 🔧 Development Guidelines

### Code Organization
- Components are organized by feature in separate directories
- Each component has a single responsibility
- Reusable UI elements are extracted into shared components
- TypeScript interfaces define clear data contracts

### State Management
- Global state managed with Redux Toolkit
- Local component state for UI interactions
- API data fetching with RTK Query
- Form state management with controlled components

### Styling Approach
- MUI `sx` prop for simple inline styles
- Emotion styled components for complex reusable styles
- Theme tokens for consistent colors and typography
- Responsive design with breakpoint considerations

## 🌐 API Integration

### Mock Data
The application includes comprehensive mock data for all features:
- Weather data with current conditions and forecasts
- Marketplace products with ratings and vendor information
- Expert profiles with specializations and availability
- Educational content with categories and bookmarking
- Forum posts with voting and expert replies
- Logbook entries with activity tracking
- Government schemes with eligibility and deadlines
- Personalized recommendations with priority levels
- Equipment and labor listings with booking system
- Notification system with various alert types

### Data Flow
- Components receive data through props from parent containers
- API calls simulated with mock data responses
- State updates trigger UI re-renders automatically
- Form submissions handled with validation and feedback

## 🎯 Target Audience

### Primary Users
- **Smallholder Farmers** - Main beneficiaries seeking agricultural support
- **Agricultural Experts** - Professionals providing consultation services
- **Equipment Owners** - Farmers sharing machinery and tools
- **Labor Providers** - Workers offering agricultural services

### Accessibility Features
- Voice input/output support for low-literacy users
- Large touch targets for mobile interaction
- High contrast colors for outdoor visibility
- Multi-language support for Indian regional languages
- Offline functionality for areas with poor connectivity

## 🔒 Security & Privacy

- Secure OTP-based authentication
- Data encryption for sensitive information
- User consent for location and data usage
- Privacy-compliant data handling
- Secure payment processing integration

## 🌍 Localization

- Multi-language interface support
- Cultural context consideration for Indian users
- Local currency formatting (₹ INR)
- Regional weather and agricultural data
- Government scheme information in local languages

## 📊 Performance Optimization

- Lazy loading for large datasets
- Image optimization and compression
- Efficient state management
- Caching strategies for offline access
- Mobile-optimized bundle sizes

## 🤝 Contributing

1. Follow the established component structure
2. Use TypeScript for type safety
3. Implement responsive design patterns
4. Add proper error handling and loading states
5. Include accessibility features
6. Write meaningful commit messages

## 📞 Support

For technical support or feature requests:
- **Email**: engineering@khetisahayak.com
- **Documentation**: See `/prd` folder for detailed requirements
- **Issues**: Report bugs through the development team

## 📄 License

This project is part of the Kheti Sahayak agricultural assistance platform.

---

**Built with ❤️ for Indian Farmers**

*Empowering agriculture through digital innovation*