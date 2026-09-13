#!/bin/bash

set -e

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Log levels
log_header() {
  echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${BLUE}$1${NC}"
  echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

log_info() {
  echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
  echo -e "${GREEN}✅ $1${NC}"
}

log_warning() {
  echo -e "${YELLOW}⚠️  $1${NC}"
}

log_error() {
  echo -e "${RED}❌ $1${NC}"
}

log_step() {
  echo -e "\n${BLUE}▶ STEP: $1${NC}"
}

# Start
log_header "🚀 JobTrigger Development Setup"

# Check if using MongoDB Cloud or Local
USE_DOCKER=${USE_DOCKER:-false}

log_info "Environment: $([ "$USE_DOCKER" = "true" ] && echo "Docker MongoDB" || echo "MongoDB Cloud (Atlas)")"

if [ "$USE_DOCKER" = "true" ]; then
  # Step 1: Start MongoDB via Docker
  log_step "Starting MongoDB via Docker"
  log_info "Running: docker compose up -d"
  docker compose up -d
  log_success "Docker container started"

  # Step 2: Wait for MongoDB to be ready
  log_step "Waiting for MongoDB to become ready"
  sleep 2
  log_info "Checking MongoDB connection on localhost:27017..."

  # Retry logic for MongoDB
  MONGO_READY=false
  for i in {1..30}; do
    if nc -z localhost 27017 2>/dev/null; then
      log_success "MongoDB is ready (attempt $i/30)"
      MONGO_READY=true
      break
    fi
    echo -ne "${YELLOW}  Attempt $i/30...${NC}\r"
    sleep 1
  done

  if [ "$MONGO_READY" = false ]; then
    log_error "MongoDB failed to start after 30 attempts"
    exit 1
  fi
else
  # Using MongoDB Cloud
  log_step "Verifying MongoDB Cloud connection"
  log_info "Checking for connection string in JobTrigger-Backend/.env..."

  if grep -q "mongodb+srv://" JobTrigger-Backend/.env 2>/dev/null; then
    log_success "MongoDB Cloud connection string found in .env"
  else
    log_error "MongoDB Cloud URI not found in JobTrigger-Backend/.env"
    log_info "Please add your connection string:"
    echo -e "  ${YELLOW}MONGODB_URI=mongodb+srv://username:password@cluster.mongodb.net/jobtrigger${NC}"
    echo ""
    exit 1
  fi
fi

# Step 3: Run database migrations & seed data
log_step "Running database migrations"
log_info "Setting up collections, users, and Jenkins credentials..."

if [ -f "JobTrigger-Backend/scripts/setup-migrations.js" ]; then
  cd JobTrigger-Backend
  node scripts/setup-migrations.js
  MIGRATION_EXIT=$?
  cd ..

  if [ $MIGRATION_EXIT -eq 0 ]; then
    log_success "Database migrations completed successfully"
  else
    log_error "Database migrations failed"
    exit 1
  fi
else
  log_warning "Migration script not found, skipping"
fi

# Step 4: Summary
echo ""
log_header "✨ Setup Complete!"
log_success "Development environment ready"
log_info "Backend running on: http://127.0.0.1:5001"
log_info "Login credentials: developer@jobtrigger.app / SecurePassword123!"
log_info "MongoDB: $([ "$USE_DOCKER" = "true" ] && echo "Docker (localhost:27017)" || echo "Atlas Cloud")"
log_info "Jenkins servers: Production CI, Staging Pipeline, Development Build"

echo ""
log_info "Next steps:"
echo "  1. Open a new terminal and run:"
echo -e "     ${CYAN}cd job_trigger${NC}"
echo -e "     ${CYAN}flutter run -d \"iPhone Air\"${NC}"
echo "  2. Login with: developer@jobtrigger.app / SecurePassword123!"
echo "  3. Check 'Remember me' checkbox ✨"

echo ""
log_header "🚀 Starting Backend (Node.js)"
echo ""

# Step 5: Start backend
cd JobTrigger-Backend
npm run dev
