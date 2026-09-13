#!/bin/bash

echo "🛑 Stopping JobTrigger Development Services"
echo "==========================================="

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

# Check if using Docker or MongoDB Cloud
USE_DOCKER=${USE_DOCKER:-false}

if [ "$USE_DOCKER" = "true" ]; then
  # Step 1: Stop MongoDB container
  echo -e "${BLUE}🐳 Stopping MongoDB container...${NC}"
  docker compose down

  if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ MongoDB stopped${NC}"
  else
    echo -e "${RED}❌ Failed to stop MongoDB${NC}"
  fi
else
  echo -e "${BLUE}☁️  Using MongoDB Cloud (Atlas) — no container to stop${NC}"
fi

# Step 2: Inform about backend
echo -e "${BLUE}ℹ️  Backend (npm run dev) must be stopped manually${NC}"
echo -e "${BLUE}Press Ctrl+C in the backend terminal to stop it${NC}"

# Step 3: Summary
echo ""
echo -e "${GREEN}🎉 Done!${NC}"
echo -e "${BLUE}==========================================="
echo "To restart: run ./setup-dev.sh"
echo "To keep MongoDB data: docker compose up -d (without -v)"
echo "To wipe MongoDB data: docker compose down -v && docker compose up -d"
echo -e "===========================================${NC}"
