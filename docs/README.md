# JobTrigger Documentation

Complete reference for the JobTrigger Flutter + Node.js project.

---

## 🚀 Getting Started

- **[Dev Setup Guide](./dev-setup.md)** — Start the backend + database, use `setup-dev.sh` / `stop-dev.sh`
- **[MongoDB Cloud Setup](./mongodb-cloud-setup.md)** — Configure MongoDB Atlas for development
- **[API Reference](./api-reference.md)** — All backend + Jenkins endpoints this app calls

---

## 🏗️ Architecture & Design

- **[Architecture Overview](./architecture.md)** — Layers, data flow, why Riverpod
- **[Data Models](./data-models.md)** — Every model: Swift → Dart, old → new
- **[State Management](./state-management.md)** — Riverpod provider structure per feature
- **[Migration Strategy](./migration-strategy.md)** — Phased rollout, parity checklist, QA gates

## 🗄️ Database

- **[Database Migrations](./database-migrations.md)** — Schema, collections, migration scripts, cleanup

---

## 🛠️ Development Guides

- **[Dev Setup](./dev-setup.md)** — What `setup-dev.sh` and `stop-dev.sh` do
- **[MongoDB Cloud](./mongodb-cloud-setup.md)** — MongoDB Atlas configuration
- **[CLAUDE.md](../CLAUDE.md)** — Project rules, conventions, tech stack decisions

---

## 📋 Project Status

- **[Tasks & Phases](../tasks/README.md)** — Current status, phase checklist, what's done

---

## 🔍 Quick Navigation

| Need | Read |
|------|------|
| How to start development | [Dev Setup](./dev-setup.md) |
| Backend endpoints | [API Reference](./api-reference.md) |
| App architecture | [Architecture](./architecture.md) |
| Riverpod setup | [State Management](./state-management.md) |
| Old → new models | [Data Models](./data-models.md) |
| Migration timeline | [Migration Strategy](./migration-strategy.md) |
| Database schema & migrations | [Database Migrations](./database-migrations.md) |
| Project rules | [CLAUDE.md](../CLAUDE.md) |
| What's left to do | [Tasks](../tasks/README.md) |

---

## ⚡ Common Commands

```bash
# Start backend + database (MongoDB Cloud)
./setup-dev.sh

# Start backend + database (local Docker)
USE_DOCKER=true ./setup-dev.sh

# Stop services
./stop-dev.sh

# Build Flutter app
cd job_trigger
flutter pub get
dart run build_runner build --delete-conflicting-outputs

# Run Flutter app
flutter run -d "iPhone Air"

# Run tests
flutter test

# Analyze code
flutter analyze
```

---

## 🔐 Security Rules

- ⛔ **Never read `.env` files** — they contain credentials
- ⛔ **Never hardcode base URLs** — use `JobTrigger-Frontend/config/`
- ✅ **Store tokens in secure storage** — `flutter_secure_storage` only
- ✅ **Return `AppFailure` from repos** — never leak raw `DioException` to widgets

See [CLAUDE.md](../CLAUDE.md) for full rules.

---

## 📞 Support

- Check the relevant doc above
- Review [CLAUDE.md](../CLAUDE.md) for project conventions
- Look at [API Reference](./api-reference.md) for endpoint questions
- Check [Tasks](../tasks/README.md) for status & in-progress work
