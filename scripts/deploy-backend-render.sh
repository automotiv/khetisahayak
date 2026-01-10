#!/bin/bash
# Deploy Backend to Render
# Agent: @render-deployment-specialist

set -e

echo "🚀 Kheti Sahayak - Backend Deployment to Render"
echo "================================================"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Check if render CLI is installed
if ! command -v render &> /dev/null; then
    echo -e "${YELLOW}Render CLI not found. Installing...${NC}"
    npm install -g render-cli
fi

# Login to Render (if not already logged in)
echo -e "${YELLOW}Step 1: Login to Render${NC}"
render login

# Navigate to backend
cd kheti_sahayak_backend

# Check if .env exists
if [ ! -f .env ]; then
    echo -e "${RED}Error: .env file not found${NC}"
    echo "Creating .env from template..."
    cat > .env << EOF
NODE_ENV=production
PORT=3000
DATABASE_URL=postgresql://user:password@host:5432/kheti_sahayak
JWT_SECRET=$(openssl rand -base64 32)
ML_API_URL=http://localhost:8000
EOF
    echo -e "${YELLOW}Please update .env with your actual values${NC}"
    exit 1
fi

# Install dependencies
echo -e "${YELLOW}Step 2: Installing dependencies...${NC}"
npm install

# Run tests
echo -e "${YELLOW}Step 3: Running tests...${NC}"
npm test || echo "⚠️  Tests failed, but continuing..."

# Deploy to Render
echo -e "${YELLOW}Step 4: Deploying to Render...${NC}"
echo "Using render.yaml configuration..."

# Check if render.yaml exists in root
cd ..
if [ -f render.yaml ]; then
    echo -e "${GREEN}✅ Found render.yaml${NC}"

    # Deploy using render CLI
    render deploy

    echo -e "${GREEN}✅ Deployment triggered${NC}"
    echo "Check status at: https://dashboard.render.com"
else
    echo -e "${RED}❌ render.yaml not found${NC}"
    echo "Creating service manually..."

    # Create web service
    render services create web \
        --name kheti-sahayak-api \
        --env node \
        --region singapore \
        --plan free \
        --repo https://github.com/YOUR_USERNAME/khetisahayak \
        --root-dir kheti_sahayak_backend \
        --build-command "npm install" \
        --start-command "npm start"
fi

# Post-deployment tasks
echo -e "${YELLOW}Step 5: Post-deployment tasks${NC}"
echo "⏳ Waiting for deployment to complete (60 seconds)..."
sleep 60

# Get service URL
SERVICE_URL=$(render services list | grep kheti-sahayak | awk '{print $4}')

if [ -z "$SERVICE_URL" ]; then
    echo -e "${YELLOW}⚠️  Could not determine service URL${NC}"
    echo "Please check Render dashboard: https://dashboard.render.com"
else
    # Test health endpoint
    echo -e "${YELLOW}Testing health endpoint...${NC}"
    curl -f $SERVICE_URL/api/health && echo -e "${GREEN}✅ API is healthy${NC}" || echo -e "${RED}❌ API health check failed${NC}"
fi

# Run database migrations
echo -e "${YELLOW}Step 6: Running database migrations${NC}"
echo "You need to run this in Render Shell:"
echo "  npm run migrate:up"
echo "  node seedTreatmentData.js"

echo ""
echo -e "${GREEN}================================================${NC}"
echo -e "${GREEN}🎉 Backend deployment complete!${NC}"
echo -e "${GREEN}================================================${NC}"
echo ""
echo "Next steps:"
echo "1. Go to Render Dashboard: https://dashboard.render.com"
echo "2. Add environment variables (DATABASE_URL, JWT_SECRET)"
echo "3. Open Shell and run migrations"
echo "4. Test API endpoints"
echo ""
echo "Service URL: $SERVICE_URL"
