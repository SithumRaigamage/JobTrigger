#!/bin/bash

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

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

# Header
log_header "🛑 Stopping JobTrigger Development Services"

# Check if using Docker or MongoDB Cloud
USE_DOCKER=${USE_DOCKER:-false}

log_info "Environment: $([ "$USE_DOCKER" = "true" ] && echo "Docker MongoDB" || echo "MongoDB Cloud (Atlas)")"

# Step 1: Handle MongoDB
if [ "$USE_DOCKER" = "true" ]; then
  log_step "Stopping MongoDB Docker container"
  log_info "Running: docker compose down"

  if docker compose down 2>/dev/null; then
    log_success "MongoDB container stopped"
    log_info "Container stopped, volumes preserved"
  else
    log_error "Failed to stop MongoDB container"
  fi
else
  log_step "MongoDB Cloud (Atlas)"
  log_info "No container to stop"
  log_info "MongoDB Cloud continues running in the cloud (you can keep it for later)"
fi

# Step 2: Backend
log_step "Node.js Backend"
log_warning "Backend (npm run dev) must be stopped manually"
log_info "In the backend terminal, press: Ctrl+C"

# Step 3: Show status
echo ""
log_step "Checking service status"

if docker ps -a 2>/dev/null | grep -q mongo; then
  log_warning "Docker containers still running"
  log_info "Run 'docker ps' to see containers"
else
  log_success "All Docker containers stopped"
fi

# Step 4: Cleanup options
echo ""
log_step "Data Management"
log_info "MongoDB data options:"
echo -e "  ${CYAN}docker compose up -d${NC}          → Restart with existing data"
echo -e "  ${CYAN}docker compose down -v${NC}        → Remove volume (wipe data)"
echo -e "  ${CYAN}USE_DOCKER=true ./setup-dev.sh${NC} → Restart Docker MongoDB"

# Step 5: Summary
echo ""
log_header "✨ Stopped Successfully"
log_success "Development services stopped"
log_info "Backend: Stopped (Ctrl+C pressed in terminal)"
log_info "MongoDB: $([ "$USE_DOCKER" = "true" ] && echo "Container stopped" || echo "Cloud running")"

echo ""
log_info "To restart:"
echo -e "  ${CYAN}./setup-dev.sh${NC}"

echo ""
log_info "To start fresh (Docker only):"
echo -e "  ${CYAN}docker compose down -v${NC}"
echo -e "  ${CYAN}USE_DOCKER=true ./setup-dev.sh${NC}"
