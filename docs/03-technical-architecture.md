# Technical Architecture Document
## JobTrigger — iOS Jenkins Build Trigger App

| Document Info | |
|---------------|---|
| **Version** | 1.0 |
| **Date** | February 7, 2026 |
| **Author** | JobTrigger Team |
| **Status** | Draft |

---

## 1. Overview

This document describes the technical architecture of the JobTrigger iOS application. It covers the system architecture, component design, data flow, and technology choices.

---

## 2. System Context

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                                                                              │
│    ┌──────────────┐         HTTPS/TLS          ┌──────────────────┐         │
│    │              │◄───────────────────────────►│                  │         │
│    │   iOS App    │                             │  Backend Proxy   │         │
│    │  (JobTrigger) │                             │  (Node.js + MG)  │         │
│    │              │                             └────────┬─────────┘         │
│    └──────┬───────┘                                      │                   │
│           │                                              │ HTTPS/TLS         │
│           ▼                                              ▼                   │
│    ┌──────────────┐                             ┌──────────────────┐         │
│    │              │                             │                  │         │
│    │    APNs      │◄────────────────────────────│  Jenkins Server  │         │
│    │  (Push)      │                             │   (REST API)     │         │
│    │              │                             │                  │         │
│    └──────────────┘                             └──────────────────┘         │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

### 2.1 External Systems

| System | Description | Integration |
|--------|-------------|-------------|
| Backend Proxy | Node.js + MongoDB service | REST API over HTTPS |
| Jenkins Server | CI/CD server hosting jobs | Triggered via Backend |
| APNs | iOS push notifications | APNs SDK |

---

## 3. High-Level Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           iOS APPLICATION                                    │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  ┌───────────────────────────────────────────────────────────────────────┐  │
│  │                         PRESENTATION LAYER                             │  │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐   │  │
│  │  │   Views     │  │   Views     │  │   Views     │  │   Views     │   │  │
│  │  │  (SwiftUI)  │  │  (SwiftUI)  │  │  (SwiftUI)  │  │  (SwiftUI)  │   │  │
│  │  │             │  │             │  │             │  │             │   │  │
│  │  │ Onboarding  │  │  Job List   │  │  Build      │  │  Settings   │   │  │
│  │  │ Server Setup│  │  Job Detail │  │  Status     │  │             │   │  │
│  │  └──────┬──────┘  └──────┬──────┘  └──────┬──────┘  └──────┬──────┘   │  │
│  │         │                │                │                │          │  │
│  │         └────────────────┴────────────────┴────────────────┘          │  │
│  │                                   │                                    │  │
│  │                                   ▼                                    │  │
│  │  ┌───────────────────────────────────────────────────────────────┐    │  │
│  │  │                      VIEW MODELS                               │    │  │
│  │  │    (ObservableObject + @Published + Combine)                   │    │  │
│  │  └───────────────────────────────────────────────────────────────┘    │  │
│  └───────────────────────────────────────────────────────────────────────┘  │
│                                      │                                       │
│                                      ▼                                       │
│  ┌───────────────────────────────────────────────────────────────────────┐  │
│  │                          DOMAIN LAYER                                  │  │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐   │  │
│  │  │  Use Cases  │  │   Models    │  │ Repositories│  │  Protocols  │   │  │
│  │  │             │  │             │  │ (Interfaces)│  │             │   │  │
│  │  └─────────────┘  └─────────────┘  └─────────────┘  └─────────────┘   │  │
│  └───────────────────────────────────────────────────────────────────────┘  │
│                                      │                                       │
│                                      ▼                                       │
│  ┌───────────────────────────────────────────────────────────────────────┐  │
│  │                           DATA LAYER                                   │  │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐   │  │
│  │  │  Network    │  │  Keychain   │  │  CoreData/  │  │   Cache     │   │  │
│  │  │  Service    │  │  Service    │  │  UserDefaults│  │  Manager    │   │  │
│  │  └─────────────┘  └─────────────┘  └─────────────┘  └─────────────┘   │  │
│  └───────────────────────────────────────────────────────────────────────┘  │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 4. Architecture Pattern: MVVM + Clean Architecture

### 4.1 Layer Responsibilities

| Layer | Responsibility | Technologies |
|-------|---------------|--------------|
| **Presentation** | UI rendering, user input handling | SwiftUI, UIKit (if needed) |
| **ViewModel** | UI state management, presentation logic | Combine, ObservableObject |
| **Domain** | Business logic, use cases | Swift, Protocols |
| **Data** | Data access, external services | URLSession, Keychain, CoreData |

### 4.2 Dependency Flow

```
Presentation → ViewModel → Domain ← Data
                            ↑
                     (Dependency Inversion)
```

---

## 5. Component Architecture

### 5.1 Module Structure

```
JobTrigger/
├── App/
│   ├── JobTriggerApp.swift          # App entry point
│   ├── AppDelegate.swift           # Push notifications
│   └── SceneDelegate.swift         # Scene lifecycle
│
├── Features/
│   ├── Authentication/
│   │   ├── Views/
│   │   │   ├── ServerSetupView.swift
│   │   │   └── ServerListView.swift
│   │   ├── ViewModels/
│   │   │   └── ServerSetupViewModel.swift
│   │   └── Models/
│   │       └── ServerConfiguration.swift
│   │
│   ├── Jobs/
│   │   ├── Views/
│   │   │   ├── JobListView.swift
│   │   │   ├── JobDetailView.swift
│   │   │   └── JobRowView.swift
│   │   ├── ViewModels/
│   │   │   ├── JobListViewModel.swift
│   │   │   └── JobDetailViewModel.swift
│   │   └── Models/
│   │       └── Job.swift
│   │
│   ├── Builds/
│   │   ├── Views/
│   │   │   ├── BuildStatusView.swift
│   │   │   ├── BuildLogView.swift
│   │   │   └── TriggerView.swift
│   │   ├── ViewModels/
│   │   │   ├── BuildStatusViewModel.swift
│   │   │   └── TriggerViewModel.swift
│   │   └── Models/
│   │       ├── Build.swift
│   │       └── BuildParameter.swift
│   │
│   └── Settings/
│       ├── Views/
│       │   └── SettingsView.swift
│       └── ViewModels/
│           └── SettingsViewModel.swift
│
├── Core/
│   ├── Network/
│   │   ├── BackendClient.swift         # Base networking client
│   │   ├── APIConfig.swift             # URL/Endpoint configuration
│   │   ├── JenkinsAPIClient.swift      # Jenkins specific calls
│   │   └── NetworkError.swift          # Error definitions
│   │
│   ├── Security/
│   │   ├── KeychainHelper.swift        # JWT and token storage
│   │   ├── BiometricService.swift
│   │   └── CertificatePinner.swift
│   │
│   ├── Persistence/
│   │   ├── CredentialStorageService.swift # CRUD for backend credentials
│   │   └── CacheManager.swift
│   │
│   └── Notifications/
│       ├── NotificationManager.swift     # Global UI notifications
│       └── PushNotificationService.swift
│
├── Shared/
│   ├── Extensions/
│   ├── Utilities/
│   ├── Components/
│   │   ├── LoadingView.swift
│   │   ├── ErrorView.swift
│   │   └── StatusBadge.swift
│   └── Resources/
│       ├── Assets.xcassets
│       └── Localizable.strings
│
└── Tests/
    ├── UnitTests/
    ├── IntegrationTests/
    └── UITests/
```

---

## 6. Data Models

### 6.1 Core Models

```swift
// Server Configuration
struct ServerConfiguration: Codable, Identifiable {
    let id: String  // MongoDB ObjectId string
    var name: String
    var url: URL
    var username: String
    // API token stored separately in Keychain
    var isDefault: Bool
    var createdAt: Date
    var lastUsedAt: Date?
}

// Jenkins Job
struct JenkinsJob: Codable, Identifiable {
    let name: String
    let url: String
    let color: String          // Jenkins status color
    let buildable: Bool
    let inQueue: Bool
    let lastBuild: BuildReference?
    let healthReport: [HealthReport]?
    let property: [JobProperty]?
    
    var id: String { name }
    var status: BuildStatus { BuildStatus(color: color) }
}

// Build
struct Build: Codable, Identifiable {
    let number: Int
    let url: String
    let result: String?        // SUCCESS, FAILURE, etc.
    let building: Bool
    let timestamp: TimeInterval
    let duration: TimeInterval
    let estimatedDuration: TimeInterval
    let displayName: String?
    
    var id: Int { number }
}

// Build Parameter
struct BuildParameter: Codable, Identifiable {
    let name: String
    let type: ParameterType
    let defaultValue: String?
    let description: String?
    let choices: [String]?     // For choice parameters
    
    var id: String { name }
}

enum ParameterType: String, Codable {
    case string = "StringParameterDefinition"
    case choice = "ChoiceParameterDefinition"
    case boolean = "BooleanParameterDefinition"
    case password = "PasswordParameterDefinition"
    case text = "TextParameterDefinition"
}

enum BuildStatus: Equatable {
    case success
    case failure
    case unstable
    case building
    case aborted
    case notBuilt
    case unknown
    
    init(color: String) {
        switch color {
        case "blue", "blue_anime": self = color.contains("anime") ? .building : .success
        case "red", "red_anime": self = color.contains("anime") ? .building : .failure
        case "yellow", "yellow_anime": self = color.contains("anime") ? .building : .unstable
        case "aborted": self = .aborted
        case "notbuilt": self = .notBuilt
        default: self = .unknown
        }
    }
}
```

### 6.2 Data Flow

```
┌─────────────────┐         ┌─────────────────┐         ┌─────────────────┐
│   Jenkins API   │────────►│   API Client    │────────►│   Repository    │
│   Response      │         │   (Parsing)     │         │   (Caching)     │
└─────────────────┘         └─────────────────┘         └────────┬────────┘
                                                                  │
                                                                  ▼
                            ┌─────────────────┐         ┌─────────────────┐
                            │    ViewModel    │◄────────│   Use Case      │
                            │   (UI State)    │         │   (Business)    │
                            └────────┬────────┘         └─────────────────┘
                                     │
                                     ▼
                            ┌─────────────────┐
                            │   SwiftUI View  │
                            │   (Rendering)   │
                            └─────────────────┘
```

---

## 7. Network Layer

### 7.1 Jenkins API Integration

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/api/json` | GET | Get server info, validate connection |
| `/api/json?tree=jobs[...]` | GET | List all jobs with details |
| `/job/{name}/api/json` | GET | Get job details |
| `/job/{name}/build` | POST | Trigger build (no params) |
| `/job/{name}/buildWithParameters` | POST | Trigger build with params |
| `/job/{name}/{number}/api/json` | GET | Get build details |
| `/job/{name}/{number}/consoleText` | GET | Get build console output |
| `/job/{name}/{number}/stop` | POST | Stop/abort a build |
| `/queue/item/{id}/api/json` | GET | Get queue item status |

### 7.2 API Client Design

```swift
protocol JenkinsAPIClientProtocol {
    func validateConnection(server: ServerConfiguration) async throws -> Bool
    func fetchJobs() async throws -> [JenkinsJob]
    func fetchJobDetail(jobName: String) async throws -> JenkinsJob
    func triggerBuild(jobName: String, parameters: [String: String]?) async throws -> Int
    func fetchBuild(jobName: String, buildNumber: Int) async throws -> Build
    func fetchConsoleOutput(jobName: String, buildNumber: Int) async throws -> String
    func cancelBuild(jobName: String, buildNumber: Int) async throws
}

class JenkinsAPIClient: JenkinsAPIClientProtocol {
    private let session: URLSession
    private let keychainService: KeychainServiceProtocol
    
    init(session: URLSession = .shared, 
         keychainService: KeychainServiceProtocol) {
        self.session = session
        self.keychainService = keychainService
    }
    
    // Implementation with proper error handling,
    // authentication header injection, and response parsing
}
```

### 7.3 Authentication Flow

```
┌─────────────────┐
│  User Enters    │
│  Credentials    │
└────────┬────────┘
         │
         ▼
┌─────────────────┐     ┌─────────────────┐
│  Validate with  │────►│  Store Token    │
│  Jenkins API    │     │  in Keychain    │
└────────┬────────┘     └────────┬────────┘
         │                       │
         │ (On Each Request)     ▼
         │              ┌─────────────────┐
         └─────────────►│  Add Basic Auth │
                        │  Header         │
                        └─────────────────┘
                                 │
                                 ▼
                        ┌─────────────────┐
                        │  HTTPS Request  │
                        │  to Jenkins     │
                        └─────────────────┘
```

### 7.4 Request Builder

```swift
struct APIEndpoint {
    let path: String
    let method: HTTPMethod
    let queryItems: [URLQueryItem]?
    let body: Data?
    
    static func jobs(tree: String? = nil) -> APIEndpoint {
        APIEndpoint(
            path: "/api/json",
            method: .get,
            queryItems: tree.map { [URLQueryItem(name: "tree", value: $0)] },
            body: nil
        )
    }
    
    static func triggerBuild(jobName: String) -> APIEndpoint {
        APIEndpoint(
            path: "/job/\(jobName)/build",
            method: .post,
            queryItems: nil,
            body: nil
        )
    }
    
    // ... more endpoints
}
```

---

## 8. Security Architecture

### 8.1 Keychain Integration

```swift
protocol KeychainServiceProtocol {
    func save(token: String, for serverId: UUID) throws
    func retrieve(for serverId: UUID) throws -> String?
    func delete(for serverId: UUID) throws
}

class KeychainService: KeychainServiceProtocol {
    private let serviceName = "com.latrigger.jenkins"
    
    func save(token: String, for serverId: UUID) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: serverId.uuidString,
            kSecValueData as String: token.data(using: .utf8)!,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        // Add or update keychain item
    }
}
```

### 8.2 Certificate Pinning

```swift
class CertificatePinner: NSObject, URLSessionDelegate {
    private let pinnedCertificates: [SecCertificate]
    
    func urlSession(_ session: URLSession, 
                    didReceive challenge: URLAuthenticationChallenge,
                    completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        // Validate server certificate against pinned certificates
    }
}
```

---

## 9. Persistence Layer

### 9.1 Storage Strategy

| Data Type | Storage | Reason |
|-----------|---------|--------|
| API Tokens | Keychain | Security |
| Server Configs | CoreData | Structured data |
| User Preferences | UserDefaults | Simple key-value |
| Job Cache | Memory/Disk | Performance |
| Build History | CoreData | Offline access |

### 9.2 CoreData Model

```
┌─────────────────────────────────────────────────────────────────┐
│                      CoreData Model                              │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ┌─────────────────┐       ┌─────────────────┐                  │
│  │ ServerEntity    │       │ FavoriteJob     │                  │
│  ├─────────────────┤       ├─────────────────┤                  │
│  │ id: UUID        │       │ id: UUID        │                  │
│  │ name: String    │◄──────│ serverId: UUID  │                  │
│  │ url: String     │       │ jobName: String │                  │
│  │ username: String│       │ addedAt: Date   │                  │
│  │ isDefault: Bool │       └─────────────────┘                  │
│  │ createdAt: Date │                                            │
│  │ lastUsedAt: Date│       ┌─────────────────┐                  │
│  └─────────────────┘       │ CachedBuild     │                  │
│                            ├─────────────────┤                  │
│                            │ id: UUID        │                  │
│                            │ serverId: UUID  │                  │
│                            │ jobName: String │                  │
│                            │ buildNumber: Int│                  │
│                            │ result: String  │                  │
│                            │ timestamp: Date │                  │
│                            │ cachedAt: Date  │                  │
│                            └─────────────────┘                  │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

---

## 10. Push Notifications Architecture

### 10.1 Notification Flow (MVP)

```
┌───────────┐     ┌───────────┐     ┌───────────┐     ┌───────────┐
│   Build   │     │   App     │     │  Check    │     │  Local    │
│  Trigger  │────►│  Polls    │────►│  Status   │────►│  Notif    │
│           │     │  (BG)     │     │           │     │           │
└───────────┘     └───────────┘     └───────────┘     └───────────┘
```

### 10.2 Notification Flow (Future - Backend)

```
┌───────────┐     ┌───────────┐     ┌───────────┐     ┌───────────┐
│  Jenkins  │     │  Backend  │     │   APNs    │     │   iOS     │
│  Webhook  │────►│  Proxy    │────►│           │────►│   App     │
│           │     │           │     │           │     │           │
└───────────┘     └───────────┘     └───────────┘     └───────────┘
```

---

## 11. Technology Stack

### 11.1 Core Technologies

| Layer | Technology |
|-------|------------|
| Language | Swift 5.9 |
| UI | SwiftUI |
| Reactive | Combine |
| Networking | URLSession |
| Persistence | CoreData |
| Security | Keychain Services |
| Backend | Node.js (Express) |
| Database | MongoDB |
| Push | UserNotifications |
| Analytics | Firebase Crashlytics |

### 11.2 Third-Party Dependencies (Minimal)

| Library | Purpose | Alternative |
|---------|---------|-------------|
| KeychainAccess | Simplified Keychain API | DIY wrapper |
| SwiftLint | Code style enforcement | N/A |

### 11.3 Development Tools

| Tool | Purpose |
|------|---------|
| Xcode 15+ | IDE |
| Swift Package Manager | Dependency management |
| XCTest | Unit/UI testing |
| Instruments | Performance profiling |
| Charles Proxy | API debugging |

---

## 12. Error Handling Strategy

### 12.1 Error Types

```swift
enum LaTriggerError: Error {
    // Network errors
    case networkUnavailable
    case serverUnreachable
    case requestTimeout
    case invalidResponse
    
    // Authentication errors
    case invalidCredentials
    case tokenExpired
    case unauthorized
    
    // Jenkins errors
    case jobNotFound
    case buildFailed
    case parameterValidationFailed
    
    // Local errors
    case keychainError(OSStatus)
    case persistenceError(Error)
}
```

### 12.2 Error Handling Flow

```
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│   API Error     │────►│   Map to        │────►│   Display       │
│   Occurs        │     │   App Error     │     │   User Message  │
└─────────────────┘     └─────────────────┘     └─────────────────┘
                                │
                                ▼
                        ┌─────────────────┐
                        │   Log to        │
                        │   Analytics     │
                        └─────────────────┘
```

---

## 13. Performance Considerations

### 13.1 Caching Strategy

| Data | Cache Duration | Strategy |
|------|----------------|----------|
| Job List | 5 minutes | Memory + Disk |
| Job Details | 2 minutes | Memory |
| Build Status | 30 seconds | Memory |
| Console Logs | On demand | No cache |

### 13.2 Optimization Techniques

- **Lazy loading**: Load job details on demand
- **Pagination**: Limit build history to 20 items
- **Image caching**: Cache Jenkins job icons
- **Request coalescing**: Debounce rapid refresh requests
- **Background refresh**: Use BGTaskScheduler for periodic updates

---

## 14. Scalability Considerations

### 14.1 Multi-Server Support

```
┌─────────────────┐
│  Server Manager │
├─────────────────┤
│ + servers[]     │
│ + activeServer  │
│ + switchServer()│
│ + addServer()   │
│ + removeServer()│
└─────────────────┘
         │
         ▼
┌─────────────────┐
│  API Client     │
│  (per server)   │
└─────────────────┘
```

### 14.2 Large Job Lists

- Virtual scrolling for 1000+ jobs
- Server-side filtering when available
- Progressive loading with pagination

---

## 15. Backend Service Architecture (`lab-trigger-backend`)

The backend is a Node.js application using Express and Mongoose to provide a secure API for the iOS application.

### 15.1 Component Breakdown

- **Express Server**: Handles routing and HTTP requests.
- **Mongoose Models**: Defines schemas for MongoDB.
- **Controllers**: Implementation logic for Auth and Credentials.
- **Middleware**: JWT authentication and error handling.

### 15.2 Data Schema (MongoDB)

#### User Collection
```javascript
{
  email: { type: String, required: true, unique: true },
  password: { type: String, required: true }, // Hashed with bcrypt
  createdAt: { type: Date, default: Date.now }
}
```

#### JenkinsCredential Collection
```javascript
{
  userId: { type: ObjectId, ref: 'User' },
  serverName: String,
  jenkinsURL: String,
  username: String,
  password: String, // Encrypted/Securely stored
  paramToken: String,
  isDefault: Boolean,
  createdAt: Date
}
```

### 15.3 API Endpoints

| Category | Endpoint | Method | Description |
|----------|----------|--------|-------------|
| **Auth** | `/api/auth/signup` | POST | Register new user |
| **Auth** | `/api/auth/login` | POST | Login and receive JWT |
| **Config** | `/api/credentials` | GET | List user's servers |
| **Config** | `/api/credentials` | POST | Add new server config |
| **Config** | `/api/credentials/:id`| PUT | Update server config |
| **Config** | `/api/credentials/:id`| DELETE | Delete server config |

---

## 16. Decision Log

| Decision | Rationale | Date |
|----------|-----------|------|
| SwiftUI over UIKit | Modern, declarative, faster development | Feb 2026 |
| MVVM pattern | Clean separation, testability | Feb 2026 |
| URLSession over Alamofire | Reduce dependencies, built-in sufficient | Feb 2026 |
| Full Backend Migration | Centralized storage, JWT security, multi-device potential | Feb 2026 |

---

## Document History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | Feb 7, 2026 | JobTrigger Team | Initial architecture |
| 1.1 | Feb 17, 2026 | Antigravity | Integrated Node.js + MongoDB backend |
