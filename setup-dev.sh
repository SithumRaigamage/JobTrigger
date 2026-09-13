#!/bin/bash

set -e

echo "🚀 JobTrigger Development Setup"
echo "================================"

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Check if using MongoDB Cloud or Local
USE_DOCKER=${USE_DOCKER:-false}

if [ "$USE_DOCKER" = "true" ]; then
  # Step 1: Start MongoDB via Docker
  echo -e "${BLUE}📦 Starting MongoDB via Docker...${NC}"
  docker compose up -d

  # Step 2: Wait for MongoDB to be ready
  echo -e "${BLUE}⏳ Waiting for MongoDB to be ready...${NC}"
  sleep 3

  # Retry logic for MongoDB
  for i in {1..30}; do
    if nc -z localhost 27017 2>/dev/null; then
      echo -e "${GREEN}✅ MongoDB is ready!${NC}"
      break
    fi
    echo -e "${YELLOW}Attempt $i/30: Waiting for MongoDB...${NC}"
    sleep 1
  done
else
  # Using MongoDB Cloud
  echo -e "${BLUE}☁️  Using MongoDB Cloud (Atlas)${NC}"

  if grep -q "mongodb+srv://" lab-trigger-backend/.env 2>/dev/null; then
    echo -e "${GREEN}✅ MongoDB Cloud connection string found in .env${NC}"
  else
    echo -e "${RED}⚠️  MongoDB Cloud URI not found in lab-trigger-backend/.env${NC}"
    echo -e "${YELLOW}Please add your connection string:${NC}"
    echo -e "  MONGODB_URI=mongodb+srv://username:password@cluster.mongodb.net/jobtrigger"
    echo ""
    exit 1
  fi
fi

# Step 3: Seed test account
echo -e "${BLUE}🌱 Seeding test account...${NC}"
SEED_RESPONSE=$(curl -s -X POST http://localhost:5001/api/auth/signup \
  -H "Content-Type: application/json" \
  -d '{"email":"test@jobtrigger.dev","password":"password123"}')

if echo "$SEED_RESPONSE" | grep -q "email\|already"; then
  echo -e "${GREEN}✅ Test account ready (test@jobtrigger.dev / password123)${NC}"
else
  echo -e "${YELLOW}ℹ️  Seed response: $SEED_RESPONSE${NC}"
fi

# Step 4: Start backend
echo -e "${GREEN}🎉 All set! Starting backend...${NC}"
echo -e "${BLUE}================================${NC}"
cd lab-trigger-backend
npm run dev
