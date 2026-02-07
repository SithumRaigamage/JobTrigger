# Security Design Document
## laTrigger — iOS Jenkins Build Trigger App

| Document Info | |
|---------------|---|
| **Version** | 1.0 |
| **Date** | February 7, 2026 |
| **Author** | laTrigger Security Team |
| **Status** | Draft |
| **Classification** | Internal |

---

## 1. Executive Summary

This document outlines the security architecture, threat model, and security controls for the laTrigger iOS application. The app handles sensitive credentials (Jenkins API tokens) and performs privileged operations (triggering builds), requiring robust security measures.

---

## 2. Security Objectives

### 2.1 Primary Objectives

| Objective | Description |
|-----------|-------------|
| **Confidentiality** | Protect API tokens and server configurations from unauthorized access |
| **Integrity** | Ensure build triggers and commands are not tampered with |
| **Availability** | Ensure app remains functional even under adverse conditions |
| **Authentication** | Verify user identity before allowing sensitive operations |
| **Authorization** | Enforce Jenkins RBAC permissions on mobile |

### 2.2 Security Principles

1. **Defense in Depth** — Multiple security layers
2. **Least Privilege** — Request only necessary permissions
3. **Secure by Default** — Security enabled out of the box
4. **Zero Trust** — Verify all requests, trust nothing
5. **Fail Secure** — Default to secure state on errors

---

## 3. Threat Model

### 3.1 Assets

| Asset | Sensitivity | Impact if Compromised |
|-------|-------------|----------------------|
| Jenkins API Token | Critical | Full Jenkins access |
| Server URL | High | Attack surface exposure |
| Build Parameters | Medium | Potential injection |
| Build Logs | Medium | Information disclosure |
| User Preferences | Low | Privacy concern |

### 3.2 Threat Actors

| Actor | Motivation | Capability |
|-------|------------|------------|
| Malicious App | Data theft | Device access |
| Network Attacker | MITM, eavesdropping | Network position |
| Physical Attacker | Device theft | Physical access |
| Insider Threat | Sabotage | Legitimate access |
| Malware | Keylogging, screen capture | Device compromise |

### 3.3 Attack Surface

```
┌─────────────────────────────────────────────────────────────────┐
│                       ATTACK SURFACE                             │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │  User Interface                                            │  │
│  │  • Shoulder surfing                                        │  │
│  │  • Screen capture malware                                  │  │
│  │  • Input validation bypass                                 │  │
│  └───────────────────────────────────────────────────────────┘  │
│                                                                  │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │  Network Communication                                     │  │
│  │  • Man-in-the-middle attacks                              │  │
│  │  • DNS spoofing                                           │  │
│  │  • SSL stripping                                          │  │
│  │  • Request/response tampering                             │  │
│  └───────────────────────────────────────────────────────────┘  │
│                                                                  │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │  Local Storage                                             │  │
│  │  • Keychain extraction (jailbreak)                        │  │
│  │  • Backup extraction                                      │  │
│  │  • Debug artifacts                                        │  │
│  └───────────────────────────────────────────────────────────┘  │
│                                                                  │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │  Application Binary                                        │  │
│  │  • Reverse engineering                                    │  │
│  │  • Code injection (jailbreak)                             │  │
│  │  • Debug/logging exposure                                 │  │
│  └───────────────────────────────────────────────────────────┘  │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### 3.4 Threat Matrix (STRIDE)

| Threat | Category | Risk | Mitigation |
|--------|----------|------|------------|
| Token theft from memory | Spoofing | High | Minimize token lifetime in memory |
| MITM on API calls | Tampering | Critical | TLS + Certificate pinning |
| Fake Jenkins server | Spoofing | High | Server fingerprinting |
| Credential disclosure in logs | Info Disclosure | High | No credential logging |
| Build trigger replay | Repudiation | Medium | Request timestamps, CSRF tokens |
| Brute force token guess | Elevation | Low | Rate limiting on Jenkins side |
| Denial of service | DoS | Low | Graceful error handling |

---

## 4. Security Architecture

### 4.1 Security Layers

```
┌─────────────────────────────────────────────────────────────────┐
│                    SECURITY ARCHITECTURE                         │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  Layer 1: Device Security                                        │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │  • iOS Secure Enclave                                      │  │
│  │  • Device Passcode/Biometrics                             │  │
│  │  • Jailbreak Detection                                    │  │
│  └───────────────────────────────────────────────────────────┘  │
│                                                                  │
│  Layer 2: Application Security                                   │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │  • App Lock (Face ID/Touch ID)                            │  │
│  │  • Data Protection (NSFileProtectionComplete)             │  │
│  │  • Code Obfuscation (optional)                            │  │
│  └───────────────────────────────────────────────────────────┘  │
│                                                                  │
│  Layer 3: Data Security                                          │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │  • Keychain (kSecAttrAccessibleWhenUnlockedThisDeviceOnly)│  │
│  │  • No credential caching in memory                        │  │
│  │  • Secure data wiping                                     │  │
│  └───────────────────────────────────────────────────────────┘  │
│                                                                  │
│  Layer 4: Network Security                                       │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │  • TLS 1.2+ required                                      │  │
│  │  • Certificate Pinning                                    │  │
│  │  • No HTTP fallback                                       │  │
│  └───────────────────────────────────────────────────────────┘  │
│                                                                  │
│  Layer 5: Backend Security (Future)                              │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │  • Token proxy service                                    │  │
│  │  • Rate limiting                                          │  │
│  │  • Audit logging                                          │  │
│  └───────────────────────────────────────────────────────────┘  │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

---

## 5. Authentication Security

### 5.1 Credential Requirements

| Requirement | Implementation |
|-------------|----------------|
| No password storage | API tokens only |
| Token format | Jenkins API tokens (hex string) |
| Token validation | Test with `/api/json` before storing |
| Token scope | Recommend scoped/limited tokens |

### 5.2 Token Storage

```swift
// Keychain storage configuration
let keychainQuery: [String: Any] = [
    kSecClass as String: kSecClassGenericPassword,
    kSecAttrService as String: "com.latrigger.jenkins",
    kSecAttrAccount as String: serverId.uuidString,
    kSecValueData as String: tokenData,
    
    // Security attributes
    kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
    kSecAttrSynchronizable as String: false,  // Don't sync to iCloud
    
    // Biometric protection (optional)
    kSecAttrAccessControl as String: accessControl
]
```

### 5.3 Biometric Authentication

```swift
// LAContext configuration
let context = LAContext()
context.localizedReason = "Authenticate to access Jenkins servers"
context.localizedFallbackTitle = "Use Passcode"

// Require biometrics, fallback to device passcode
let policy = LAPolicy.deviceOwnerAuthentication
```

### 5.4 Session Management

| Aspect | Implementation |
|--------|----------------|
| Session lifetime | Per-app-launch (no persistent sessions) |
| Token refresh | N/A (Jenkins tokens don't expire) |
| Multi-device | Tokens not synced between devices |
| Logout | Clear cached data, retain Keychain tokens |

---

## 6. Network Security

### 6.1 Transport Security

| Control | Requirement |
|---------|-------------|
| Protocol | HTTPS only |
| TLS Version | TLS 1.2 minimum, TLS 1.3 preferred |
| HTTP Fallback | Disabled |
| ATS | App Transport Security enabled |
| Certificate Validation | Full chain validation |

### 6.2 App Transport Security Configuration

```xml
<!-- Info.plist -->
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsArbitraryLoads</key>
    <false/>
    
    <!-- Only if absolutely needed for specific legacy servers -->
    <key>NSExceptionDomains</key>
    <dict>
        <!-- Avoid exceptions if possible -->
    </dict>
</dict>
```

### 6.3 Certificate Pinning

```swift
class CertificatePinningDelegate: NSObject, URLSessionDelegate {
    
    // Pinned certificate public key hashes (SPKI)
    private var pinnedHashes: [String: [String]] = [:]
    
    func urlSession(
        _ session: URLSession,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    ) {
        guard challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
              let serverTrust = challenge.protectionSpace.serverTrust else {
            completionHandler(.cancelAuthenticationChallenge, nil)
            return
        }
        
        // Validate certificate chain
        var error: CFError?
        let isValid = SecTrustEvaluateWithError(serverTrust, &error)
        
        guard isValid else {
            completionHandler(.cancelAuthenticationChallenge, nil)
            return
        }
        
        // Check pinned hash (if configured for this domain)
        let host = challenge.protectionSpace.host
        if let expectedHashes = pinnedHashes[host] {
            guard validatePinnedCertificate(serverTrust, expectedHashes: expectedHashes) else {
                completionHandler(.cancelAuthenticationChallenge, nil)
                return
            }
        }
        
        let credential = URLCredential(trust: serverTrust)
        completionHandler(.useCredential, credential)
    }
    
    private func validatePinnedCertificate(_ trust: SecTrust, expectedHashes: [String]) -> Bool {
        // Extract and hash server certificate public key
        // Compare against expected hashes
        // Return true if any hash matches
        return true // Implementation details
    }
}
```

### 6.4 Request Security

| Header | Purpose |
|--------|---------|
| `Authorization: Basic {base64}` | Jenkins authentication |
| `User-Agent: laTrigger/1.0` | App identification |
| `X-Request-ID: {uuid}` | Request tracing |

---

## 7. Data Protection

### 7.1 Data Classification

| Data | Classification | Storage | Encryption |
|------|---------------|---------|------------|
| API Token | Confidential | Keychain | Hardware encrypted |
| Server URL | Internal | CoreData | File protection |
| Username | Internal | CoreData | File protection |
| Job Cache | Internal | Memory/Disk | Optional |
| Build Logs | Internal | Memory | None (transient) |
| Preferences | Internal | UserDefaults | None |

### 7.2 iOS Data Protection

```swift
// File protection for CoreData store
let storeOptions = [
    NSPersistentStoreFileProtectionKey: FileProtectionType.complete
]

// Ensure documents are protected when device is locked
let attributes = [
    FileAttributeKey.protectionKey: FileProtectionType.complete
]
try FileManager.default.setAttributes(attributes, ofItemAtPath: path)
```

### 7.3 Memory Security

```swift
// Clear sensitive data from memory when done
class SecureString {
    private var data: Data
    
    deinit {
        // Overwrite memory before deallocation
        data.withUnsafeMutableBytes { bytes in
            memset(bytes.baseAddress!, 0, bytes.count)
        }
    }
}
```

### 7.4 Backup Exclusion

```swift
// Exclude sensitive files from iTunes/iCloud backup
var resourceValues = URLResourceValues()
resourceValues.isExcludedFromBackup = true
try fileURL.setResourceValues(resourceValues)
```

---

## 8. Input Validation

### 8.1 Server URL Validation

```swift
func validateServerURL(_ urlString: String) -> Result<URL, ValidationError> {
    guard let url = URL(string: urlString) else {
        return .failure(.invalidFormat)
    }
    
    guard url.scheme == "https" else {
        return .failure(.httpNotAllowed)
    }
    
    guard url.host != nil else {
        return .failure(.missingHost)
    }
    
    // Block localhost/internal IPs in production
    guard !isPrivateIP(url.host!) else {
        return .failure(.privateIPNotAllowed)
    }
    
    return .success(url)
}
```

### 8.2 Parameter Sanitization

```swift
func sanitizeBuildParameter(_ value: String) -> String {
    // Remove or escape potentially dangerous characters
    let dangerous = CharacterSet(charactersIn: "`${}|;&<>")
    return value.components(separatedBy: dangerous).joined()
}

// For display in logs (redact sensitive values)
func redactSensitiveParameters(_ params: [String: String]) -> [String: String] {
    var redacted = params
    let sensitiveKeys = ["password", "secret", "token", "key", "credential"]
    
    for key in redacted.keys {
        if sensitiveKeys.contains(where: { key.lowercased().contains($0) }) {
            redacted[key] = "***REDACTED***"
        }
    }
    return redacted
}
```

### 8.3 Job Name Validation

```swift
func validateJobName(_ name: String) -> Bool {
    // Jenkins job name constraints
    let allowedCharacters = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-_. "))
    return name.unicodeScalars.allSatisfy { allowedCharacters.contains($0) }
}
```

---

## 9. Logging & Audit

### 9.1 Logging Policy

| Log Level | Includes | Excludes |
|-----------|----------|----------|
| Debug | Request URLs, response codes | Tokens, passwords |
| Info | User actions, build triggers | Full parameters |
| Warning | Validation failures, retries | Credentials |
| Error | Exception details | Stack traces with secrets |

### 9.2 Secure Logging Implementation

```swift
enum LogLevel {
    case debug, info, warning, error
}

class SecureLogger {
    
    func log(_ message: String, level: LogLevel) {
        let sanitized = sanitize(message)
        
        #if DEBUG
        print("[\(level)] \(sanitized)")
        #else
        // Production: Send to Crashlytics without sensitive data
        if level == .error {
            Crashlytics.crashlytics().log(sanitized)
        }
        #endif
    }
    
    private func sanitize(_ message: String) -> String {
        var result = message
        
        // Redact potential tokens (32-char hex strings)
        let tokenPattern = "[a-fA-F0-9]{32,}"
        result = result.replacingOccurrences(
            of: tokenPattern,
            with: "[REDACTED]",
            options: .regularExpression
        )
        
        // Redact Basic auth headers
        let authPattern = "Basic [A-Za-z0-9+/=]+"
        result = result.replacingOccurrences(
            of: authPattern,
            with: "Basic [REDACTED]",
            options: .regularExpression
        )
        
        return result
    }
}
```

### 9.3 Audit Trail

| Event | Logged Data | Storage |
|-------|-------------|---------|
| Server Added | Server name, timestamp | Local |
| Server Removed | Server name, timestamp | Local |
| Build Triggered | Job name, timestamp, success/fail | Local |
| Auth Failure | Server URL, timestamp | Local + Analytics |

---

## 10. Jailbreak Detection

### 10.1 Detection Checks

```swift
class JailbreakDetector {
    
    func isJailbroken() -> Bool {
        #if targetEnvironment(simulator)
        return false
        #else
        return checkSuspiciousPaths() ||
               checkWritableSystemPaths() ||
               checkSuspiciousApps() ||
               checkDyldEnvironment()
        #endif
    }
    
    private func checkSuspiciousPaths() -> Bool {
        let paths = [
            "/Applications/Cydia.app",
            "/private/var/lib/apt",
            "/private/var/stash",
            "/usr/bin/ssh",
            "/usr/sbin/sshd"
        ]
        return paths.contains { FileManager.default.fileExists(atPath: $0) }
    }
    
    private func checkWritableSystemPaths() -> Bool {
        let testPath = "/private/jailbreak_test.txt"
        do {
            try "test".write(toFile: testPath, atomically: true, encoding: .utf8)
            try FileManager.default.removeItem(atPath: testPath)
            return true
        } catch {
            return false
        }
    }
}
```

### 10.2 Jailbreak Response

| Sensitivity | Response |
|-------------|----------|
| Low | Show warning, allow use |
| Medium | Disable certain features |
| High | Refuse to run, wipe data |

**Recommendation for laTrigger**: Show warning but allow use (user may have legitimate reasons).

---

## 11. Security Testing

### 11.1 Testing Requirements

| Test Type | Frequency | Tools |
|-----------|-----------|-------|
| Static Analysis | Every build | SwiftLint, SonarQube |
| Dynamic Analysis | Weekly | Frida, Objection |
| Penetration Testing | Pre-release | Manual + Burp Suite |
| Dependency Scan | Daily | OWASP Dependency-Check |

### 11.2 Security Test Cases

| ID | Test Case | Expected Result |
|----|-----------|-----------------|
| SEC-01 | Attempt HTTP connection | Rejected by ATS |
| SEC-02 | Self-signed certificate | Connection rejected |
| SEC-03 | Token extraction from memory dump | Token not in plain text |
| SEC-04 | Keychain access without auth | Access denied |
| SEC-05 | SQL injection in job search | Input sanitized |
| SEC-06 | App backgrounding | Sensitive data cleared from screen |
| SEC-07 | Debug build in production | Build rejected |
| SEC-08 | Invalid certificate pin | Connection terminated |

### 11.3 OWASP MASVS Compliance

| Category | Level | Status |
|----------|-------|--------|
| MASVS-STORAGE | L1 | Planned |
| MASVS-CRYPTO | L1 | Planned |
| MASVS-AUTH | L1 | Planned |
| MASVS-NETWORK | L1 | Planned |
| MASVS-PLATFORM | L1 | Planned |
| MASVS-CODE | L1 | Planned |
| MASVS-RESILIENCE | L1 | Optional |

---

## 12. Incident Response

### 12.1 Security Incident Types

| Incident | Severity | Response |
|----------|----------|----------|
| Token compromise | Critical | Revoke token, notify user, force re-auth |
| Data breach | Critical | Investigate, notify affected users |
| Vulnerability discovered | High | Patch within 7 days, release update |
| Failed auth attempts | Medium | Rate limit, alert user |

### 12.2 Response Procedure

```
1. DETECT
   ↓
2. CONTAIN (disable affected feature if needed)
   ↓
3. INVESTIGATE (determine scope and cause)
   ↓
4. REMEDIATE (patch vulnerability)
   ↓
5. RECOVER (restore normal operation)
   ↓
6. LESSONS LEARNED (update security controls)
```

---

## 13. Privacy Considerations

### 13.1 Data Collection

| Data | Collected | Purpose | Retention |
|------|-----------|---------|-----------|
| Server URLs | Yes (local) | Functionality | Until deleted |
| Job names | Yes (cached) | UX | 24 hours |
| Build history | Yes (cached) | UX | 7 days |
| Crash reports | Yes (anonymized) | Debugging | 90 days |
| Usage analytics | Optional | Improvement | 1 year |

### 13.2 Privacy by Design

- No tracking without consent
- No personal data sent to third parties
- All server data stays on device
- User can export/delete all data
- Clear privacy policy

---

## 14. Compliance

### 14.1 Regulatory Requirements

| Regulation | Applicability | Controls |
|------------|---------------|----------|
| GDPR | EU users | Data minimization, right to delete |
| CCPA | California users | Disclosure, opt-out |
| App Store Guidelines | All users | Privacy nutrition labels |

### 14.2 App Store Privacy Labels

| Category | Data Collected |
|----------|----------------|
| Identifiers | Device ID (for crash reports) |
| Usage Data | App interactions (optional analytics) |
| Diagnostics | Crash logs |

---

## 15. Security Roadmap

### 15.1 MVP (Phase 3)

- [x] Keychain storage for tokens
- [x] HTTPS-only connections
- [x] Input validation
- [x] Secure logging

### 15.2 Phase 4 (Security Hardening)

- [ ] Certificate pinning
- [ ] Biometric app lock
- [ ] Jailbreak detection
- [ ] Background data protection

### 15.3 Future Enhancements

- [ ] Backend proxy for token isolation
- [ ] OAuth 2.0 support
- [ ] Hardware security key (FIDO2)
- [ ] Enterprise SSO integration

---

## 16. Approval & Sign-off

| Role | Name | Date | Signature |
|------|------|------|-----------|
| Security Lead | | | |
| Development Lead | | | |
| Product Owner | | | |

---

## Document History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | Feb 7, 2026 | Security Team | Initial security design |
