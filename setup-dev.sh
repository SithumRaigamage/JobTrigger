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

# Phase 17: the database is MongoDB Atlas, always. There is no local
# MongoDB; docs/mongodb-cloud-setup.md sets up the dev cluster.
log_info "Database: MongoDB Atlas (docs/mongodb-cloud-setup.md)"

# Step 1: Check the connection string is there (never printed: it holds
# the database password)
log_step "Checking the Atlas connection string"
if grep -qE "^MONGODB_URI=[\"']?mongodb\+srv://" JobTrigger-Backend/.env 2>/dev/null; then
  log_success "MONGODB_URI found in JobTrigger-Backend/.env"
else
  log_error "No Atlas MONGODB_URI in JobTrigger-Backend/.env"
  log_info "Set it up with docs/mongodb-cloud-setup.md, then add:"
  echo -e "  ${YELLOW}MONGODB_URI=mongodb+srv://USER:PASSWORD@CLUSTER.mongodb.net/jobtrigger${NC}"
  echo ""
  exit 1
fi

# Step 2: Seed the dev data
# AUD-58: setup-migrations.js writes a test account whose password is in
# the README, so it refuses a remote database unless --allow-remote. It
# still refuses NODE_ENV=production and any URI that names production
# ("prod" in its user, cluster, database or appName), forced or not.
# Seeding is safe to repeat. SEED_REMOTE=false skips it.
log_step "Seeding the Atlas dev database"
if [ "${SEED_REMOTE:-true}" = "false" ]; then
  SEEDED=false
  log_warning "SEED_REMOTE=false: the database is used as it is"
else
  SEEDED=true
  log_info "Dev account, sample Jenkins servers, app info (existing ones are kept)"
  # Checked with `if`, not `$?`: under `set -e` a failing command would
  # end the script before its exit code could be read.
  if (cd JobTrigger-Backend && node scripts/setup-migrations.js --allow-remote); then
    log_success "Seeding completed"
  else
    log_error "Seeding failed (see the error above); the backend was not started"
    exit 1
  fi
fi

# Step 4: Summary
echo ""
log_header "✨ Setup Complete!"
log_success "Development environment ready"
log_info "Backend will run on: http://127.0.0.1:5001"
log_info "Database: MongoDB Atlas"
if [ "$SEEDED" = "false" ]; then
  LOGIN_HINT="an account that already exists in the Atlas database"
else
  LOGIN_HINT="developer@jobtrigger.app / SecurePassword123!"
  log_info "Seeded Jenkins servers: Production CI, Staging Pipeline, Development Build"
fi
log_info "Log in with: $LOGIN_HINT"

echo ""
log_info "Next steps:"
echo "  1. Open a new terminal and run:"
echo -e "     ${CYAN}cd JobTrigger-Frontend${NC}"
echo -e "     ${CYAN}flutter run -d \"iPhone Air\"${NC}"
echo "  2. Log in with: $LOGIN_HINT"
echo "  3. Check 'Remember me' checkbox ✨"

echo ""
log_header "🚀 Starting Backend (Node.js)"
log_info "The backend is up when you see \"server.listening\" with port 5001 below."
log_info "It keeps running in this terminal (restarting on file changes); press Ctrl+C to stop it."
echo ""

# Step 3: Start backend
cd JobTrigger-Backend
npm run dev
