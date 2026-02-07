# Test Plan Document
## laTrigger — iOS Jenkins Build Trigger App

| Document Info | |
|---------------|---|
| **Version** | 1.0 |
| **Date** | February 7, 2026 |
| **Author** | laTrigger QA Team |
| **Status** | Draft |

---

## 1. Introduction

### 1.1 Purpose

This document describes the test strategy, test cases, and quality assurance processes for the laTrigger iOS application. It ensures comprehensive coverage of functional, non-functional, and security requirements.

### 1.2 Scope

| In Scope | Out of Scope |
|----------|--------------|
| iOS application testing | Jenkins server testing |
| API integration testing | Backend proxy (future) |
| UI/UX testing | Third-party integrations |
| Security testing | Load testing Jenkins |
| Performance testing | |

### 1.3 References

- Product Requirements Document (PRD)
- User Stories Document
- Technical Architecture Document
- Security Design Document

---

## 2. Test Strategy

### 2.1 Testing Levels

```
┌─────────────────────────────────────────────────────────────────┐
│                      TESTING PYRAMID                             │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│                         ┌─────────┐                              │
│                        /  Manual   \                             │
│                       /   Testing   \                            │
│                      ┌───────────────┐                           │
│                     /   E2E / UI      \                          │
│                    /    Tests          \                         │
│                   ┌─────────────────────┐                        │
│                  /   Integration Tests   \                       │
│                 /    (API, Keychain)      \                      │
│                ┌───────────────────────────┐                     │
│               /       Unit Tests            \                    │
│              /   (ViewModels, Services)      \                   │
│             └─────────────────────────────────┘                  │
│                                                                  │
│  Unit Tests: 70%  |  Integration: 20%  |  E2E: 10%              │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### 2.2 Test Types

| Test Type | Purpose | Tools | Frequency |
|-----------|---------|-------|-----------|
| Unit Tests | Test isolated components | XCTest | Every commit |
| Integration Tests | Test component interactions | XCTest | Every PR |
| UI Tests | Test user workflows | XCUITest | Daily |
| Snapshot Tests | Test UI consistency | Swift Snapshot Testing | Every PR |
| API Tests | Test Jenkins API integration | XCTest + Mock Server | Every PR |
| Security Tests | Test security controls | Manual + Tools | Pre-release |
| Performance Tests | Test app responsiveness | Instruments | Weekly |
| Accessibility Tests | Test a11y compliance | Accessibility Inspector | Every sprint |

### 2.3 Test Environment

| Environment | Purpose | Jenkins Server |
|-------------|---------|----------------|
| Development | Developer testing | Local/Mock |
| CI/CD | Automated testing | Mock Server |
| Staging | Integration testing | Staging Jenkins |
| Production | Smoke testing | Isolated test server |

---

## 3. Test Coverage Goals

### 3.1 Code Coverage Targets

| Component | Minimum Coverage | Target Coverage |
|-----------|------------------|-----------------|
| ViewModels | 80% | 90% |
| Services | 85% | 95% |
| Repositories | 80% | 90% |
| Utilities | 90% | 95% |
| UI Views | 60% | 70% |
| **Overall** | **75%** | **85%** |

### 3.2 Feature Coverage

| Feature | Unit | Integration | UI | Priority |
|---------|------|-------------|-----|----------|
| Authentication | ✓ | ✓ | ✓ | P0 |
| Server Management | ✓ | ✓ | ✓ | P1 |
| Job Listing | ✓ | ✓ | ✓ | P0 |
| Job Search | ✓ | - | ✓ | P0 |
| Build Trigger | ✓ | ✓ | ✓ | P0 |
| Build Parameters | ✓ | ✓ | ✓ | P0 |
| Build Status | ✓ | ✓ | ✓ | P0 |
| Build Logs | ✓ | ✓ | ✓ | P1 |
| Notifications | ✓ | ✓ | ✓ | P1 |
| Settings | ✓ | - | ✓ | P2 |

---

## 4. Unit Test Cases

### 4.1 Authentication Tests

#### TC-AUTH-001: Valid Server Connection
```
Feature: Server Authentication
Scenario: Connect with valid credentials

Given a valid Jenkins server URL
And valid username and API token
When the user attempts to connect
Then the connection should succeed
And server configuration should be saved
And token should be stored in Keychain
```

| Test ID | Description | Input | Expected Output |
|---------|-------------|-------|-----------------|
| TC-AUTH-001 | Valid connection | Valid URL, user, token | Success, saved |
| TC-AUTH-002 | Invalid URL format | "not-a-url" | Validation error |
| TC-AUTH-003 | HTTP URL rejected | "http://jenkins.com" | HTTPS required error |
| TC-AUTH-004 | Invalid credentials | Wrong token | 401 Unauthorized |
| TC-AUTH-005 | Server unreachable | Non-existent URL | Connection timeout |
| TC-AUTH-006 | Empty fields | Empty URL/user/token | Validation error |

### 4.2 Job Management Tests

| Test ID | Description | Input | Expected Output |
|---------|-------------|-------|-----------------|
| TC-JOB-001 | Fetch job list | Valid server | List of jobs returned |
| TC-JOB-002 | Empty job list | Server with no jobs | Empty state displayed |
| TC-JOB-003 | Search jobs | Search query "deploy" | Filtered job list |
| TC-JOB-004 | Search no results | Search query "xyz123" | No results message |
| TC-JOB-005 | Job details fetch | Job name | Job with parameters |
| TC-JOB-006 | Nested folder jobs | Folder structure | Properly parsed |

### 4.3 Build Trigger Tests

| Test ID | Description | Input | Expected Output |
|---------|-------------|-------|-----------------|
| TC-BUILD-001 | Trigger simple job | Job without params | Build queued |
| TC-BUILD-002 | Trigger with params | Job + parameters | Build queued with params |
| TC-BUILD-003 | Missing required param | Empty required field | Validation error |
| TC-BUILD-004 | Invalid param value | Invalid choice | Validation error |
| TC-BUILD-005 | Trigger permission denied | No build permission | 403 error handled |
| TC-BUILD-006 | Server error on trigger | 500 response | Error message shown |

### 4.4 Build Status Tests

| Test ID | Description | Input | Expected Output |
|---------|-------------|-------|-----------------|
| TC-STATUS-001 | Parse success status | color: "blue" | Status.success |
| TC-STATUS-002 | Parse failure status | color: "red" | Status.failure |
| TC-STATUS-003 | Parse building status | color: "blue_anime" | Status.building |
| TC-STATUS-004 | Parse unstable status | color: "yellow" | Status.unstable |
| TC-STATUS-005 | Calculate progress | timestamp, duration | Percentage 0-100 |
| TC-STATUS-006 | Fetch console log | Build number | Console text |

### 4.5 ViewModel Tests

```swift
// Example ViewModel Test
class JobListViewModelTests: XCTestCase {
    
    var sut: JobListViewModel!
    var mockAPIClient: MockJenkinsAPIClient!
    
    override func setUp() {
        super.setUp()
        mockAPIClient = MockJenkinsAPIClient()
        sut = JobListViewModel(apiClient: mockAPIClient)
    }
    
    func testFetchJobs_Success() async {
        // Given
        let expectedJobs = [
            JenkinsJob(name: "build-app", url: "...", color: "blue"),
            JenkinsJob(name: "deploy-prod", url: "...", color: "red")
        ]
        mockAPIClient.jobsToReturn = expectedJobs
        
        // When
        await sut.fetchJobs()
        
        // Then
        XCTAssertEqual(sut.jobs.count, 2)
        XCTAssertFalse(sut.isLoading)
        XCTAssertNil(sut.error)
    }
    
    func testFetchJobs_NetworkError() async {
        // Given
        mockAPIClient.errorToThrow = LaTriggerError.networkUnavailable
        
        // When
        await sut.fetchJobs()
        
        // Then
        XCTAssertTrue(sut.jobs.isEmpty)
        XCTAssertNotNil(sut.error)
    }
    
    func testSearchJobs_FiltersCorrectly() {
        // Given
        sut.jobs = [
            JenkinsJob(name: "build-ios", ...),
            JenkinsJob(name: "build-android", ...),
            JenkinsJob(name: "deploy-prod", ...)
        ]
        
        // When
        sut.searchQuery = "build"
        
        // Then
        XCTAssertEqual(sut.filteredJobs.count, 2)
    }
}
```

---

## 5. Integration Test Cases

### 5.1 API Integration Tests

| Test ID | Description | Setup | Validation |
|---------|-------------|-------|------------|
| TC-API-001 | Full auth flow | Mock server | Token stored in Keychain |
| TC-API-002 | Job list with pagination | 100+ mock jobs | All jobs loaded |
| TC-API-003 | Build trigger end-to-end | Mock job | Queue ID returned |
| TC-API-004 | Build status polling | Running build | Status updates |
| TC-API-005 | Network retry logic | Flaky connection | Retries succeed |
| TC-API-006 | Timeout handling | Slow response | Timeout error |

### 5.2 Keychain Integration Tests

| Test ID | Description | Validation |
|---------|-------------|------------|
| TC-KEY-001 | Save token | Token retrievable |
| TC-KEY-002 | Update token | New token returned |
| TC-KEY-003 | Delete token | Token not found |
| TC-KEY-004 | Multiple servers | Correct token per server |
| TC-KEY-005 | Biometric access | Requires auth |

### 5.3 CoreData Integration Tests

| Test ID | Description | Validation |
|---------|-------------|------------|
| TC-CD-001 | Save server config | Config persisted |
| TC-CD-002 | Update server config | Changes saved |
| TC-CD-003 | Delete server config | Config removed |
| TC-CD-004 | Migrate schema | Data preserved |
| TC-CD-005 | Concurrent access | No crashes |

---

## 6. UI Test Cases

### 6.1 Onboarding Flow

```swift
// XCUITest Example
class OnboardingUITests: XCTestCase {
    
    let app = XCUIApplication()
    
    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app.launchArguments = ["--uitesting", "--reset-state"]
        app.launch()
    }
    
    func testOnboarding_AddFirstServer() {
        // Verify onboarding screen appears
        XCTAssertTrue(app.staticTexts["Welcome to laTrigger"].exists)
        
        // Tap "Add Server" button
        app.buttons["Add Server"].tap()
        
        // Fill in server details
        app.textFields["Server URL"].tap()
        app.textFields["Server URL"].typeText("https://jenkins.example.com")
        
        app.textFields["Username"].tap()
        app.textFields["Username"].typeText("testuser")
        
        app.secureTextFields["API Token"].tap()
        app.secureTextFields["API Token"].typeText("abc123token")
        
        // Submit
        app.buttons["Connect"].tap()
        
        // Verify success (job list appears)
        XCTAssertTrue(app.navigationBars["Jobs"].waitForExistence(timeout: 5))
    }
}
```

### 6.2 UI Test Scenarios

| Test ID | Screen | Scenario | Steps | Expected |
|---------|--------|----------|-------|----------|
| TC-UI-001 | Onboarding | First launch | Open app fresh | Onboarding shown |
| TC-UI-002 | Server Setup | Add server | Fill form, submit | Server saved |
| TC-UI-003 | Server Setup | Invalid URL | Enter bad URL | Error shown |
| TC-UI-004 | Job List | View jobs | Navigate to jobs | Jobs displayed |
| TC-UI-005 | Job List | Pull to refresh | Pull down | Jobs refreshed |
| TC-UI-006 | Job List | Search jobs | Type in search | List filtered |
| TC-UI-007 | Job Detail | View details | Tap job | Details shown |
| TC-UI-008 | Trigger | Simple trigger | Tap Build button | Confirmation shown |
| TC-UI-009 | Trigger | With params | Fill params, submit | Build triggered |
| TC-UI-010 | Build Status | View status | Navigate to build | Status displayed |
| TC-UI-011 | Build Status | View logs | Tap "View Logs" | Logs shown |
| TC-UI-012 | Settings | Change theme | Toggle dark mode | Theme changes |
| TC-UI-013 | Settings | App lock | Enable Face ID | Biometric prompt |

### 6.3 Accessibility Tests

| Test ID | Screen | Validation |
|---------|--------|------------|
| TC-A11Y-001 | All screens | VoiceOver navigation |
| TC-A11Y-002 | All screens | Dynamic Type (XXL) |
| TC-A11Y-003 | Buttons | Minimum 44x44pt |
| TC-A11Y-004 | Colors | Contrast ratio ≥ 4.5:1 |
| TC-A11Y-005 | Forms | Labels associated |
| TC-A11Y-006 | Status | Non-color indicators |

---

## 7. Security Test Cases

### 7.1 Authentication Security

| Test ID | Description | Method | Expected |
|---------|-------------|--------|----------|
| TC-SEC-001 | Token not in logs | Review logs | No token visible |
| TC-SEC-002 | Token not in memory dump | Memory analysis | Token encrypted |
| TC-SEC-003 | Keychain protection | Device lock test | Access denied |
| TC-SEC-004 | Biometric bypass | Attack simulation | Cannot bypass |

### 7.2 Network Security

| Test ID | Description | Method | Expected |
|---------|-------------|--------|----------|
| TC-SEC-005 | HTTPS enforced | Proxy test | HTTP rejected |
| TC-SEC-006 | Cert pinning | MITM test | Connection fails |
| TC-SEC-007 | Invalid cert | Self-signed cert | Connection fails |
| TC-SEC-008 | TLS version | Protocol test | TLS 1.2+ only |

### 7.3 Data Security

| Test ID | Description | Method | Expected |
|---------|-------------|--------|----------|
| TC-SEC-009 | Backup exclusion | iTunes backup | Token not in backup |
| TC-SEC-010 | Screenshot protection | Screenshot | Sensitive data hidden |
| TC-SEC-011 | Clipboard safety | Copy token | Not possible |
| TC-SEC-012 | Debug disabled | Release build | Debugger rejected |

---

## 8. Performance Test Cases

### 8.1 Performance Benchmarks

| Metric | Target | Maximum |
|--------|--------|---------|
| App launch (cold) | < 1.5s | 2.0s |
| App launch (warm) | < 0.5s | 1.0s |
| Job list load | < 1.0s | 2.0s |
| Build trigger response | < 0.5s | 1.0s |
| Memory usage (idle) | < 50MB | 100MB |
| Memory usage (active) | < 80MB | 150MB |
| Battery drain (1hr use) | < 5% | 10% |

### 8.2 Performance Test Cases

| Test ID | Description | Measurement | Tool |
|---------|-------------|-------------|------|
| TC-PERF-001 | Cold start time | Time to interactive | Instruments |
| TC-PERF-002 | Job list scroll | Frame rate | Instruments |
| TC-PERF-003 | Memory footprint | Memory usage | Instruments |
| TC-PERF-004 | Network efficiency | Request count | Charles |
| TC-PERF-005 | Battery impact | Power usage | Instruments |
| TC-PERF-006 | Large job list (1000+) | Scroll performance | Instruments |

---

## 9. Regression Test Suite

### 9.1 Smoke Tests (Critical Path)

Run before every release:

| ID | Test Case | Priority |
|----|-----------|----------|
| SMOKE-01 | App launches successfully | P0 |
| SMOKE-02 | Add new server | P0 |
| SMOKE-03 | View job list | P0 |
| SMOKE-04 | Trigger a build | P0 |
| SMOKE-05 | View build status | P0 |
| SMOKE-06 | View build logs | P1 |

### 9.2 Full Regression

Run weekly and before major releases:

- All smoke tests
- All unit tests (automated)
- All integration tests (automated)
- All UI tests (automated)
- Manual exploratory testing
- Accessibility audit
- Security spot checks

---

## 10. Test Data Management

### 10.1 Mock Jenkins Server

```yaml
# Mock server configuration
endpoints:
  - path: /api/json
    method: GET
    response:
      jobs:
        - name: "build-ios"
          color: "blue"
        - name: "build-android"
          color: "red"
        - name: "deploy-prod"
          color: "blue_anime"
          
  - path: /job/{name}/build
    method: POST
    response:
      status: 201
      headers:
        Location: "/queue/item/123/"
```

### 10.2 Test Fixtures

```swift
// Test fixtures
enum TestFixtures {
    
    static let validServer = ServerConfiguration(
        id: UUID(),
        name: "Test Server",
        url: URL(string: "https://jenkins.test.com")!,
        username: "testuser",
        isDefault: true,
        createdAt: Date()
    )
    
    static let sampleJobs: [JenkinsJob] = [
        JenkinsJob(name: "build-ios", url: "...", color: "blue", buildable: true),
        JenkinsJob(name: "build-android", url: "...", color: "red", buildable: true),
        JenkinsJob(name: "deploy-staging", url: "...", color: "yellow", buildable: true)
    ]
    
    static let sampleBuild = Build(
        number: 42,
        url: "...",
        result: "SUCCESS",
        building: false,
        timestamp: Date().timeIntervalSince1970 * 1000,
        duration: 120000,
        estimatedDuration: 150000,
        displayName: "#42"
    )
}
```

---

## 11. Bug Tracking

### 11.1 Bug Severity Levels

| Severity | Definition | SLA |
|----------|------------|-----|
| S1 - Critical | App crash, data loss, security flaw | 24 hours |
| S2 - High | Major feature broken, no workaround | 3 days |
| S3 - Medium | Feature impaired, workaround exists | 1 week |
| S4 - Low | Minor issue, cosmetic | Next release |

### 11.2 Bug Report Template

```markdown
## Bug Report

**Title:** [Brief description]

**Severity:** S1/S2/S3/S4

**Environment:**
- iOS Version: 
- Device: 
- App Version: 
- Jenkins Version: 

**Steps to Reproduce:**
1. 
2. 
3. 

**Expected Result:**


**Actual Result:**


**Screenshots/Logs:**


**Additional Context:**

```

---

## 12. Test Automation

### 12.1 CI/CD Pipeline

```yaml
# GitHub Actions workflow
name: iOS Tests

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

jobs:
  test:
    runs-on: macos-latest
    
    steps:
      - uses: actions/checkout@v3
      
      - name: Select Xcode
        run: sudo xcode-select -s /Applications/Xcode_15.app
        
      - name: Build
        run: xcodebuild build -scheme laTrigger -destination 'platform=iOS Simulator,name=iPhone 15'
        
      - name: Unit Tests
        run: xcodebuild test -scheme laTrigger -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing:laTriggerTests
        
      - name: UI Tests
        run: xcodebuild test -scheme laTrigger -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing:laTriggerUITests
        
      - name: Code Coverage
        run: xcov --scheme laTrigger --minimum_coverage_percentage 75
```

### 12.2 Test Reports

| Report | Format | Frequency |
|--------|--------|-----------|
| Unit test results | JUnit XML | Every build |
| Code coverage | HTML | Every build |
| UI test screenshots | PNG | On failure |
| Performance metrics | JSON | Weekly |

---

## 13. Acceptance Criteria

### 13.1 User Story Acceptance (US-05: Trigger Build)

```gherkin
Feature: Trigger Jenkins Build
  As a user
  I want to trigger a build with one tap
  So that I can start builds quickly

  Scenario: Successfully trigger a build
    Given I am viewing a job that I have permission to build
    And the job has no required parameters
    When I tap the "Build" button
    And I confirm the trigger action
    Then the build should be queued in Jenkins
    And I should see a success message
    And the job's last build should update

  Scenario: Trigger build fails
    Given I am viewing a job
    When I tap the "Build" button
    And the Jenkins server returns an error
    Then I should see an error message
    And I should have the option to retry
```

### 13.2 Definition of Done (Testing)

- [ ] All unit tests pass
- [ ] All integration tests pass
- [ ] All UI tests pass
- [ ] Code coverage ≥ 75%
- [ ] No S1 or S2 bugs
- [ ] Security tests pass
- [ ] Performance benchmarks met
- [ ] Accessibility audit pass
- [ ] Manual QA sign-off

---

## 14. Test Schedule

| Phase | Duration | Activities |
|-------|----------|------------|
| Sprint Testing | 2 weeks | Unit, integration tests for sprint features |
| Integration Testing | 1 week | Full integration suite, API testing |
| System Testing | 1 week | E2E flows, regression suite |
| UAT | 1 week | User acceptance, beta testing |
| Release Testing | 3 days | Smoke tests, final validation |

---

## 15. Approval

| Role | Name | Date | Signature |
|------|------|------|-----------|
| QA Lead | | | |
| Dev Lead | | | |
| Product Owner | | | |

---

## Document History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | Feb 7, 2026 | QA Team | Initial test plan |
