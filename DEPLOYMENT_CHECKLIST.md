# ✅ Kheti Sahayak - Deployment Checklist

**Version:** ___________
**Date:** ___________
**Deployed By:** ___________

---

## Pre-Deployment Checklist

### Code Quality
- [ ] All unit tests passing
- [ ] All integration tests passing
- [ ] Flutter tests passing (no failures)
- [ ] Backend tests passing (no failures)
- [ ] Code reviewed and approved
- [ ] No console errors or warnings
- [ ] Linter checks passed

### Version Management
- [ ] Version number updated in `VERSION` file
- [ ] Version updated in `kheti_sahayak_app/pubspec.yaml`
- [ ] Version updated in `kheti_sahayak_backend/package.json`
- [ ] Build number incremented
- [ ] Changelog updated with new features/fixes

### Environment & Configuration
- [ ] All environment variables verified
- [ ] Secrets rotated (if needed)
- [ ] API keys validated
- [ ] Database connection strings updated
- [ ] SSL certificates valid
- [ ] Firebase configuration updated (if changed)

### Database
- [ ] Database migrations tested in staging
- [ ] Seed data verified
- [ ] Database backups enabled
- [ ] Migration rollback tested
- [ ] No breaking schema changes (or migration plan ready)

### Security
- [ ] No hardcoded credentials
- [ ] No API keys in code
- [ ] Security audit completed
- [ ] Dependencies scanned for vulnerabilities
- [ ] Authentication flows tested
- [ ] Authorization rules verified

---

## Backend Deployment (Render)

### Pre-Deploy
- [ ] Render account verified
- [ ] PostgreSQL database created
- [ ] Environment variables set in Render dashboard
- [ ] Health check endpoint configured
- [ ] Deployment hook URL obtained

### Deploy
- [ ] Run deployment script: `./scripts/deploy-backend-render.sh`
- [ ] Monitor deployment logs
- [ ] Wait for deployment to complete (~3-5 minutes)

### Post-Deploy
- [ ] API health check passing: `curl https://kheti-sahayak-api.onrender.com/api/health`
- [ ] Database connected successfully
- [ ] Run migrations in Render Shell: `npm run migrate:up`
- [ ] Seed treatment data: `node seedTreatmentData.js`
- [ ] Test critical endpoints (auth, diagnostics, treatments)
- [ ] Check response times (<500ms)
- [ ] Verify CORS configuration
- [ ] Monitor error logs for 15 minutes

---

## Android Deployment (Play Store)

### Pre-Build
- [ ] Keystore file exists: `android/app/upload-keystore.jks`
- [ ] `key.properties` file configured
- [ ] App signing configured correctly
- [ ] ProGuard rules verified
- [ ] App permissions reviewed

### Build
- [ ] Run build script: `./scripts/build-android.sh release production`
- [ ] AAB size < 25 MB
- [ ] Signing verification passed
- [ ] Test APK on physical device
- [ ] No crashes during testing

### Upload
- [ ] Google Play Console account active
- [ ] App created in Play Console
- [ ] Store listing complete:
  - [ ] Short description (80 chars)
  - [ ] Full description (4000 chars)
  - [ ] App icon (512x512 px)
  - [ ] Feature graphic (1024x500 px)
  - [ ] Screenshots (minimum 2, uploaded)
  - [ ] Privacy policy URL added
  - [ ] Content rating completed

- [ ] AAB uploaded to Internal Testing
- [ ] Release notes added (English + Hindi)
- [ ] Internal testers added (minimum 5)
- [ ] Test link shared with testers

### Testing
- [ ] Internal testing (1-2 weeks)
- [ ] No crashes reported (crash-free rate >99%)
- [ ] Critical bugs fixed
- [ ] User feedback addressed
- [ ] Promote to Beta track
- [ ] Beta testing (1-2 weeks)
- [ ] Final approval from stakeholders

### Production Release
- [ ] Promote to Production track
- [ ] Set staged rollout to 10%
- [ ] Monitor for 24 hours
- [ ] Check crash reports (0 critical crashes)
- [ ] Check ANR rate (<1%)
- [ ] Increase rollout to 25%
- [ ] Monitor for 24 hours
- [ ] Increase rollout to 50%
- [ ] Monitor for 24 hours
- [ ] Complete rollout to 100%

---

## iOS Deployment (App Store)

### Pre-Build
- [ ] Apple Developer account active ($99/year paid)
- [ ] Distribution certificate created
- [ ] Provisioning profile created
- [ ] App ID registered: `com.khetisahayak.app`
- [ ] Code signing configured in Xcode

### Build
- [ ] Run build script: `./scripts/build-ios.sh` (macOS only)
- [ ] IPA size < 30 MB
- [ ] Test on physical iOS device
- [ ] No crashes during testing

### App Store Connect
- [ ] App created in App Store Connect
- [ ] App information complete
- [ ] Store listing complete:
  - [ ] App name
  - [ ] Subtitle (30 chars)
  - [ ] Description (4000 chars)
  - [ ] Keywords
  - [ ] App icon (1024x1024 px)
  - [ ] Screenshots (all device sizes)
  - [ ] Privacy policy URL
  - [ ] Support URL
  - [ ] Marketing URL (optional)

### TestFlight Beta
- [ ] IPA uploaded via Transporter/Xcode/fastlane
- [ ] Build processed (wait ~30 minutes)
- [ ] Internal testers added
- [ ] Beta testing (1-2 weeks)
- [ ] Crash reports reviewed (crash-free >99.5%)
- [ ] User feedback addressed

### App Review Submission
- [ ] App Review Information completed:
  - [ ] Contact information
  - [ ] Demo account credentials (if login required)
  - [ ] Review notes (explain app functionality)
  - [ ] App walkthrough video (if helpful)

- [ ] Age rating completed
- [ ] Export compliance answered
- [ ] Content rights verified
- [ ] Submit for review
- [ ] Monitor review status (typically 1-3 days)

### Post-Approval
- [ ] Set release option (manual/automatic)
- [ ] Enable phased release (recommended)
- [ ] Monitor crash reports
- [ ] Respond to user reviews
- [ ] Track App Analytics

---

## Frontend Deployment (Vercel) - If Applicable

### Pre-Deploy
- [ ] Vercel account created
- [ ] GitHub repository connected
- [ ] Environment variables configured
- [ ] Build command verified
- [ ] Output directory correct

### Deploy
- [ ] Deploy preview environment first
- [ ] Test preview URL thoroughly
- [ ] Deploy to production: `vercel --prod`
- [ ] Custom domain configured (optional)

### Post-Deploy
- [ ] Homepage loads correctly
- [ ] All routes working
- [ ] API calls successful
- [ ] Check Lighthouse score (>90)
- [ ] Core Web Vitals passing
- [ ] Mobile responsive
- [ ] No console errors

---

## Post-Deployment Monitoring

### First 24 Hours
- [ ] Monitor backend API health every hour
- [ ] Check error rates (<1%)
- [ ] Monitor response times (<500ms)
- [ ] Check database query performance
- [ ] Review application logs
- [ ] Monitor memory usage
- [ ] Check CPU usage

### Mobile Apps (First Week)
- [ ] Crash-free rate >99.5%
- [ ] ANR rate <1% (Android)
- [ ] No critical bugs reported
- [ ] User reviews monitored daily
- [ ] Respond to reviews within 24 hours
- [ ] Track app ratings (target 4.5+)

### Performance Metrics
- [ ] API uptime >99.9%
- [ ] Average response time <500ms
- [ ] Database query time <100ms
- [ ] App launch time <3 seconds
- [ ] Screen transition smooth (<16ms frame time)

---

## Rollback Plan

### If Critical Issues Found

**Backend Rollback:**
```bash
# In Render Dashboard
1. Go to service → Events
2. Click previous successful deployment
3. Click "Redeploy"
```

**Android Rollback:**
1. Go to Play Console → Release management
2. Halt current staged rollout
3. Create new release with previous AAB
4. Deploy to 100%

**iOS Rollback:**
1. Cannot directly rollback
2. Submit new version with previous code
3. Request expedited review (if critical)

### Rollback Triggers
- [ ] Crash rate >2%
- [ ] Critical functionality broken
- [ ] Security vulnerability discovered
- [ ] Data loss or corruption
- [ ] Severe performance degradation

---

## Communication

### Internal Communication
- [ ] Notify team of deployment start
- [ ] Share deployment status updates
- [ ] Announce successful deployment
- [ ] Share monitoring dashboard links

### External Communication (If Major Release)
- [ ] Social media announcement
- [ ] Email to existing users
- [ ] Blog post about new features
- [ ] Update website/landing page
- [ ] Press release (if significant)

---

## Documentation

- [ ] Update CHANGELOG.md
- [ ] Update README.md (if needed)
- [ ] Update API documentation (if changed)
- [ ] Document new features
- [ ] Update deployment guide (if process changed)
- [ ] Create release notes
- [ ] Tag release in Git: `git tag v1.0.0`
- [ ] Push tag: `git push origin v1.0.0`

---

## Sign-Off

### Deployment Team
- [ ] DevOps Engineer: ___________________
- [ ] Backend Lead: ___________________
- [ ] Mobile Lead: ___________________
- [ ] QA Lead: ___________________

### Approvals
- [ ] CTO Approval: ___________________
- [ ] Product Manager: ___________________

### Deployment Complete
- [ ] **Date/Time:** ___________________
- [ ] **Duration:** ___________________
- [ ] **Status:** Success / Partial / Failed
- [ ] **Issues:** ___________________
- [ ] **Notes:** ___________________

---

## Next Steps After Deployment

1. **Monitor for 48 hours**
2. **Collect user feedback**
3. **Plan next release**
4. **Address bug reports**
5. **Analyze usage metrics**
6. **Optimize based on data**

---

**🎉 Deployment Complete! Well done team!**

*Keep this checklist for future deployments and update as needed.*
