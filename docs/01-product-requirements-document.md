# Product Requirements Document (PRD)
## laTrigger — iOS Jenkins Build Trigger App

| Document Info | |
|---------------|---|
| **Version** | 1.0 |
| **Date** | February 7, 2026 |
| **Author** | laTrigger Team |
| **Status** | Draft |

---

## 1. Executive Summary

laTrigger is a native iOS application that enables developers and DevOps engineers to securely trigger, monitor, and manage Jenkins jobs directly from their iOS devices. The app provides a mobile-first experience for CI/CD pipeline management, allowing users to stay connected to their build processes anytime, anywhere.

---

## 2. Product Vision

> *"Empower developers to control their CI/CD pipelines from anywhere with a secure, intuitive iOS experience."*

### 2.1 Problem Statement

DevOps engineers and developers often need to trigger Jenkins builds when they're away from their workstations. Current solutions require VPN access and browser-based interactions, which are cumbersome on mobile devices. There's a need for a dedicated, secure, and user-friendly mobile application to manage Jenkins jobs on the go.

### 2.2 Solution

laTrigger provides:
- Native iOS app with intuitive SwiftUI interface
- Secure authentication via Jenkins API tokens
- One-tap build triggering with parameter support
- Real-time build status monitoring
- Push notifications for build completion

---

## 3. Goals & Success Metrics

### 3.1 Business Goals

| Goal | Target | Timeline |
|------|--------|----------|
| MVP Launch | TestFlight Beta | Q2 2026 |
| App Store Release | Production | Q3 2026 |
| Active Users | 1,000+ | Q4 2026 |
| User Retention | 60% monthly | Q4 2026 |

### 3.2 Key Performance Indicators (KPIs)

| KPI | Target |
|-----|--------|
| Build trigger success rate | > 99% |
| API response time | < 2 seconds |
| App crash rate | < 0.1% |
| User satisfaction (App Store rating) | ≥ 4.5 stars |
| Push notification delivery rate | > 95% |

---

## 4. Stakeholders

### 4.1 Primary Users
- **DevOps Engineers**: Need quick access to trigger and monitor pipelines
- **Backend Engineers**: Want to trigger builds for their services remotely

### 4.2 Secondary Users
- **Team Leads**: Require visibility into build status before releases
- **Release Managers**: Need to approve and trigger release builds

### 4.3 Internal Stakeholders
- **Development Team**: Responsible for app development
- **Security Team**: Ensures secure credential handling
- **QA Team**: Validates functionality and user experience

### 4.4 External Systems
- Jenkins Server (REST API)
- GitHub/GitLab (future integration)
- Apple Push Notification Service (APNs)

---

## 5. Functional Requirements

### 5.1 Authentication & Server Management

| ID | Requirement | Priority |
|----|-------------|----------|
| FR-01 | User shall authenticate with Jenkins using API token | P0 |
| FR-02 | User shall save multiple Jenkins server configurations | P1 |
| FR-03 | User shall switch between saved Jenkins servers | P1 |
| FR-04 | User shall edit/delete saved server configurations | P1 |
| FR-05 | App shall validate server connectivity on setup | P0 |

### 5.2 Job Management

| ID | Requirement | Priority |
|----|-------------|----------|
| FR-06 | User shall view all available Jenkins jobs | P0 |
| FR-07 | User shall search/filter jobs by name | P0 |
| FR-08 | User shall view job details and configuration | P1 |
| FR-09 | User shall mark jobs as favorites | P2 |
| FR-10 | User shall view job build history | P1 |

### 5.3 Build Triggering

| ID | Requirement | Priority |
|----|-------------|----------|
| FR-11 | User shall trigger a job with one tap | P0 |
| FR-12 | User shall pass parameters before triggering | P0 |
| FR-13 | User shall see confirmation before triggering | P1 |
| FR-14 | User shall cancel a running build | P2 |
| FR-15 | App shall show immediate feedback on trigger | P0 |

### 5.4 Build Monitoring

| ID | Requirement | Priority |
|----|-------------|----------|
| FR-16 | User shall view current build status | P0 |
| FR-17 | User shall view build progress percentage | P1 |
| FR-18 | User shall view build logs (last N lines) | P1 |
| FR-19 | User shall refresh build status manually | P0 |
| FR-20 | App shall auto-refresh build status | P2 |

### 5.5 Notifications

| ID | Requirement | Priority |
|----|-------------|----------|
| FR-21 | User shall receive push notification on build completion | P1 |
| FR-22 | User shall configure notification preferences | P2 |
| FR-23 | User shall enable/disable notifications per job | P2 |

---

## 6. Non-Functional Requirements

### 6.1 Security

| ID | Requirement |
|----|-------------|
| NFR-01 | Credentials stored in iOS Keychain only |
| NFR-02 | All API calls over HTTPS/TLS 1.2+ |
| NFR-03 | No password storage—API tokens only |
| NFR-04 | Certificate pinning for API calls |
| NFR-05 | Biometric authentication option (Face ID/Touch ID) |

### 6.2 Performance

| ID | Requirement |
|----|-------------|
| NFR-06 | API calls complete within 3 seconds |
| NFR-07 | App launch time < 2 seconds |
| NFR-08 | Smooth scrolling at 60 FPS |
| NFR-09 | Memory usage < 100MB |

### 6.3 Reliability

| ID | Requirement |
|----|-------------|
| NFR-10 | App crash rate < 0.1% |
| NFR-11 | Graceful handling of network failures |
| NFR-12 | Offline-safe UI with cached data |
| NFR-13 | 99.9% uptime for app functionality |

### 6.4 Compatibility

| ID | Requirement |
|----|-------------|
| NFR-14 | iOS 16.0+ support |
| NFR-15 | iPhone and iPad support |
| NFR-16 | Jenkins 2.x LTS compatibility |
| NFR-17 | Dark mode support |

### 6.5 Accessibility

| ID | Requirement |
|----|-------------|
| NFR-18 | VoiceOver support |
| NFR-19 | Dynamic Type support |
| NFR-20 | Minimum touch target size 44x44pt |

---

## 7. User Personas

### Persona 1: DevOps Dave
- **Role**: Senior DevOps Engineer
- **Age**: 32
- **Tech Savvy**: High
- **Goals**: 
  - Trigger pipelines quickly when away from laptop
  - Monitor critical builds during incidents
  - Reduce time to deploy hotfixes
- **Pain Points**:
  - VPN is slow and unreliable on mobile
  - Jenkins web UI is not mobile-friendly
  - Can't get build notifications on the go
- **Quote**: *"I want to trigger pipelines quickly when I'm away from my laptop."*

### Persona 2: Team Lead Tanya
- **Role**: Engineering Team Lead
- **Age**: 38
- **Tech Savvy**: Medium-High
- **Goals**:
  - Visibility into build status before releases
  - Quick approval of release builds
  - Team build health overview
- **Pain Points**:
  - Needs to open laptop just to check build status
  - No quick way to see if release pipeline passed
- **Quote**: *"I want visibility into build status before releases."*

---

## 8. Scope

### 8.1 In Scope (MVP)
- Single/Multiple Jenkins server connections
- API token authentication
- Job listing and search
- Build triggering with parameters
- Build status monitoring
- Push notifications

### 8.2 Out of Scope (MVP)
- GitHub/GitLab PR triggers
- Slack/Teams integration
- Jenkins Blue Ocean support
- macOS/watchOS versions
- Jenkinsfile preview/editing
- Multi-user/team features

---

## 9. Assumptions & Dependencies

### 9.1 Assumptions
- Users have valid Jenkins API tokens
- Jenkins server is accessible over HTTPS
- Users have permission to trigger builds
- Jenkins REST API is enabled

### 9.2 Dependencies
- Jenkins REST API availability
- Apple Push Notification Service
- iOS Keychain Services
- Network connectivity

---

## 10. Risks & Mitigations

| Risk | Impact | Probability | Mitigation |
|------|--------|-------------|------------|
| Jenkins API changes | High | Low | Version detection, graceful degradation |
| Token security breach | Critical | Low | Keychain storage, certificate pinning |
| App Store rejection | High | Medium | Privacy policy, security audit |
| Poor network conditions | Medium | High | Offline caching, retry logic |
| Complex Jenkins setups | Medium | Medium | Progressive feature support |

---

## 11. Timeline

| Phase | Duration | Target Date |
|-------|----------|-------------|
| Phase 1: Discovery & Planning | 2 weeks | Feb 2026 |
| Phase 2: UX & Architecture | 3 weeks | Mar 2026 |
| Phase 3: MVP Development | 8 weeks | May 2026 |
| Phase 4: Security & Hardening | 2 weeks | May 2026 |
| Phase 5: Testing & QA | 3 weeks | Jun 2026 |
| Phase 6: Release | 2 weeks | Jun 2026 |
| Phase 7: Enhancements | Ongoing | Q3+ 2026 |

---

## 12. Approval

| Role | Name | Date | Signature |
|------|------|------|-----------|
| Product Owner | | | |
| Tech Lead | | | |
| Security Lead | | | |
| QA Lead | | | |

---

## Document History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | Feb 7, 2026 | laTrigger Team | Initial draft |
