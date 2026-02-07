# Monitoring & Analytics Document
## laTrigger — iOS Jenkins Build Trigger App

| Document Info | |
|---------------|---|
| **Version** | 1.0 |
| **Date** | February 7, 2026 |
| **Author** | laTrigger Team |
| **Status** | Draft |

---

## 1. Overview

### 1.1 Purpose

This document defines the monitoring, analytics, and observability strategy for the laTrigger iOS application. It ensures we can:

- Track app health and stability
- Understand user behavior
- Measure feature success
- Detect and resolve issues quickly

### 1.2 Principles

| Principle | Description |
|-----------|-------------|
| **Privacy First** | Minimal data collection, user consent |
| **Actionable Metrics** | Only track what drives decisions |
| **Real-Time Alerts** | Fast issue detection and response |
| **Performance Focus** | Monitor user-impacting metrics |

---

## 2. Monitoring Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                   MONITORING ARCHITECTURE                        │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │                    iOS Application                        │   │
│  │  ┌─────────┐  ┌─────────┐  ┌─────────┐  ┌─────────┐      │   │
│  │  │Analytics│  │ Crash   │  │ Perf    │  │ Custom  │      │   │
│  │  │ Events  │  │ Reports │  │ Traces  │  │ Logs    │      │   │
│  │  └────┬────┘  └────┬────┘  └────┬────┘  └────┬────┘      │   │
│  └───────┼────────────┼───────────┼────────────┼────────────┘   │
│          │            │           │            │                 │
│          ▼            ▼           ▼            ▼                 │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │                    Firebase SDK                           │   │
│  │  ┌─────────┐  ┌─────────┐  ┌─────────┐                   │   │
│  │  │Analytics│  │Crashly- │  │ Perfor- │                   │   │
│  │  │         │  │  tics   │  │ mance   │                   │   │
│  │  └────┬────┘  └────┬────┘  └────┬────┘                   │   │
│  └───────┼────────────┼───────────┼─────────────────────────┘   │
│          │            │           │                              │
│          ▼            ▼           ▼                              │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │                  Firebase Console                         │   │
│  │  ┌─────────┐  ┌─────────┐  ┌─────────┐  ┌─────────┐      │   │
│  │  │Dashboard│  │ Alerts  │  │ Reports │  │ Export  │      │   │
│  │  └─────────┘  └─────────┘  └─────────┘  └─────────┘      │   │
│  └──────────────────────────────────────────────────────────┘   │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

---

## 3. Crash Reporting

### 3.1 Tool: Firebase Crashlytics

| Feature | Configuration |
|---------|---------------|
| Automatic crash reporting | Enabled |
| Non-fatal error logging | Enabled |
| Breadcrumbs | Enabled |
| User identification | Disabled (privacy) |
| Beta distribution | Via TestFlight |

### 3.2 Crash Metrics

| Metric | Target | Alert Threshold |
|--------|--------|-----------------|
| Crash-free users | > 99.5% | < 99.0% |
| Crash-free sessions | > 99.8% | < 99.5% |
| Time to resolution | < 24 hours | > 48 hours |

### 3.3 Crashlytics Implementation

```swift
import FirebaseCrashlytics

class CrashReporter {
    
    static func configure() {
        // Enable collection (consider user opt-in)
        Crashlytics.crashlytics().setCrashlyticsCollectionEnabled(true)
    }
    
    static func logError(_ error: Error, context: [String: Any] = [:]) {
        let crashlytics = Crashlytics.crashlytics()
        
        // Add breadcrumb
        crashlytics.log("Error: \(error.localizedDescription)")
        
        // Add custom keys (sanitized)
        for (key, value) in context {
            crashlytics.setCustomValue(value, forKey: key)
        }
        
        // Record non-fatal error
        crashlytics.record(error: error)
    }
    
    static func logBreadcrumb(_ message: String) {
        Crashlytics.crashlytics().log(message)
    }
    
    static func setServerContext(serverId: String) {
        // Use hashed ID for privacy
        let hashedId = serverId.sha256Hash
        Crashlytics.crashlytics().setCustomValue(hashedId, forKey: "server_id_hash")
    }
}
```

### 3.4 Error Categories

| Category | Examples | Priority |
|----------|----------|----------|
| Critical | App crash, data loss | P0 - Immediate |
| High | API failures, auth errors | P1 - Same day |
| Medium | UI glitches, timeouts | P2 - This week |
| Low | Minor warnings | P3 - Backlog |

---

## 4. Analytics Events

### 4.1 Event Taxonomy

```
Event Naming Convention:
{category}_{action}_{target}

Examples:
- server_add_success
- job_trigger_started
- build_status_viewed
```

### 4.2 Core Events

#### Authentication Events

| Event | Parameters | Trigger |
|-------|------------|---------|
| `server_add_started` | - | User opens add server form |
| `server_add_success` | `server_count` | Server successfully added |
| `server_add_failed` | `error_code` | Server connection failed |
| `server_switch` | `server_count` | User switches active server |
| `server_delete` | - | Server configuration deleted |

#### Job Events

| Event | Parameters | Trigger |
|-------|------------|---------|
| `job_list_viewed` | `job_count` | Job list screen opened |
| `job_list_refreshed` | - | Pull to refresh |
| `job_search_used` | `query_length` | Search filter applied |
| `job_detail_viewed` | `has_parameters` | Job detail opened |
| `job_favorite_added` | - | Job marked as favorite |
| `job_favorite_removed` | - | Job unfavorited |

#### Build Events

| Event | Parameters | Trigger |
|-------|------------|---------|
| `build_trigger_started` | `has_parameters` | Build button tapped |
| `build_trigger_confirmed` | `param_count` | Confirmation accepted |
| `build_trigger_success` | `response_time_ms` | Build queued successfully |
| `build_trigger_failed` | `error_code` | Trigger failed |
| `build_trigger_cancelled` | - | User cancelled confirmation |
| `build_status_viewed` | `build_status` | Build status screen opened |
| `build_log_viewed` | `log_lines` | Build logs opened |
| `build_cancelled` | - | User cancelled running build |

#### App Events

| Event | Parameters | Trigger |
|-------|------------|---------|
| `app_opened` | `launch_type` | App launched |
| `app_backgrounded` | `session_duration` | App went to background |
| `settings_opened` | - | Settings screen opened |
| `theme_changed` | `theme` | Appearance changed |
| `biometric_enabled` | - | App lock enabled |
| `notification_permission` | `granted` | Permission response |

### 4.3 Analytics Implementation

```swift
import FirebaseAnalytics

enum AnalyticsEvent {
    case serverAddSuccess(serverCount: Int)
    case buildTriggerSuccess(responseTime: Int)
    case buildTriggerFailed(errorCode: String)
    case jobListViewed(jobCount: Int)
    
    var name: String {
        switch self {
        case .serverAddSuccess: return "server_add_success"
        case .buildTriggerSuccess: return "build_trigger_success"
        case .buildTriggerFailed: return "build_trigger_failed"
        case .jobListViewed: return "job_list_viewed"
        }
    }
    
    var parameters: [String: Any] {
        switch self {
        case .serverAddSuccess(let count):
            return ["server_count": count]
        case .buildTriggerSuccess(let responseTime):
            return ["response_time_ms": responseTime]
        case .buildTriggerFailed(let code):
            return ["error_code": code]
        case .jobListViewed(let count):
            return ["job_count": count]
        }
    }
}

class Analytics {
    
    static func log(_ event: AnalyticsEvent) {
        #if !DEBUG
        FirebaseAnalytics.Analytics.logEvent(event.name, parameters: event.parameters)
        #endif
        
        // Debug logging
        print("📊 Analytics: \(event.name) - \(event.parameters)")
    }
    
    static func setUserProperty(_ value: String?, forName name: String) {
        FirebaseAnalytics.Analytics.setUserProperty(value, forName: name)
    }
}

// Usage
Analytics.log(.buildTriggerSuccess(responseTime: 450))
```

### 4.4 User Properties

| Property | Type | Description |
|----------|------|-------------|
| `server_count` | Int | Number of configured servers |
| `app_version` | String | Current app version |
| `theme_preference` | String | light/dark/system |
| `biometric_enabled` | Bool | App lock enabled |
| `notification_enabled` | Bool | Push notifications on |

---

## 5. Performance Monitoring

### 5.1 Tool: Firebase Performance

| Feature | Configuration |
|---------|---------------|
| Automatic traces | Enabled |
| Network monitoring | Enabled |
| Custom traces | Enabled |
| Screen traces | Enabled |

### 5.2 Key Performance Metrics

| Metric | Target | Alert |
|--------|--------|-------|
| App start time (cold) | < 1.5s | > 2.5s |
| App start time (warm) | < 0.5s | > 1.0s |
| API response time | < 1.0s | > 3.0s |
| Frame render time | < 16ms | > 33ms |
| Memory usage | < 100MB | > 200MB |

### 5.3 Custom Traces

```swift
import FirebasePerformance

class PerformanceTracer {
    
    // API call tracing
    static func traceAPICall<T>(
        endpoint: String,
        execute: () async throws -> T
    ) async throws -> T {
        let trace = Performance.startTrace(name: "api_\(endpoint)")
        trace?.setValue(endpoint, forAttribute: "endpoint")
        
        let startTime = CFAbsoluteTimeGetCurrent()
        
        do {
            let result = try await execute()
            let duration = (CFAbsoluteTimeGetCurrent() - startTime) * 1000
            
            trace?.setValue(Int64(duration), forMetric: "duration_ms")
            trace?.setValue("success", forAttribute: "status")
            trace?.stop()
            
            return result
        } catch {
            trace?.setValue("failure", forAttribute: "status")
            trace?.setValue(error.localizedDescription, forAttribute: "error")
            trace?.stop()
            throw error
        }
    }
    
    // Build trigger trace
    static func traceBuildTrigger() -> Trace? {
        let trace = Performance.startTrace(name: "build_trigger")
        return trace
    }
    
    // Screen load trace
    static func traceScreenLoad(_ screenName: String) -> Trace? {
        let trace = Performance.startTrace(name: "screen_\(screenName)")
        return trace
    }
}

// Usage
let jobs = try await PerformanceTracer.traceAPICall(endpoint: "jobs") {
    try await apiClient.fetchJobs()
}
```

### 5.4 Network Monitoring

Automatically tracked:
- Request URL (domain only for privacy)
- Response time
- Response size
- Success/failure rate
- HTTP status codes

### 5.5 Performance Dashboard

| Panel | Metrics | Grouping |
|-------|---------|----------|
| App Start | Cold/warm start times | By version |
| Network | Response times, success rate | By endpoint |
| Screen Render | Frame times, slow renders | By screen |
| Custom Traces | Build trigger, API calls | By trace |

---

## 6. Key Performance Indicators (KPIs)

### 6.1 Engagement KPIs

| KPI | Definition | Target |
|-----|------------|--------|
| DAU | Daily Active Users | Growth |
| WAU | Weekly Active Users | Growth |
| MAU | Monthly Active Users | Growth |
| DAU/MAU Ratio | Stickiness | > 20% |
| Session Duration | Avg time in app | > 2 min |
| Sessions/User/Day | Engagement | > 1.5 |

### 6.2 Feature KPIs

| KPI | Definition | Target |
|-----|------------|--------|
| Build Trigger Rate | Triggers per user per day | > 3 |
| Build Success Rate | Successful triggers / total | > 95% |
| Job Search Usage | % users using search | > 40% |
| Favorites Adoption | % users with favorites | > 30% |
| Multi-Server Usage | % users with 2+ servers | > 20% |

### 6.3 Quality KPIs

| KPI | Definition | Target |
|-----|------------|--------|
| Crash-Free Rate | % sessions without crash | > 99.5% |
| ANR Rate | App Not Responding | < 0.1% |
| API Error Rate | Failed API calls | < 2% |
| App Rating | App Store rating | ≥ 4.5 |
| NPS | Net Promoter Score | > 50 |

### 6.4 Business KPIs

| KPI | Definition | Target |
|-----|------------|--------|
| Downloads | Total installs | 1,000/month |
| Retention D1 | % users returning day 1 | > 60% |
| Retention D7 | % users returning day 7 | > 40% |
| Retention D30 | % users returning day 30 | > 25% |
| Churn Rate | Monthly user loss | < 5% |

---

## 7. Dashboards

### 7.1 Executive Dashboard

```
┌─────────────────────────────────────────────────────────────────┐
│                    laTrigger - Executive Dashboard               │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ┌───────────────┐  ┌───────────────┐  ┌───────────────┐        │
│  │   MAU: 1,234  │  │ Crash-Free:   │  │  App Rating:  │        │
│  │    ▲ +15%     │  │   99.7%       │  │    4.6 ⭐     │        │
│  └───────────────┘  └───────────────┘  └───────────────┘        │
│                                                                  │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │  Daily Active Users (Last 30 Days)                      │    │
│  │  📈 [Line chart showing DAU trend]                      │    │
│  └─────────────────────────────────────────────────────────┘    │
│                                                                  │
│  ┌──────────────────────┐  ┌──────────────────────┐             │
│  │ Retention Cohort     │  │ Top Features         │             │
│  │ D1: 65%  D7: 42%     │  │ 1. Build Trigger     │             │
│  │ D14: 35% D30: 28%    │  │ 2. Job List          │             │
│  └──────────────────────┘  │ 3. Build Status      │             │
│                            └──────────────────────┘             │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### 7.2 Engineering Dashboard

```
┌─────────────────────────────────────────────────────────────────┐
│                    laTrigger - Engineering Dashboard             │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  STABILITY                         PERFORMANCE                   │
│  ┌───────────────────┐             ┌───────────────────┐        │
│  │ Crash-free: 99.7% │             │ API p50: 340ms    │        │
│  │ ANR: 0.02%        │             │ API p95: 1.2s     │        │
│  │ Errors: 124       │             │ Cold start: 1.4s  │        │
│  └───────────────────┘             └───────────────────┘        │
│                                                                  │
│  TOP CRASHES                       API HEALTH                    │
│  ┌───────────────────┐             ┌───────────────────┐        │
│  │ 1. JobListVM (23) │             │ /api/json: 99.2%  │        │
│  │ 2. APIClient (12) │             │ /build: 98.5%     │        │
│  │ 3. Keychain (5)   │             │ /consoleText: 97% │        │
│  └───────────────────┘             └───────────────────┘        │
│                                                                  │
│  ERROR TIMELINE                                                  │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │  [Timeline of errors over last 24 hours]                │    │
│  └─────────────────────────────────────────────────────────┘    │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

---

## 8. Alerting

### 8.1 Alert Configuration

| Alert | Condition | Channel | Severity |
|-------|-----------|---------|----------|
| Crash spike | >1% in 1 hour | Slack, PagerDuty | Critical |
| API errors | >5% in 15 min | Slack | High |
| App rating drop | <4.0 average | Email | Medium |
| Performance degradation | p95 > 3s | Slack | Medium |

### 8.2 Alert Escalation

```
Level 1 (0-15 min): Slack notification to on-call
Level 2 (15-30 min): PagerDuty alert to on-call
Level 3 (30-60 min): Escalate to engineering lead
Level 4 (60+ min): Escalate to CTO
```

### 8.3 On-Call Runbook

| Issue | Detection | Response |
|-------|-----------|----------|
| Crash spike | Crashlytics alert | Analyze, hotfix if needed |
| API failures | Performance alert | Check Jenkins connectivity |
| High error rate | Error rate alert | Review error logs |
| App not responding | ANR alert | Profile and optimize |

---

## 9. Privacy & Compliance

### 9.1 Data Collection Policy

| Data Type | Collected | Purpose | Retention |
|-----------|-----------|---------|-----------|
| Crash reports | Yes | Stability | 90 days |
| Analytics events | Yes (opt-in) | Usage insights | 14 months |
| Performance traces | Yes | Optimization | 90 days |
| Personal data | No | N/A | N/A |
| Server URLs | No | N/A | N/A |
| Credentials | No | N/A | N/A |

### 9.2 User Consent

```swift
class AnalyticsConsent {
    
    @AppStorage("analytics_opted_in") 
    private var analyticsOptedIn: Bool = false
    
    func requestConsent() {
        // Show consent dialog on first launch
    }
    
    func enableAnalytics() {
        analyticsOptedIn = true
        FirebaseAnalytics.Analytics.setAnalyticsCollectionEnabled(true)
        Crashlytics.crashlytics().setCrashlyticsCollectionEnabled(true)
    }
    
    func disableAnalytics() {
        analyticsOptedIn = false
        FirebaseAnalytics.Analytics.setAnalyticsCollectionEnabled(false)
        // Note: Crash reporting may still be needed for app health
    }
}
```

### 9.3 GDPR Compliance

- Data collection disclosure in privacy policy
- User opt-in for analytics
- Data deletion request handling
- No PII in analytics events
- Anonymized identifiers only

---

## 10. Reporting

### 10.1 Report Schedule

| Report | Frequency | Audience | Content |
|--------|-----------|----------|---------|
| Daily Health | Daily | Engineering | Crashes, errors |
| Weekly Metrics | Weekly | Team | KPIs, trends |
| Monthly Review | Monthly | Stakeholders | Full analysis |
| Release Report | Per release | Team | Version comparison |

### 10.2 Report Template

```markdown
# laTrigger Weekly Report - Week of [Date]

## Summary
- **Active Users**: X,XXX (▲/▼ X%)
- **Crash-Free Rate**: XX.X% (▲/▼ X%)
- **Build Triggers**: X,XXX (▲/▼ X%)

## Key Metrics
| Metric | This Week | Last Week | Change |
|--------|-----------|-----------|--------|
| DAU | 450 | 420 | +7% |
| Sessions | 2,100 | 1,900 | +10% |
| Crash-free | 99.7% | 99.5% | +0.2% |

## Issues
- [List of significant issues this week]

## Actions
- [Actions taken or planned]

## Next Week Focus
- [Priorities for next week]
```

---

## 11. Tools Summary

| Category | Tool | Purpose |
|----------|------|---------|
| Crash Reporting | Firebase Crashlytics | Crash analysis |
| Analytics | Firebase Analytics | Usage tracking |
| Performance | Firebase Performance | Performance monitoring |
| Dashboard | Firebase Console | Centralized view |
| Alerting | Slack + PagerDuty | Incident response |
| Logs | Console.app / Xcode | Development debugging |

---

## 12. Approval

| Role | Name | Date | Signature |
|------|------|------|-----------|
| Engineering Lead | | | |
| Product Manager | | | |
| Privacy Officer | | | |

---

## Document History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | Feb 7, 2026 | laTrigger Team | Initial monitoring plan |
