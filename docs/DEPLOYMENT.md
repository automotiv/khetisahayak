# Deployment Guide

This guide covers deploying Kheti Sahayak to Render (backend) and Vercel (frontend).

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                        Internet                              │
└─────────────────────────────────────────────────────────────┘
                    │                       │
                    ▼                       ▼
┌──────────────────────────┐    ┌──────────────────────────┐
│       Vercel             │    │        Render            │
│  (Frontend - React)      │    │   (Backend - Node.js)    │
│                          │    │                          │
│  kheti-sahayak.vercel.app│───▶│  kheti-sahayak-backend   │
│                          │    │    .onrender.com         │
└──────────────────────────┘    └──────────────────────────┘
                                            │
                                            ▼
                                ┌──────────────────────────┐
                                │   Render PostgreSQL      │
                                │   (Database)             │
                                └──────────────────────────┘
```

---

## Backend Deployment (Render)

### Option 1: Blueprint Deployment (Recommended)

1. **Connect Repository**
   - Go to [Render Dashboard](https://dashboard.render.com)
   - Click **New** → **Blueprint**
   - Connect your GitHub repository
   - Render will automatically detect `render.yaml`

2. **Review Services**
   - Web Service: `kheti-sahayak-backend`
   - Database: `kheti-sahayak-db` (PostgreSQL)

3. **Configure Secrets**
   After deployment, set these in Render Dashboard → Environment:
   ```
   GOOGLE_CLIENT_ID=your_google_oauth_client_id
   GOOGLE_CLIENT_ID_IOS=your_ios_client_id
   GOOGLE_CLIENT_ID_ANDROID=your_android_client_id
   FACEBOOK_APP_ID=your_facebook_app_id
   FACEBOOK_APP_SECRET=your_facebook_app_secret
   SMTP_HOST=smtp.gmail.com
   SMTP_PORT=587
   SMTP_USER=your_email@gmail.com
   SMTP_PASS=your_app_password
   SENTRY_DSN=your_sentry_dsn
   ```

4. **Deploy**
   - Click **Apply** to deploy all services
   - Wait for database to be ready first
   - Backend will run migrations automatically

### Option 2: Manual Service Creation

1. **Create PostgreSQL Database**
   - Render Dashboard → New → PostgreSQL
   - Name: `kheti-sahayak-db`
   - Region: Singapore
   - Plan: Free

2. **Create Web Service**
   - Render Dashboard → New → Web Service
   - Connect GitHub repo
   - Root Directory: `kheti_sahayak_backend`
   - Build Command: `npm install && npm run migrate:up`
   - Start Command: `npm start`
   - Add environment variables from database

### GitHub Actions Auto-Deploy

For automatic deployments via GitHub Actions:

1. **Get Render API Key**
   - Render Dashboard → Account Settings → API Keys
   - Create a new API key

2. **Get Service ID**
   - Go to your service in Render
   - Copy the Service ID from the URL: `https://dashboard.render.com/web/srv-xxxxx`

3. **Add GitHub Secrets**
   ```
   RENDER_API_KEY=rnd_xxxxxxxxxxxxx
   RENDER_SERVICE_ID=srv-xxxxxxxxxxxxx
   ```

4. **Workflow Triggers**
   - Auto-deploys on push to `main` branch
   - Only when `kheti_sahayak_backend/**` files change
   - Manual trigger available via workflow_dispatch

### Health Check

After deployment, verify:
```bash
curl https://kheti-sahayak-backend.onrender.com/api/health
```

Expected response:
```json
{
  "status": "ok",
  "timestamp": "2025-01-13T...",
  "services": {
    "database": "connected"
  }
}
```

---

## Frontend Deployment (Vercel)

### Option 1: Vercel Dashboard (Recommended for First Deploy)

1. **Import Project**
   - Go to [Vercel Dashboard](https://vercel.com/dashboard)
   - Click **Add New** → **Project**
   - Import your GitHub repository

2. **Configure Project**
   - Framework Preset: Vite
   - Root Directory: `frontend`
   - Build Command: `npm run build`
   - Output Directory: `dist`

3. **Environment Variables**
   Add in Vercel Dashboard → Settings → Environment Variables:
   ```
   VITE_API_BASE_URL=https://kheti-sahayak-backend.onrender.com/api
   ```

4. **Deploy**
   - Click **Deploy**
   - Vercel auto-detects settings from `vercel.json`

### Option 2: Vercel CLI

```bash
# Install Vercel CLI
npm install -g vercel

# Login
vercel login

# Deploy from frontend directory
cd frontend
vercel

# For production
vercel --prod
```

### GitHub Actions Auto-Deploy

For automatic deployments:

1. **Get Vercel Credentials**
   ```bash
   # Get your Vercel token
   vercel login
   
   # Link project and get IDs
   cd frontend
   vercel link
   ```

   This creates `.vercel/project.json` with:
   ```json
   {
     "orgId": "team_xxxxx",
     "projectId": "prj_xxxxx"
   }
   ```

2. **Add GitHub Secrets**
   ```
   VERCEL_TOKEN=your_vercel_token
   VERCEL_ORG_ID=team_xxxxx (or user ID)
   VERCEL_PROJECT_ID=prj_xxxxx
   VITE_API_BASE_URL=https://kheti-sahayak-backend.onrender.com/api
   ```

3. **Workflow Features**
   - **Preview deployments** on Pull Requests (with comment)
   - **Production deployment** on push to `main`
   - Type checking before deploy

---

## Environment Variables Summary

### Backend (Render)

| Variable | Required | Description |
|----------|----------|-------------|
| `DATABASE_URL` | Yes | Auto-set by Render |
| `JWT_SECRET` | Yes | Auto-generated |
| `NODE_ENV` | Yes | Set to `production` |
| `PORT` | Yes | Set to `10000` |
| `GOOGLE_CLIENT_ID` | No | OAuth |
| `FACEBOOK_APP_ID` | No | OAuth |
| `SMTP_*` | No | Email service |
| `SENTRY_DSN` | No | Error monitoring |

### Frontend (Vercel)

| Variable | Required | Description |
|----------|----------|-------------|
| `VITE_API_BASE_URL` | Yes | Backend API URL |

---

## CI/CD Pipeline Flow

```
┌─────────────────────────────────────────────────────────────────┐
│                     GitHub Push to main                          │
└─────────────────────────────────────────────────────────────────┘
                              │
          ┌───────────────────┴───────────────────┐
          │                                       │
          ▼                                       ▼
┌─────────────────────┐               ┌─────────────────────┐
│  Backend Changed?   │               │  Frontend Changed?  │
│ (kheti_sahayak_     │               │    (frontend/*)     │
│    backend/*)       │               │                     │
└─────────────────────┘               └─────────────────────┘
          │ Yes                                   │ Yes
          ▼                                       ▼
┌─────────────────────┐               ┌─────────────────────┐
│    Run Tests        │               │  Lint & Type Check  │
│   (PostgreSQL CI)   │               │     Build Check     │
└─────────────────────┘               └─────────────────────┘
          │                                       │
          ▼                                       ▼
┌─────────────────────┐               ┌─────────────────────┐
│  Deploy to Render   │               │  Deploy to Vercel   │
│   (via API call)    │               │   (Vercel CLI)      │
└─────────────────────┘               └─────────────────────┘
          │                                       │
          ▼                                       ▼
┌─────────────────────┐               ┌─────────────────────┐
│   Health Check      │               │  Production Live    │
│   /api/health       │               │                     │
└─────────────────────┘               └─────────────────────┘
```

---

## Troubleshooting

### Backend (Render)

**Issue: Build fails**
```bash
# Check build logs in Render Dashboard
# Common fix: ensure package-lock.json is committed
git add package-lock.json
git commit -m "Add package-lock.json"
```

**Issue: Database connection fails**
- Ensure database is fully provisioned (can take 5-10 minutes)
- Check DATABASE_URL is correctly set
- Verify IP allowlist if using external database

**Issue: Service sleeps (free tier)**
- Free tier services sleep after 15 minutes of inactivity
- First request after sleep takes ~30s (cold start)
- Consider upgrading for always-on

### Frontend (Vercel)

**Issue: API calls fail (CORS)**
- Ensure backend has CORS configured for Vercel domain
- Check `VITE_API_BASE_URL` is set correctly

**Issue: Build fails on TypeScript**
```bash
# Run locally to check errors
cd frontend
npm run build
```

**Issue: Routes return 404**
- `vercel.json` rewrites handle SPA routing
- Ensure rewrites configuration is present

---

## Monitoring & Logs

### Render
- **Logs**: Dashboard → Service → Logs
- **Metrics**: Dashboard → Service → Metrics
- **Alerts**: Set up in Dashboard → Settings

### Vercel
- **Logs**: Dashboard → Project → Deployments → Functions
- **Analytics**: Dashboard → Project → Analytics
- **Speed Insights**: Dashboard → Project → Speed Insights

---

## Cost Estimation

### Free Tier Limits

| Service | Render Free | Vercel Free |
|---------|-------------|-------------|
| **Compute** | 750 hours/month | 100GB bandwidth |
| **Database** | 1GB storage, 90-day retention | N/A |
| **Bandwidth** | 100GB/month | 100GB/month |
| **Builds** | Unlimited | 6000 min/month |
| **Sleep** | After 15min inactive | No sleep |

### Recommended Production Setup

| Component | Service | Plan | ~Cost/month |
|-----------|---------|------|-------------|
| Backend | Render Starter | $7 | Always-on |
| Database | Render Starter | $7 | 1GB storage |
| Frontend | Vercel Pro | $20 | Team features |

---

## Quick Reference

### URLs

| Environment | Frontend | Backend | API Docs |
|-------------|----------|---------|----------|
| Production | `kheti-sahayak.vercel.app` | `kheti-sahayak-backend.onrender.com` | `/api-docs` |
| Preview | `kheti-sahayak-*.vercel.app` | N/A | N/A |

### Manual Deploy Commands

```bash
# Backend - trigger via GitHub Actions
git push origin main

# Frontend - manual deploy
cd frontend
vercel --prod

# Force redeploy backend
curl -X POST "https://api.render.com/v1/services/$SERVICE_ID/deploys" \
  -H "Authorization: Bearer $RENDER_API_KEY"
```
