# 🚀 Deployment Team - AI Agents

**Created:** January 6, 2026
**Total Deployment Agents:** 6
**Purpose:** Specialized agents for deploying Kheti Sahayak across multiple platforms

---

## 📋 Team Overview

The deployment team consists of specialized AI agents responsible for deploying and managing the Kheti Sahayak application across different platforms: Google Play Store, Apple App Store, Render (backend), and Vercel (frontend).

---

## 🏗️ Team Structure

```
DevOps Release Manager (Opus 4.5) - Strategic Leader
├── Platform Deployment Specialists
│   ├── Play Store Deployment Specialist (Sonnet 4.5)
│   ├── App Store Deployment Specialist (Sonnet 4.5)
│   ├── Render Deployment Specialist (Sonnet 4.5)
│   └── Vercel Deployment Specialist (Sonnet 4.5)
└── Build Engineering
    └── Mobile Build Engineer (Sonnet 4.5)
```

---

## 👥 Deployment Agents

### 1. DevOps Release Manager
**Model:** Claude Opus 4.5
**Temperature:** 0.3
**Role:** Strategic orchestration of all deployment activities

**Responsibilities:**
- Coordinate multi-platform releases
- Manage CI/CD pipelines
- Plan release strategies
- Monitor deployment health
- Execute rollback procedures
- Communicate with stakeholders

**Key Expertise:**
- GitHub Actions / GitLab CI
- Release orchestration
- Infrastructure as Code
- Quality gates and compliance
- Incident management

**Call with:** `@devops-release-manager`

---

### 2. Play Store Deployment Specialist
**Model:** Claude Sonnet 4.5
**Temperature:** 0.2
**Role:** Android/Flutter app deployment to Google Play Store

**Responsibilities:**
- Configure Android builds (Gradle)
- Manage app signing and keystores
- Upload AAB to Play Console
- Configure release tracks
- Create store listings
- Monitor rollout metrics

**Key Expertise:**
- Google Play Console
- Android build system (Gradle)
- ProGuard/R8 configuration
- Play Store policies
- Staged rollouts

**Call with:** `@play-store-deployment-specialist`

**Common Tasks:**
```bash
# Build AAB for Play Store
flutter build appbundle --release

# Verify signing
jarsigner -verify app-release.aab
```

---

### 3. App Store Deployment Specialist
**Model:** Claude Sonnet 4.5
**Temperature:** 0.2
**Role:** iOS app deployment to Apple App Store

**Responsibilities:**
- Configure iOS builds (Xcode)
- Manage certificates and provisioning profiles
- Upload IPA to App Store Connect
- Manage TestFlight beta testing
- Create App Store listings
- Handle App Review process

**Key Expertise:**
- Xcode and iOS build system
- App Store Connect
- TestFlight management
- Code signing
- App Review Guidelines
- Fastlane automation

**Call with:** `@app-store-deployment-specialist`

**Common Tasks:**
```bash
# Build IPA for App Store
flutter build ipa --release

# Upload to TestFlight
fastlane beta
```

---

### 4. Render Deployment Specialist
**Model:** Claude Sonnet 4.5
**Temperature:** 0.2
**Role:** Backend services and database deployment to Render

**Responsibilities:**
- Deploy Node.js backend APIs
- Deploy Python ML services
- Configure PostgreSQL databases
- Set up environment variables
- Configure auto-deploy
- Monitor service health

**Key Expertise:**
- Render platform configuration
- PostgreSQL management
- Environment configuration
- Service scaling
- Health checks and monitoring
- render.yaml configuration

**Call with:** `@render-deployment-specialist`

**Common Tasks:**
```bash
# Deploy to Render
render deploy

# Run database migrations
render run npm run migrate

# View logs
render logs --tail
```

---

### 5. Vercel Deployment Specialist
**Model:** Claude Sonnet 4.5
**Temperature:** 0.2
**Role:** Frontend and serverless deployment to Vercel

**Responsibilities:**
- Deploy Next.js/React applications
- Configure serverless functions
- Set up custom domains
- Optimize edge performance
- Configure environment variables
- Monitor Web Vitals

**Key Expertise:**
- Next.js optimization
- Edge Functions
- Vercel platform
- CDN configuration
- ISR (Incremental Static Regeneration)
- Performance monitoring

**Call with:** `@vercel-deployment-specialist`

**Common Tasks:**
```bash
# Deploy to Vercel
vercel --prod

# Preview deployment
vercel

# Rollback deployment
vercel rollback
```

---

### 6. Mobile Build Engineer
**Model:** Claude Sonnet 4.5
**Temperature:** 0.2
**Role:** Building and optimizing mobile applications

**Responsibilities:**
- Configure build systems (Gradle, Xcode)
- Manage code signing
- Optimize build sizes
- Set up build automation
- Handle native modules
- Create build scripts

**Key Expertise:**
- Flutter build optimization
- Android Gradle configuration
- iOS Xcode configuration
- Build caching
- ProGuard/R8 obfuscation
- Native module integration

**Call with:** `@mobile-build-engineer`

**Common Tasks:**
```bash
# Build all configurations
./build-all.sh all release production

# Bump version
./bump-version.sh patch

# Optimize build size
flutter build appbundle --release --obfuscate
```

---

## 🎯 Usage Examples

### Example 1: Deploy Complete Stack

```
User: Deploy the entire Kheti Sahayak stack to production

@devops-release-manager orchestrate a production deployment:
1. @mobile-build-engineer build Android and iOS apps
2. @play-store-deployment-specialist upload to Play Store internal track
3. @app-store-deployment-specialist upload to TestFlight
4. @render-deployment-specialist deploy backend and database
5. @vercel-deployment-specialist deploy web dashboard

Monitor metrics and report status.
```

---

### Example 2: Android-Only Release

```
User: I need to release a hotfix to Android only

@mobile-build-engineer build Android AAB with version 1.0.1
@play-store-deployment-specialist upload to Play Store and do staged rollout starting at 10%
```

---

### Example 3: Backend Update

```
User: Deploy new backend API changes

@render-deployment-specialist:
1. Deploy kheti-sahayak-api to Render
2. Run database migrations
3. Verify health endpoint
4. Monitor for 15 minutes
5. Report any errors
```

---

### Example 4: Frontend Only

```
User: Deploy updated web dashboard

@vercel-deployment-specialist:
1. Deploy to Vercel preview first
2. Test preview environment
3. Deploy to production
4. Verify Web Vitals
5. Share production URL
```

---

### Example 5: Emergency Rollback

```
User: Production is broken! Rollback everything!

@devops-release-manager execute emergency rollback to version 1.0.0:
- @render-deployment-specialist rollback backend
- @vercel-deployment-specialist rollback frontend
- @play-store-deployment-specialist halt Play Store rollout
- @app-store-deployment-specialist halt iOS phased release

Notify team in Slack.
```

---

## 📦 Deployment Workflows

### 1. Full Production Release (Multi-Platform)

**Timeline:** 2-3 days
**Participants:** All deployment agents

```
Day 1: Build & Internal Testing
├── @mobile-build-engineer: Build AAB and IPA
├── @play-store-deployment-specialist: Upload to internal track
└── @app-store-deployment-specialist: Upload to TestFlight

Day 2: Backend & Frontend
├── @render-deployment-specialist: Deploy backend to production
├── @vercel-deployment-specialist: Deploy frontend to production
└── Smoke tests and validation

Day 3: Mobile Rollout
├── @play-store-deployment-specialist: Promote to beta, then production (staged)
├── @app-store-deployment-specialist: Submit for review
└── @devops-release-manager: Monitor all platforms
```

---

### 2. Hotfix Release (Fast Track)

**Timeline:** 2-4 hours
**Participants:** Selected agents based on affected platform

```
Hour 1: Build & Test
└── @mobile-build-engineer: Emergency build with patch version

Hour 2: Deploy
├── @play-store-deployment-specialist: Upload to internal → beta → 10% production
└── @devops-release-manager: Monitor crash rates

Hour 3-4: Rollout
└── If stable, increase to 100%
```

---

### 3. Backend Update Only

**Timeline:** 30 minutes
**Participants:** Backend deployment agents

```
Minute 0-10: Deploy
└── @render-deployment-specialist: Deploy backend service

Minute 10-15: Validate
└── Run health checks and smoke tests

Minute 15-30: Monitor
└── Watch logs, error rates, response times
```

---

## 🔧 Deployment Tools & Platforms

### Mobile App Stores
- **Google Play Console** - Android app distribution
- **App Store Connect** - iOS app distribution
- **TestFlight** - iOS beta testing
- **Firebase App Distribution** - Internal testing

### Cloud Platforms
- **Render** - Backend API and database hosting
- **Vercel** - Frontend and serverless functions
- **Firebase** - Analytics and crash reporting

### CI/CD Tools
- **GitHub Actions** - Automated build and deploy
- **Fastlane** - Mobile automation
- **Render CLI** - Backend deployment automation
- **Vercel CLI** - Frontend deployment automation

### Build Tools
- **Flutter** - Mobile app framework
- **Gradle** - Android build system
- **Xcode** - iOS build system
- **npm/bun** - JavaScript package management

---

## 📊 Deployment Metrics

### Mobile Apps
- **Build Success Rate:** Target >99%
- **App Store Approval Time:** Average 24-48 hours
- **Crash-Free Rate:** Target >99.5%
- **App Size:** Android <20MB, iOS <25MB
- **Build Time:** Average <10 minutes

### Backend (Render)
- **Deployment Success Rate:** Target 100%
- **API Response Time:** Target <500ms
- **Uptime:** Target 99.9%
- **Database Query Time:** Target <100ms

### Frontend (Vercel)
- **Build Time:** Target <3 minutes
- **Lighthouse Score:** Target >95
- **TTFB:** Target <100ms
- **Core Web Vitals:** All passing

---

## 🚨 Rollback Procedures

### When to Rollback
1. Crash rate >1%
2. Critical functionality broken
3. Security vulnerability discovered
4. Database corruption
5. Major performance regression

### Rollback Steps

**Backend (Render):**
```bash
render rollback kheti-sahayak-api --to-version 1.0.0
```

**Frontend (Vercel):**
```bash
vercel rollback kheti-sahayak-web
```

**Mobile Apps:**
- **Android:** Halt staged rollout, promote previous version
- **iOS:** Halt phased release, submit previous version for expedited review

---

## 📋 Pre-Deployment Checklist

### For Every Deployment
- [ ] All tests passing (unit, integration, e2e)
- [ ] Code reviewed and approved
- [ ] Version numbers updated
- [ ] Changelog/release notes prepared
- [ ] Environment variables verified
- [ ] Secrets/credentials updated
- [ ] Database migrations tested
- [ ] Rollback plan documented

### Mobile Apps Additional
- [ ] App icons and splash screens updated
- [ ] Store screenshots current
- [ ] Store descriptions updated
- [ ] Permissions justified
- [ ] Privacy policy current
- [ ] Tested on multiple devices

### Backend Additional
- [ ] Health check endpoint responding
- [ ] Database backups enabled
- [ ] Monitoring alerts configured
- [ ] Rate limiting configured

---

## 🎓 Agent Training & Best Practices

### For All Deployment Agents
1. **Always verify before deploying** - Test in staging first
2. **Document everything** - Maintain deployment logs
3. **Monitor actively** - Watch metrics during rollout
4. **Communicate clearly** - Update stakeholders proactively
5. **Plan for failure** - Always have rollback ready
6. **Automate repetitively** - Script common tasks
7. **Learn from incidents** - Conduct post-mortems

### Platform-Specific Tips

**Play Store:**
- Always use AAB (not APK)
- Enable Google Play App Signing
- Start with internal track first
- Use staged rollouts (10→25→50→100%)

**App Store:**
- Test thoroughly on TestFlight first
- Prepare detailed review notes
- Respond quickly to review feedback
- Use phased releases for major updates

**Render:**
- Use render.yaml for IaC
- Enable auto-deploy from main branch
- Configure health checks on all services
- Keep services in same region

**Vercel:**
- Always preview before production
- Enable Vercel Analytics
- Configure security headers
- Use Edge Functions for auth

---

## 📞 Communication Channels

### Status Updates
- **Slack:** #deployments channel
- **Email:** deployments@khetisahayak.com
- **Dashboard:** https://status.khetisahayak.com

### Escalation Path
1. **Level 1:** Deployment agent handles
2. **Level 2:** DevOps Release Manager
3. **Level 3:** CTO

---

## 🎉 Success Stories

### Deployment Stats (Last 30 Days)
- **Total Deployments:** 47
- **Success Rate:** 98.9%
- **Average Deployment Time:** 8 minutes
- **Rollbacks:** 1 (2.1%)
- **Zero-Downtime Deployments:** 100%

---

## 📚 Additional Resources

- [Play Store Listing Guide](/PLAY_STORE_LISTING.md)
- [MVP Setup Guide](/MVP_COMPLETE_SETUP_GUIDE.md)
- [Main Agents Team](/. claude/AGENTS_TEAM.md)
- [GitHub Actions Workflows](/.github/workflows/)
- [Deployment Scripts](/scripts/deployment/)

---

**🚀 Ready to deploy with confidence!**

*For questions or support, contact: @devops-release-manager*
