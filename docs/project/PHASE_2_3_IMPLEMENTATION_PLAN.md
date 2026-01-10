# Phase 2 & 3 Implementation Plan

## Kheti Sahayak - Complete Development Roadmap

**Document Version**: 1.0  
**Created**: January 10, 2026  
**Target Completion**: March 2026  
**Estimated Effort**: 8-10 weeks

---

## Executive Summary

This document outlines the comprehensive implementation plan to complete Phase 2 (Core Feature Development) and Phase 3 (Cross-Cutting Concerns & Deployment) of Kheti Sahayak. The plan covers:

- **Phase 2 Remaining**: ~55% to complete
- **Phase 3**: ~100% to implement
- **Platforms**: Android (Flutter) + Desktop/Web (React)
- **Focus**: Beautiful UI/UX with production-ready features

---

## Table of Contents

1. [Current State Analysis](#current-state-analysis)
2. [Phase 2 Completion Plan](#phase-2-completion-plan)
3. [Phase 3 Implementation Plan](#phase-3-implementation-plan)
4. [Sprint Breakdown](#sprint-breakdown)
5. [UI/UX Design Specifications](#uiux-design-specifications)
6. [Technical Architecture](#technical-architecture)
7. [Risk Assessment](#risk-assessment)
8. [Success Metrics](#success-metrics)

---

## Current State Analysis

### Backend Status (Node.js) - 85% Complete

| Feature | Status | Endpoints |
|---------|--------|-----------|
| Authentication | ✅ Complete | 15 endpoints |
| Marketplace | ✅ Complete | 12 endpoints |
| Cart & Orders | ✅ Complete | 15 endpoints |
| Payments (Razorpay) | ✅ Complete | 6 endpoints |
| Diagnostics | ✅ Complete | 9 endpoints |
| Reviews | ✅ Complete | 8 endpoints |
| Weather | ✅ Complete | 5 endpoints |
| Education | ✅ Complete | 8 endpoints |
| Equipment Rental | ✅ Complete | 12 endpoints |
| Notifications (FCM) | ✅ Complete | 14 endpoints |
| Logbook | ✅ Complete | 3 endpoints |
| Community | ⚠️ Basic | 2 endpoints |
| Experts | ⚠️ Basic | 2 endpoints |
| Schemes | ⚠️ Basic | 2 endpoints |

**Missing Backend Features:**
- Expert Consultation Booking System
- Seller Dashboard Analytics
- Advanced Community Features
- Real ML Model Integration

### Flutter App Status - 70% Complete

| Category | Screens | Status |
|----------|---------|--------|
| Authentication | 6 | ✅ Complete |
| Dashboard | 3 | ✅ Complete |
| Marketplace | 9 | ✅ Complete |
| Diagnostics | 3 | ✅ Complete |
| Education | 4 | ✅ Complete |
| Fields/Farm | 5 | ✅ Complete |
| Profile | 4 | ✅ Complete |
| Schemes | 7 | ⚠️ Partial |
| Community | 3 | ⚠️ Basic |
| Utility | 5 | ⚠️ Partial |

**Existing i18n Support**: 7 languages (en, hi, mr, ta, kn, te, gu)

### React Web Frontend Status - 40% Complete

- Basic dashboard implemented
- MUI v6 styling
- Redux Toolkit for state
- Needs significant feature parity with mobile

---

## Phase 2 Completion Plan

### 2.1 Localized Weather Forecast (30% remaining)

**Current State**: Basic weather + 5-day forecast working

**To Implement**:

| Task | Priority | Effort | Sprint |
|------|----------|--------|--------|
| Hyperlocal village-level forecasts | P0 | 3 days | Sprint 1 |
| Weather alerts & push notifications | P0 | 2 days | Sprint 1 |
| Seasonal farming advisories | P1 | 2 days | Sprint 1 |
| Crop-weather integration | P1 | 2 days | Sprint 2 |

**Backend Changes**:
- Integrate OpenWeatherMap One Call API 3.0
- Add village-level geolocation mapping
- Create weather alert subscription system

**Flutter Changes**:
- Enhanced weather screen with hourly breakdown
- Alert notification cards
- Seasonal advisory section

### 2.2 Crop Health Diagnostics (40% remaining)

**Current State**: Mock ML model, basic diagnosis flow

**To Implement**:

| Task | Priority | Effort | Sprint |
|------|----------|--------|--------|
| Real TensorFlow model integration | P0 | 5 days | Sprint 2 |
| Expand to 20+ crop types | P1 | 3 days | Sprint 2 |
| Multilingual diagnostic reports | P1 | 2 days | Sprint 3 |
| Expert consultation integration | P0 | 4 days | Sprint 3 |
| Pesticide/fertilizer recommendations | P1 | 2 days | Sprint 3 |

**ML Service Changes**:
- Train/deploy real TensorFlow Lite model
- Add confidence calibration
- Multi-crop classification

**Flutter Changes**:
- Enhanced results screen with confidence visualization
- Expert review request flow
- Treatment comparison view

### 2.3 Marketplace Enhancements (15% remaining)

**Current State**: Full CRUD, cart, orders, payments working

**To Implement**:

| Task | Priority | Effort | Sprint |
|------|----------|--------|--------|
| Seller Dashboard - Orders | P0 | 3 days | Sprint 1 |
| Seller Dashboard - Analytics | P1 | 3 days | Sprint 2 |
| Product inventory management | P1 | 2 days | Sprint 2 |
| Wishlist functionality | P2 | 1 day | Sprint 3 |
| Product comparison | P2 | 2 days | Sprint 4 |

**New Screens Required**:
- `seller_dashboard_screen.dart`
- `seller_orders_screen.dart`
- `seller_analytics_screen.dart`
- `inventory_management_screen.dart`

### 2.4 Educational Content (35% remaining)

**Current State**: Content listing, video player working

**To Implement**:

| Task | Priority | Effort | Sprint |
|------|----------|--------|--------|
| Interactive learning modules | P1 | 4 days | Sprint 3 |
| Government scheme notifications | P1 | 2 days | Sprint 2 |
| Expert-curated content library | P2 | 3 days | Sprint 4 |
| Multilingual content support | P0 | 3 days | Sprint 3 |

### 2.5 Expert Network (New Feature)

**Current State**: Basic expert listing only

**To Implement**:

| Task | Priority | Effort | Sprint |
|------|----------|--------|--------|
| Expert registration & verification | P0 | 3 days | Sprint 2 |
| Consultation booking system | P0 | 4 days | Sprint 2 |
| Video/audio call integration | P1 | 5 days | Sprint 3 |
| Expert rating & review system | P1 | 2 days | Sprint 3 |
| Community Q&A platform | P2 | 4 days | Sprint 4 |

**New Backend Endpoints**:
```
POST   /api/experts/register
GET    /api/experts/:id/availability
POST   /api/experts/:id/book-consultation
GET    /api/consultations
PUT    /api/consultations/:id/reschedule
POST   /api/consultations/:id/complete
POST   /api/consultations/:id/review
```

**New Screens Required**:
- `expert_profile_screen.dart`
- `book_consultation_screen.dart`
- `consultation_list_screen.dart`
- `video_call_screen.dart`
- `expert_qa_screen.dart`

---

## Phase 3 Implementation Plan

### 3.1 Multilingual Support (i18n)

**Current State**: 7 languages in Flutter, basic setup

**To Implement**:

| Task | Priority | Effort | Sprint |
|------|----------|--------|--------|
| Complete Hindi translations | P0 | 2 days | Sprint 1 |
| Complete Marathi translations | P0 | 2 days | Sprint 1 |
| Add 5 more regional languages | P1 | 5 days | Sprint 4 |
| Dynamic content translation | P1 | 3 days | Sprint 4 |
| Voice input in local languages | P2 | 4 days | Sprint 5 |
| Text-to-speech for results | P2 | 3 days | Sprint 5 |

**Technical Implementation**:
```dart
// lib/l10n/ structure
lib/
└── l10n/
    ├── app_en.arb      // English (complete)
    ├── app_hi.arb      // Hindi (to complete)
    ├── app_mr.arb      // Marathi (to complete)
    ├── app_te.arb      // Telugu
    ├── app_ta.arb      // Tamil
    ├── app_kn.arb      // Kannada
    ├── app_gu.arb      // Gujarati
    ├── app_bn.arb      // Bengali (new)
    ├── app_pa.arb      // Punjabi (new)
    ├── app_or.arb      // Odia (new)
    ├── app_ml.arb      // Malayalam (new)
    └── app_ur.arb      // Urdu (new, RTL)
```

**String Count Estimate**: ~500 translatable strings

### 3.2 Offline Functionality

**Current State**: Basic SQLite setup, sync service exists

**To Implement**:

| Task | Priority | Effort | Sprint |
|------|----------|--------|--------|
| SQLite schema for offline data | P0 | 3 days | Sprint 2 |
| Weather data caching (24hr) | P0 | 2 days | Sprint 2 |
| Educational content download | P1 | 3 days | Sprint 3 |
| Offline diagnostics (TFLite) | P0 | 5 days | Sprint 3 |
| Sync queue with conflict resolution | P0 | 4 days | Sprint 3 |
| Offline indicators in UI | P1 | 2 days | Sprint 4 |
| Storage management settings | P2 | 2 days | Sprint 4 |

**Technical Architecture**:
```
┌─────────────────────────────────────────────────────────────┐
│                    Mobile App (Flutter)                      │
│  ┌───────────────────────────────────────────────────────┐  │
│  │                   SQLite Database                      │  │
│  │  ┌─────────┐  ┌─────────┐  ┌─────────┐  ┌─────────┐  │  │
│  │  │ Users   │  │ Content │  │ Weather │  │ Queue   │  │  │
│  │  │ Cache   │  │ Cache   │  │ Cache   │  │ (Sync)  │  │  │
│  │  └─────────┘  └─────────┘  └─────────┘  └─────────┘  │  │
│  └───────────────────────────────────────────────────────┘  │
│                                                              │
│  ┌───────────────────────────────────────────────────────┐  │
│  │                  TFLite Runtime                        │  │
│  │  ┌─────────────────┐  ┌─────────────────────────────┐ │  │
│  │  │ Disease Model   │  │ Inference Engine            │ │  │
│  │  │ (~30MB)         │  │ (CPU/GPU acceleration)      │ │  │
│  │  └─────────────────┘  └─────────────────────────────┘ │  │
│  └───────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

**Storage Limits**:
- SQLite DB: ~50MB
- TFLite Model: ~30MB
- Content Cache: ~200MB (configurable)
- Total: ~300MB default

### 3.3 Security Enhancements

**To Implement**:

| Task | Priority | Effort | Sprint |
|------|----------|--------|--------|
| Input validation (frontend) | P0 | 2 days | Sprint 1 |
| Input validation (backend) | P0 | 2 days | Sprint 1 |
| HTTPS enforcement | P0 | 1 day | Sprint 1 |
| Database encryption at rest | P1 | 2 days | Sprint 2 |
| Security audit & fixes | P0 | 3 days | Sprint 5 |
| Rate limiting enhancement | P1 | 1 day | Sprint 2 |
| JWT refresh token flow | P1 | 2 days | Sprint 2 |

### 3.4 Testing

**To Implement**:

| Task | Priority | Effort | Sprint |
|------|----------|--------|--------|
| Backend unit tests (90% coverage) | P0 | 5 days | Sprint 4 |
| Flutter widget tests | P1 | 4 days | Sprint 4 |
| API integration tests | P0 | 3 days | Sprint 4 |
| E2E tests (critical flows) | P1 | 4 days | Sprint 5 |
| Performance testing | P1 | 2 days | Sprint 5 |
| Security testing | P0 | 2 days | Sprint 5 |

**Test Coverage Targets**:
- Backend: 90%+
- Flutter: 70%+
- Integration: 80%+

### 3.5 Deployment

**To Implement**:

| Task | Priority | Effort | Sprint |
|------|----------|--------|--------|
| AWS infrastructure setup | P0 | 3 days | Sprint 5 |
| CI/CD pipeline (GitHub Actions) | P0 | 2 days | Sprint 5 |
| Production database setup | P0 | 1 day | Sprint 5 |
| SSL certificates | P0 | 1 day | Sprint 5 |
| Google Play Store submission | P0 | 2 days | Sprint 6 |
| Apple App Store submission | P1 | 2 days | Sprint 6 |
| Monitoring & alerting (Grafana) | P1 | 2 days | Sprint 6 |

---

## Sprint Breakdown

### Sprint 1: Foundation & Quick Wins (Week 1-2)

**Goal**: Complete security basics, seller dashboard, weather enhancements

| Task | Assignee | Days |
|------|----------|------|
| Input validation (frontend + backend) | Backend Dev | 4 |
| HTTPS enforcement | DevOps | 1 |
| Seller Dashboard - Orders | Full Stack | 3 |
| Hyperlocal weather forecasts | Backend Dev | 3 |
| Weather alerts & notifications | Mobile Dev | 2 |
| Hindi translations (complete) | Localization | 2 |
| Marathi translations (complete) | Localization | 2 |

**Deliverables**:
- Seller can view and manage orders
- Weather alerts working with push notifications
- Complete Hindi/Marathi UI translations
- Security baseline established

---

### Sprint 2: Core Features (Week 3-4)

**Goal**: Expert network, offline foundation, ML integration

| Task | Assignee | Days |
|------|----------|------|
| Expert registration & verification | Backend Dev | 3 |
| Consultation booking system | Full Stack | 4 |
| SQLite offline schema | Mobile Dev | 3 |
| Weather data caching | Mobile Dev | 2 |
| Real TensorFlow model integration | ML Engineer | 5 |
| Seller analytics dashboard | Full Stack | 3 |
| JWT refresh token flow | Backend Dev | 2 |
| Database encryption | DevOps | 2 |

**Deliverables**:
- Farmers can book expert consultations
- Offline weather data available
- Real ML model for crop diagnostics
- Seller analytics dashboard

---

### Sprint 3: Advanced Features (Week 5-6)

**Goal**: Video calls, offline diagnostics, multilingual content

| Task | Assignee | Days |
|------|----------|------|
| Video/audio call integration | Full Stack | 5 |
| Offline diagnostics (TFLite) | Mobile Dev | 5 |
| Sync queue with conflict resolution | Mobile Dev | 4 |
| Multilingual diagnostic reports | Full Stack | 2 |
| Expert rating & review system | Backend Dev | 2 |
| Interactive learning modules | Full Stack | 4 |
| Educational content download | Mobile Dev | 3 |

**Deliverables**:
- Video consultations with experts
- Offline crop disease detection
- Downloadable educational content
- Expert reviews working

---

### Sprint 4: Polish & Testing (Week 7-8)

**Goal**: Testing, additional languages, UI polish

| Task | Assignee | Days |
|------|----------|------|
| Backend unit tests (90% coverage) | Backend Dev | 5 |
| Flutter widget tests | Mobile Dev | 4 |
| API integration tests | QA | 3 |
| Add 5 regional languages | Localization | 5 |
| Community Q&A platform | Full Stack | 4 |
| Offline indicators in UI | Mobile Dev | 2 |
| Storage management settings | Mobile Dev | 2 |
| Wishlist functionality | Full Stack | 1 |
| Product comparison | Full Stack | 2 |

**Deliverables**:
- 90% backend test coverage
- 12 languages supported
- Community Q&A working
- Complete offline experience

---

### Sprint 5: Security & Infrastructure (Week 9)

**Goal**: Security audit, AWS deployment, performance

| Task | Assignee | Days |
|------|----------|------|
| Security audit & fixes | Security | 3 |
| E2E tests (critical flows) | QA | 4 |
| Performance testing | QA | 2 |
| AWS infrastructure setup | DevOps | 3 |
| CI/CD pipeline | DevOps | 2 |
| Production database setup | DevOps | 1 |
| SSL certificates | DevOps | 1 |

**Deliverables**:
- Security audit passed
- E2E tests for critical flows
- AWS infrastructure ready
- CI/CD pipeline working

---

### Sprint 6: Launch (Week 10)

**Goal**: App store submissions, monitoring, launch

| Task | Assignee | Days |
|------|----------|------|
| Google Play Store submission | Mobile Dev | 2 |
| Apple App Store submission | Mobile Dev | 2 |
| Monitoring & alerting setup | DevOps | 2 |
| Final bug fixes | All | 3 |
| Documentation updates | Tech Writer | 2 |
| Launch preparation | PM | 2 |

**Deliverables**:
- Apps submitted to stores
- Monitoring dashboards live
- Documentation complete
- Ready for public launch

---

## UI/UX Design Specifications

### Design System

**Color Palette**:
```
Primary:     #2E7D32 (Forest Green)
Secondary:   #66BB6A (Light Green)
Accent:      #FFA726 (Orange)
Background:  #FAFAFA (Light) / #121212 (Dark)
Surface:     #FFFFFF (Light) / #1E1E1E (Dark)
Error:       #D32F2F
Success:     #388E3C
Warning:     #F57C00
```

**Typography**:
```
Headings:    Poppins (600, 700)
Body:        Inter (400, 500)
Monospace:   JetBrains Mono
```

**Spacing Scale**:
```
xs: 4px, sm: 8px, md: 16px, lg: 24px, xl: 32px, xxl: 48px
```

### New Screen Designs Required

#### 1. Seller Dashboard
```
┌─────────────────────────────────────────┐
│  Seller Dashboard                    ☰  │
├─────────────────────────────────────────┤
│  ┌─────────┐ ┌─────────┐ ┌─────────┐   │
│  │ Orders  │ │ Revenue │ │Products │   │
│  │   24    │ │ ₹45,000 │ │   12    │   │
│  └─────────┘ └─────────┘ └─────────┘   │
├─────────────────────────────────────────┤
│  Recent Orders                          │
│  ┌─────────────────────────────────┐   │
│  │ #ORD-001  Pending    ₹2,500    │   │
│  │ Tomato Seeds (5kg)              │   │
│  └─────────────────────────────────┘   │
│  ┌─────────────────────────────────┐   │
│  │ #ORD-002  Shipped    ₹1,200    │   │
│  │ Organic Fertilizer              │   │
│  └─────────────────────────────────┘   │
├─────────────────────────────────────────┤
│  📊 Analytics  📦 Inventory  ⚙️ Settings │
└─────────────────────────────────────────┘
```

#### 2. Expert Consultation Booking
```
┌─────────────────────────────────────────┐
│  ← Book Consultation                    │
├─────────────────────────────────────────┤
│  ┌─────────────────────────────────┐   │
│  │  👨‍🌾 Dr. Rajesh Kumar           │   │
│  │  Crop Disease Specialist        │   │
│  │  ⭐ 4.8 (120 reviews)           │   │
│  │  ₹200/consultation              │   │
│  └─────────────────────────────────┘   │
├─────────────────────────────────────────┤
│  Select Date                            │
│  ┌───┬───┬───┬───┬───┬───┬───┐        │
│  │Mon│Tue│Wed│Thu│Fri│Sat│Sun│        │
│  │ 10│ 11│ 12│ 13│ 14│ 15│ 16│        │
│  └───┴───┴───┴───┴───┴───┴───┘        │
├─────────────────────────────────────────┤
│  Available Slots                        │
│  ┌────────┐ ┌────────┐ ┌────────┐     │
│  │ 9:00AM │ │10:00AM │ │11:00AM │     │
│  └────────┘ └────────┘ └────────┘     │
│  ┌────────┐ ┌────────┐ ┌────────┐     │
│  │ 2:00PM │ │ 3:00PM │ │ 4:00PM │     │
│  └────────┘ └────────┘ └────────┘     │
├─────────────────────────────────────────┤
│  Describe your issue (optional)         │
│  ┌─────────────────────────────────┐   │
│  │ My tomato plants have yellow... │   │
│  └─────────────────────────────────┘   │
├─────────────────────────────────────────┤
│  ┌─────────────────────────────────┐   │
│  │     Book Consultation - ₹200    │   │
│  └─────────────────────────────────┘   │
└─────────────────────────────────────────┘
```

#### 3. Offline Mode Indicator
```
┌─────────────────────────────────────────┐
│  ⚠️ You're Offline                      │
│  Some features may be limited           │
│  ┌─────────────────────────────────┐   │
│  │ ✓ Crop Diagnostics (offline)   │   │
│  │ ✓ Saved Weather Data           │   │
│  │ ✓ Downloaded Content           │   │
│  │ ✗ Marketplace (needs internet) │   │
│  │ ✗ Expert Consultation          │   │
│  └─────────────────────────────────┘   │
│  Changes will sync when online          │
└─────────────────────────────────────────┘
```

#### 4. Language Selection (Enhanced)
```
┌─────────────────────────────────────────┐
│  ← Select Language                      │
├─────────────────────────────────────────┤
│  🔍 Search languages...                 │
├─────────────────────────────────────────┤
│  Popular                                │
│  ┌─────────────────────────────────┐   │
│  │ 🇮🇳 हिंदी (Hindi)            ✓  │   │
│  └─────────────────────────────────┘   │
│  ┌─────────────────────────────────┐   │
│  │ 🇬🇧 English                     │   │
│  └─────────────────────────────────┘   │
│  ┌─────────────────────────────────┐   │
│  │ 🇮🇳 मराठी (Marathi)             │   │
│  └─────────────────────────────────┘   │
├─────────────────────────────────────────┤
│  All Languages                          │
│  ┌─────────────────────────────────┐   │
│  │ 🇮🇳 తెలుగు (Telugu)             │   │
│  └─────────────────────────────────┘   │
│  ┌─────────────────────────────────┐   │
│  │ 🇮🇳 தமிழ் (Tamil)               │   │
│  └─────────────────────────────────┘   │
│  ┌─────────────────────────────────┐   │
│  │ 🇮🇳 ಕನ್ನಡ (Kannada)             │   │
│  └─────────────────────────────────┘   │
└─────────────────────────────────────────┘
```

### Desktop/Web Responsive Design

**Breakpoints**:
```
Mobile:   < 768px
Tablet:   768px - 1024px
Desktop:  > 1024px
```

**Desktop Layout**:
```
┌────────────────────────────────────────────────────────────────┐
│  🌾 Kheti Sahayak    Dashboard  Market  Diagnose  Learn  👤   │
├────────┬───────────────────────────────────────────────────────┤
│        │                                                        │
│  Nav   │   Main Content Area                                   │
│        │                                                        │
│  🏠    │   ┌──────────────┐ ┌──────────────┐ ┌──────────────┐ │
│  📊    │   │   Weather    │ │   Alerts     │ │   Tasks      │ │
│  🛒    │   │   28°C ☀️    │ │   2 new      │ │   5 pending  │ │
│  🔬    │   └──────────────┘ └──────────────┘ └──────────────┘ │
│  📚    │                                                        │
│  👨‍🌾   │   Recent Activity                                     │
│  ⚙️    │   ┌────────────────────────────────────────────────┐ │
│        │   │ Diagnosed: Tomato Late Blight - 2 hours ago   │ │
│        │   │ Order #123 shipped - Yesterday                 │ │
│        │   │ New scheme available - 3 days ago              │ │
│        │   └────────────────────────────────────────────────┘ │
│        │                                                        │
└────────┴───────────────────────────────────────────────────────┘
```

---

## Technical Architecture

### Offline-First Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                         Flutter App                              │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │                    Presentation Layer                    │   │
│  │  Screens → Widgets → Providers (ChangeNotifier)         │   │
│  └─────────────────────────────────────────────────────────┘   │
│                              ↓                                   │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │                    Repository Layer                      │   │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐     │   │
│  │  │ Remote Repo │  │ Local Repo  │  │ Sync Manager│     │   │
│  │  │ (API calls) │  │ (SQLite)    │  │ (Queue)     │     │   │
│  │  └─────────────┘  └─────────────┘  └─────────────┘     │   │
│  └─────────────────────────────────────────────────────────┘   │
│                              ↓                                   │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │                    Data Layer                            │   │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐     │   │
│  │  │ API Service │  │ DB Helper   │  │ TFLite      │     │   │
│  │  │ (Dio)       │  │ (SQLite)    │  │ (ML)        │     │   │
│  │  └─────────────┘  └─────────────┘  └─────────────┘     │   │
│  └─────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
```

### i18n Architecture

```dart
// Recommended: easy_localization package
// pubspec.yaml
dependencies:
  easy_localization: ^3.0.3

// main.dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();
  
  runApp(
    EasyLocalization(
      supportedLocales: [
        Locale('en'),
        Locale('hi'),
        Locale('mr'),
        Locale('te'),
        Locale('ta'),
        Locale('kn'),
        Locale('gu'),
        Locale('bn'),
        Locale('pa'),
        Locale('or'),
        Locale('ml'),
        Locale('ur'),
      ],
      path: 'assets/translations',
      fallbackLocale: Locale('en'),
      child: MyApp(),
    ),
  );
}

// Usage in widgets
Text('welcome'.tr())
Text('hello_name'.tr(args: ['Rahul']))
```

### Video Call Architecture (Expert Consultation)

```
┌─────────────────────────────────────────────────────────────────┐
│                      Video Call Flow                             │
│                                                                  │
│  Farmer App                              Expert App              │
│  ┌─────────┐                            ┌─────────┐             │
│  │ WebRTC  │ ←──── Signaling ────────→ │ WebRTC  │             │
│  │ Client  │       (Socket.io)          │ Client  │             │
│  └─────────┘                            └─────────┘             │
│       ↓                                      ↓                   │
│  ┌─────────┐                            ┌─────────┐             │
│  │ Camera  │                            │ Camera  │             │
│  │ + Mic   │                            │ + Mic   │             │
│  └─────────┘                            └─────────┘             │
│                                                                  │
│  Backend (Node.js)                                              │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │  Socket.io Server  │  TURN/STUN  │  Session Manager     │   │
│  └─────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘

Recommended: Agora.io or 100ms.live for production
```

---

## Risk Assessment

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| ML model accuracy < 85% | Medium | High | Use ensemble models, expert fallback |
| Video call quality issues | Medium | Medium | Use established SDK (Agora/100ms) |
| Translation quality | Low | Medium | Professional translators + community review |
| Offline sync conflicts | Medium | Medium | Last-write-wins + user conflict resolution |
| App store rejection | Low | High | Follow guidelines, beta testing |
| Performance on low-end devices | Medium | Medium | Optimize images, lazy loading |
| Security vulnerabilities | Low | Critical | Regular audits, penetration testing |

---

## Success Metrics

### Phase 2 Completion Criteria

| Metric | Target |
|--------|--------|
| Weather alerts working | 100% |
| ML model accuracy | ≥85% |
| Seller dashboard functional | 100% |
| Expert booking working | 100% |
| Educational content complete | 100% |

### Phase 3 Completion Criteria

| Metric | Target |
|--------|--------|
| Languages supported | 12 |
| Offline feature coverage | 80% |
| Test coverage (backend) | 90% |
| Test coverage (Flutter) | 70% |
| Security audit passed | Yes |
| App store approved | Yes |

### Post-Launch Metrics

| Metric | Target (Month 1) |
|--------|------------------|
| App downloads | 10,000+ |
| Daily active users | 1,000+ |
| Crash-free rate | 99.5% |
| App store rating | 4.0+ |
| Expert consultations | 100+ |

---

## Resource Requirements

### Team Composition

| Role | Count | Responsibility |
|------|-------|----------------|
| Backend Developer | 1 | API development, database |
| Mobile Developer (Flutter) | 1 | Android/iOS app |
| Full Stack Developer | 1 | Features across stack |
| ML Engineer | 1 | Model training, TFLite |
| DevOps Engineer | 1 | Infrastructure, CI/CD |
| QA Engineer | 1 | Testing, automation |
| UI/UX Designer | 1 | Design, prototypes |
| Localization Specialist | 1 | Translations |

### Infrastructure Costs (Monthly)

| Service | Cost |
|---------|------|
| AWS (EC2, RDS, S3) | $200-400 |
| Agora.io (Video calls) | $100-200 |
| Firebase (FCM, Analytics) | Free tier |
| OpenWeatherMap API | $40 |
| Translation services | $500 (one-time) |
| **Total Monthly** | **$340-640** |

---

## Appendix

### A. File Structure for New Features

```
lib/
├── screens/
│   ├── seller/
│   │   ├── seller_dashboard_screen.dart
│   │   ├── seller_orders_screen.dart
│   │   ├── seller_analytics_screen.dart
│   │   └── inventory_management_screen.dart
│   ├── expert/
│   │   ├── expert_list_screen.dart
│   │   ├── expert_profile_screen.dart
│   │   ├── book_consultation_screen.dart
│   │   ├── consultation_list_screen.dart
│   │   └── video_call_screen.dart
│   └── offline/
│       ├── offline_status_screen.dart
│       └── storage_management_screen.dart
├── services/
│   ├── consultation_service.dart
│   ├── video_call_service.dart
│   ├── offline_sync_service.dart
│   └── tflite_service.dart
├── models/
│   ├── consultation.dart
│   ├── expert_availability.dart
│   └── sync_status.dart
└── l10n/
    ├── app_en.arb
    ├── app_hi.arb
    └── ... (12 language files)
```

### B. API Endpoints to Add

```
# Expert Consultation
POST   /api/experts/register
GET    /api/experts/:id/availability
POST   /api/experts/:id/book-consultation
GET    /api/consultations
GET    /api/consultations/:id
PUT    /api/consultations/:id/reschedule
POST   /api/consultations/:id/start
POST   /api/consultations/:id/complete
POST   /api/consultations/:id/review
DELETE /api/consultations/:id/cancel

# Seller Dashboard
GET    /api/sellers/dashboard
GET    /api/sellers/orders
GET    /api/sellers/revenue
GET    /api/sellers/analytics
GET    /api/sellers/inventory
PUT    /api/sellers/inventory/:productId

# Video Calls
POST   /api/calls/token
POST   /api/calls/:consultationId/start
POST   /api/calls/:consultationId/end
```

### C. Database Migrations Required

```javascript
// 1. Expert consultations table
CREATE TABLE consultations (
  id UUID PRIMARY KEY,
  farmer_id UUID REFERENCES users(id),
  expert_id UUID REFERENCES users(id),
  scheduled_at TIMESTAMP,
  duration_minutes INTEGER DEFAULT 30,
  status VARCHAR(20), -- pending, confirmed, in_progress, completed, cancelled
  issue_description TEXT,
  call_room_id VARCHAR(100),
  payment_id UUID REFERENCES payments(id),
  rating INTEGER,
  review TEXT,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

// 2. Expert availability table
CREATE TABLE expert_availability (
  id UUID PRIMARY KEY,
  expert_id UUID REFERENCES users(id),
  day_of_week INTEGER, -- 0-6
  start_time TIME,
  end_time TIME,
  is_available BOOLEAN DEFAULT true
);

// 3. Seller analytics table
CREATE TABLE seller_analytics (
  id UUID PRIMARY KEY,
  seller_id UUID REFERENCES users(id),
  date DATE,
  total_orders INTEGER DEFAULT 0,
  total_revenue DECIMAL(10,2) DEFAULT 0,
  products_sold INTEGER DEFAULT 0,
  avg_order_value DECIMAL(10,2) DEFAULT 0
);
```

---

**Document Prepared By**: Sisyphus AI Agent  
**Review Status**: Pending Team Review  
**Next Steps**: Create GitHub issues for Sprint 1 tasks

---

*This plan is a living document and will be updated as implementation progresses.*
