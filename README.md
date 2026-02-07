# 🚀 JobTrigger

> **Trigger Jenkins builds from anywhere — An iOS app for DevOps engineers**

[![iOS](https://img.shields.io/badge/iOS-16.0+-blue.svg)](https://developer.apple.com/ios/)
[![Swift](https://img.shields.io/badge/Swift-5.9-orange.svg)](https://swift.org/)
[![SwiftUI](https://img.shields.io/badge/SwiftUI-4.0-green.svg)](https://developer.apple.com/xcode/swiftui/)
[![License](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

---

## 🎯 Product Vision

laTrigger enables developers and DevOps engineers to securely trigger, monitor, and manage Jenkins jobs directly from an iOS device—anytime, anywhere.

## ✨ Features (MVP)

- 🔐 **Secure Authentication** — Connect using Jenkins API tokens
- 📱 **Multiple Servers** — Manage dev, staging, and prod environments
- 📋 **Job Management** — View, search, and organize Jenkins jobs
- 🚀 **One-Tap Trigger** — Start builds instantly
- ⚙️ **Build Parameters** — Pass parameters before triggering
- 📊 **Real-Time Status** — Monitor build progress
- 📄 **Build Logs** — View console output
- 🌙 **Dark Mode** — Easy on the eyes

## 🏗️ Architecture

```
iOS App (Swift / SwiftUI)
   │
   │ HTTPS + API Token
   │
Jenkins REST API
   │
Jenkins Jobs / Pipelines
```

## 📚 Documentation

All project documentation is available in the [`/docs`](./docs) folder:

| Document | Description |
|----------|-------------|
| [📋 Product Requirements](./docs/01-product-requirements-document.md) | PRD with vision, goals, and requirements |
| [📝 User Stories](./docs/02-user-stories.md) | Jira-ready stories with acceptance criteria |
| [🏛️ Technical Architecture](./docs/03-technical-architecture.md) | System design and components |
| [🔒 Security Design](./docs/04-security-design.md) | Threat model and security controls |
| [🧪 Test Plan](./docs/05-test-plan.md) | Test strategy and test cases |
| [🚀 Release Plan](./docs/06-release-plan.md) | Release strategy and App Store plan |
| [🎨 UX Design](./docs/07-ux-design.md) | UI screens and design system |
| [📈 Monitoring](./docs/08-monitoring-analytics.md) | Analytics and observability |
| [🗺️ Roadmap](./docs/09-future-roadmap.md) | Future enhancements |

## 🛠️ Tech Stack

| Layer | Technology |
|-------|------------|
| Language | Swift 5.9 |
| UI | SwiftUI |
| Networking | URLSession |
| Security | iOS Keychain |
| Persistence | CoreData |
| Analytics | Firebase |

## 📱 Requirements

- iOS 16.0+
- Jenkins 2.x with REST API enabled
- Valid Jenkins API token

## 🚦 Project Status

| Phase | Status | Timeline |
|-------|--------|----------|
| Discovery & Planning | 🟢 Complete | Feb 2026 |
| UX & Architecture | 🟡 In Progress | Mar 2026 |
| MVP Development | ⚪ Pending | Apr-May 2026 |
| Testing & QA | ⚪ Pending | Jun 2026 |
| Release | ⚪ Pending | Jun 2026 |

## 👥 Target Users

- **DevOps Engineers** — Trigger pipelines on the go
- **Backend Engineers** — Quick access to build status
- **Team Leads** — Visibility before releases
- **Release Managers** — Approve and deploy

## 🔐 Security

- API tokens only (no password storage)
- iOS Keychain for credential storage
- HTTPS/TLS 1.2+ enforced
- Optional Face ID/Touch ID lock

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🤝 Contributing

Contributions are welcome! Please read our contributing guidelines before submitting PRs.

---

*Made with ❤️ for the DevOps community*
