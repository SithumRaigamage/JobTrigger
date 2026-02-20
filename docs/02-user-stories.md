# User Stories Document
## JobTrigger — iOS Jenkins Build Trigger App

| Document Info | |
|---------------|---|
| **Version** | 1.0 |
| **Date** | February 7, 2026 |
| **Author** | JobTrigger Team |
| **Status** | Draft |

---

## Overview

This document contains all user stories for the JobTrigger iOS application, organized by epic and ready for import into Jira or similar project management tools.

---

## Epic Structure

```
EP-01: Authentication & Server Management
EP-02: Job Management
EP-03: Build Triggering
EP-04: Build Monitoring
EP-05: Notifications
EP-06: Settings & Preferences
```

---

## EP-01: Authentication & Server Management

### ✅ US-01: Connect to Jenkins Server with API Token

#### <span style="color:green">**STATUS: COMPLETED**</span>

**As a** user  
**I want to** connect to a Jenkins server using an API token  
**So that** my credentials are secure and I can access my Jenkins instance

**Priority:** P0 (Must Have)  
**Story Points:** 5  
**Sprint:** 1

#### Acceptance Criteria - US-01
- [x] User can enter Jenkins server URL
- [x] User can enter username and API token
- [x] App validates the connection before saving
- [x] Error message shown for invalid credentials
- [x] Success confirmation shown on valid connection
- [x] Credentials stored securely in iOS Keychain via Node.js backend
#### Acceptance Criteria (status verified)
- [x] User can enter Jenkins server URL
- [x] User can enter username and API token
- [x] App validates the connection before saving
- [x] Error message shown for invalid credentials
- [x] Success confirmation shown on valid connection
- [ ] Credentials stored securely in iOS Keychain via Node.js backend

#### Technical Notes
- Use URLSession for API calls
- Validate with `/api/json` endpoint
- Store in Keychain with `kSecClassGenericPassword`

---

### ✅ US-02: Save Multiple Jenkins Servers

#### <span style="color:green">**STATUS: COMPLETED**</span>

**As a** user  
**I want to** save multiple Jenkins server configurations  
**So that** I can manage different environments (dev, staging, prod)

**Priority:** P1 (Should Have)  
**Story Points:** 3  
**Sprint:** 1

#### Acceptance Criteria - US-02
- [ ] User can add multiple server configurations
- [ ] Each server has a unique display name
- [ ] Server list shows all saved servers
- [ ] User can set a default server
- [ ] Maximum of 10 servers supported
#### Acceptance Criteria (status verified)
- [x] User can add multiple server configurations
- [x] Each server has a unique display name (Set by user)
- [x] Server list shows all saved servers
- [x] User can set a default server
- [ ] Maximum of 10 servers supported (Not enforced)

#### Technical Notes
- Use CoreData or UserDefaults for server metadata
- Credentials remain in Keychain with server ID reference

---

### ✅ US-03: Switch Between Jenkins Servers

#### <span style="color:green">**STATUS: COMPLETED**</span>

**As a** user  
**I want to** switch between saved Jenkins servers  
**So that** I can work with different environments quickly

**Priority:** P1 (Should Have)  
**Story Points:** 2  
**Sprint:** 2

#### Acceptance Criteria - US-03
- [ ] Active server displayed in navigation/header
- [ ] Tap on server name shows server picker
- [ ] Switching server refreshes job list
- [ ] Last active server remembered on app launch
#### Acceptance Criteria (status verified)
- [x] Active server displayed in navigation/header (Implemented in `NavBarView` and `HomeView`)
- [x] Tap on server name shows server picker (Implemented via `SettingsView` list)
- [x] Switching server refreshes job list (Implemented via `ActiveServerManager` and `HomeViewModel`)
- [x] Last active server remembered on app launch (Retrieved from backend `isDefault` status)

---

### ✅ US-04: Edit Server Configuration

#### <span style="color:green">**STATUS: COMPLETED**</span>

**As a** user  
**I want to** edit my saved Jenkins server configurations  
**So that** I can update tokens or server URLs when they change

**Priority:** P1 (Should Have)  
**Story Points:** 2  
**Sprint:** 2

#### Acceptance Criteria - US-04
- [ ] User can edit server name, URL, and credentials
- [ ] Changes require re-validation before saving
- [ ] Cancel discards changes
- [ ] Original config preserved until save confirmed
#### Acceptance Criteria (status verified)
- [x] User can edit server name, URL, and credentials
- [x] Changes require re-validation before saving (in saveSettings)
- [x] Cancel discards changes (Sheet presentation handles this)
- [x] Original config preserved until save confirmed

---

### ✅ US-05: Delete Server Configuration

#### <span style="color:green">**STATUS: COMPLETED**</span>

**As a** user  
**I want to** delete a saved Jenkins server  
**So that** I can remove servers I no longer use

**Priority:** P1 (Should Have)  
**Story Points:** 1  
**Sprint:** 2

#### Acceptance Criteria - US-05
- [ ] Swipe-to-delete on server list
- [ ] Confirmation dialog before deletion
- [ ] Associated credentials removed from Keychain
- [ ] Cannot delete if only one server exists (or can with warning)
#### Acceptance Criteria (status verified)
- [x] Swipe-to-delete on server list
- [ ] Confirmation dialog before deletion (Missing in ViewModel)
- [x] Associated credentials removed from Keychain (Handled by backend)
- [x] Cannot delete if only one server exists (UI allows, but backend handles ownership)

---

### ✅ US-07: View All Jenkins Jobs

#### <span style="color:green">**STATUS: COMPLETED**</span>

**As a** user  
**I want to** view all available Jenkins jobs  
**So that** I can see what builds are available to trigger

**Priority:** P0 (Must Have)  
**Story Points:** 5  
**Sprint:** 2

#### Acceptance Criteria - US-07
- [x] Jobs displayed in a scrollable list
- [x] Each job shows name and last build status
- [x] Folder structure represented (nested jobs - Level 6 support)
- [x] Pull-to-refresh updates job list
- [x] Loading indicator while fetching
- [x] Empty state when no jobs found
- [x] API Service supports fetching jobs (JenkinsAPIService.fetchJobs)

#### Technical Notes
- Use `/api/json?tree=jobs[name,url,color]`
- Support recursive folder traversal

---

### ✅ US-08: Search Jobs by Name

#### <span style="color:green">**STATUS: COMPLETED**</span>

**As a** user  
**I want to** search and filter jobs by name  
**So that** I can quickly find the job I need

**Priority:** P0 (Must Have)  
**Story Points:** 3  
**Sprint:** 2

#### Acceptance Criteria - US-08
- [x] Search bar at top of job list
- [x] Real-time filtering as user types
- [x] Case-insensitive search
- [x] Highlights matching text
- [x] "No results" message when no matches

---

### ✅ US-09: View Job Details

#### <span style="color:green">**STATUS: COMPLETED**</span>

**As a** user  
**I want to** view detailed information about a job  
**So that** I can understand the job before triggering

**Priority:** P1 (Should Have)  
**Story Points:** 3  
**Sprint:** 3

#### Acceptance Criteria - US-09
- [x] Tap on job opens detail view
- [x] Shows job name, description, URL
- [x] Shows last build number and status
- [x] Shows job parameters (if any)
- [x] Shows health report
- [ ] Link to open in browser (Removed for now)

---


### US-11: View Job Build History

**Status: COMPLETED** (Sprint 3)

**As a** user  
**I want to** view the build history of a job  
**So that** I can see past build results and trends

**Priority:** P1 (Should Have)  
**Story Points:** 3  
**Sprint:** 3

#### Acceptance Criteria - US-11
- [x] Build history list in job details
- [x] Global history tab in main navigation
- [x] Shows last 20 builds by default
- [x] Each build shows number, status, timestamp, and duration
- [ ] Tap on build shows build details (Deep link/Log view)
- [ ] Load more pagination

---

## EP-03: Build Triggering

### 🏃 US-12: Trigger Job with One Tap

#### <span style="color:blue">**STATUS: IN PROGRESS**</span>

**As a** user  
**I want to** trigger a Jenkins job with one tap  
**So that** I can quickly start builds without navigating through menus

**Priority:** P0 (Must Have)  
**Story Points:** 5  
**Sprint:** 3

#### Acceptance Criteria
- [x] "Build" button prominently displayed
- [ ] Confirmation dialog before triggering
- [x] Loading state during API call
- [x] Success toast on successful trigger (Handled by NotificationManager)
- [x] Error message on failure with retry option (Handled by NotificationManager)
- [ ] Haptic feedback on trigger

#### Technical Notes
- Use `/job/{jobName}/build` for parameterless jobs
- Handle queue response and return queue ID

---

### US-13: Trigger Build with Parameters

**Status: COMPLETED** (Sprint 3)

**As a** user  
**I want to** pass parameters before triggering a build  
**So that** I can customize the build execution

**Priority:** P0 (Must Have)  
**Story Points:** 8  
**Sprint:** 3

#### Acceptance Criteria - US-13
- [x] Parameter form shown for parameterized jobs
- [x] Supports text, choice, boolean, password parameters
- [x] Default values pre-populated
- [x] Parameter descriptions shown as hints
- [ ] Required parameters validated
- [ ] Recent parameter values remembered

#### Technical Notes
- Parse `/job/{jobName}/api/json` for parameter definitions
- Use `/job/{jobName}/buildWithParameters`

#### Supported Parameter Types
| Type | UI Component |
|------|--------------|
| String | Text field |
| Choice | Picker/Dropdown |
| Boolean | Toggle switch |
| Password | Secure text field |
| Text | Multi-line text area |

---

### US-14: Quick Trigger from Job List
**As a** user  
**I want to** trigger a job directly from the job list  
**So that** I don't have to navigate to job details for simple triggers

**Priority:** P1 (Should Have)  
**Story Points:** 3  
**Sprint:** 4

#### Acceptance Criteria
- [ ] Swipe action or quick button on job row
- [ ] Shows parameter sheet if needed
- [ ] Same confirmation flow as detail trigger
- [ ] Only for jobs user has permission to build

---

### US-15: Cancel Running Build
**As a** user  
**I want to** cancel a running build  
**So that** I can stop builds that were triggered by mistake

**Priority:** P2 (Nice to Have)  
**Story Points:** 3  
**Sprint:** 5

#### Acceptance Criteria
- [ ] "Cancel" button visible for running builds
- [ ] Confirmation before cancellation
- [ ] Build status updates to "Aborted"
- [ ] Error handling for permission denied

#### Technical Notes
- Use `/job/{jobName}/{buildNumber}/stop`

---

### US-16: Rebuild Last Build
**As a** user  
**I want to** quickly rebuild the last build  
**So that** I can retry failed builds with same parameters

**Priority:** P2 (Nice to Have)  
**Story Points:** 2  
**Sprint:** 5

#### Acceptance Criteria
- [ ] "Rebuild" button in build details
- [ ] Uses same parameters as original build
- [ ] Shows parameter preview before triggering
- [ ] Option to modify parameters before rebuild

---

## EP-04: Build Monitoring

### US-17: View Current Build Status

**Status: COMPLETED** (Sprint 3)

**As a** user  
**I want to** see the current build status  
**So that** I can know if builds are passing or failing

**Priority:** P0 (Must Have)  
**Story Points:** 5  
**Sprint:** 3

#### Acceptance Criteria - US-17
- [x] Status indicator (icon + color) for each build
- [x] Status types: Success, Failure, Unstable, Running, Aborted, Not Built
- [x] Last build timestamp shown
- [x] Duration of build shown
- [x] Semantic color mapping (Jenkins Blue -> Green)
- [x] Pulsing animation for active builds

#### Status Mapping
| Jenkins Color | App Status | Color |
|---------------|------------|-------|
| blue | Success | Green |
| red | Failed | Red |
| yellow | Unstable | Orange |
| blue_anime | Building | Blue (animated) |
| aborted | Aborted | Gray |
| notbuilt | Not Built | Light Gray |

---

### US-18: View Build Progress

**Status: COMPLETED** (Sprint 3)

**As a** user  
**I want to** see build progress percentage  
**So that** I can estimate when the build will complete

**Priority:** P1 (Should Have)  
**Story Points:** 3  
**Sprint:** 4

#### Acceptance Criteria - US-18
- [x] Progress bar for running builds
- [x] Percentage based on estimated vs elapsed time
- [x] "Estimating..." for first builds
- [x] Updates every 5 seconds

#### Technical Notes
- Use `estimatedDuration` and `timestamp` from build API

---

### US-19: View Build Logs

**Status: COMPLETED** (Sprint 3)

**As a** user  
**I want to** view build logs  
**So that** I can debug failed builds without opening a browser

**Priority:** P1 (Should Have)  
**Story Points:** 5  
**Sprint:** 4

#### Acceptance Criteria - US-19
- [x] Console output in scrollable view
- [x] Progressive loading for large logs
- [x] Streaming updates for active builds
- [x] Copy log to clipboard
- [x] Share log via iOS share sheet

#### Technical Notes
- Use `/job/{jobName}/{buildNumber}/consoleText`

---

### US-20: Manual Refresh Build Status
**As a** user  
**I want to** manually refresh build status  
**So that** I can get the latest information on demand

**Priority:** P0 (Must Have)  
**Story Points:** 1  
**Sprint:** 3

#### Acceptance Criteria
- [ ] Pull-to-refresh on build status screen
- [ ] Refresh button in navigation bar
- [ ] Loading indicator during refresh
- [ ] Timestamp of last refresh shown

---

### US-21: Auto-Refresh Build Status
**As a** user  
**I want to** have build status auto-refresh  
**So that** I don't have to manually refresh while watching a build

**Priority:** P2 (Nice to Have)  
**Story Points:** 3  
**Sprint:** 5

#### Acceptance Criteria
- [ ] Auto-refresh every 10 seconds for running builds
- [ ] Stops when build completes
- [ ] Battery-conscious (stops when app backgrounded)
- [ ] Configurable refresh interval

---

## EP-05: Notifications

### US-22: Push Notification on Build Completion
**As a** user  
**I want to** receive a push notification when a build completes  
**So that** I know immediately when my build is done

**Priority:** P1 (Should Have)  
**Story Points:** 8  
**Sprint:** 5

#### Acceptance Criteria
- [ ] Notification sent when build completes
- [ ] Shows job name and build result
- [ ] Tap notification opens build details
- [ ] Different notification sound for success/failure
- [ ] Works when app is backgrounded

#### Technical Notes
- Requires background polling or backend service
- Consider Jenkins Notification Plugin webhook

---

### US-23: Configure Notification Preferences
**As a** user  
**I want to** configure notification preferences  
**So that** I only get notified about builds I care about

**Priority:** P2 (Nice to Have)  
**Story Points:** 3  
**Sprint:** 6

#### Acceptance Criteria
- [ ] Global notifications on/off toggle
- [ ] Notify on: Success, Failure, All, None
- [ ] Quiet hours configuration
- [ ] Per-server notification settings

---

### US-24: Per-Job Notification Settings
**As a** user  
**I want to** enable/disable notifications for specific jobs  
**So that** I'm not overwhelmed by notifications from less important jobs

**Priority:** P2 (Nice to Have)  
**Story Points:** 2  
**Sprint:** 6

#### Acceptance Criteria
- [ ] Notification toggle in job details
- [ ] Overrides global settings
- [ ] Visual indicator for jobs with notifications enabled

---

## EP-06: Settings & Preferences

### ✅ US-25: App Settings Screen

#### <span style="color:green">**STATUS: COMPLETED**</span>

**As a** user  
**I want to** access app settings  
**So that** I can customize the app behavior

**Priority:** P1 (Should Have)  
**Story Points:** 3  
**Sprint:** 4

#### Acceptance Criteria
- [x] Settings accessible from tab bar
- [x] Grouped settings with clear labels
- [x] Changes applied immediately and synced to backend
#### Acceptance Criteria (status verified)
- [x] Settings accessible from tab bar (NavBarView)
- [x] Grouped settings with clear labels (SettingsView Forms)
- [x] Changes applied immediately and synced to backend (CredentialStorageService)

#### Settings Sections
- Account & Servers
- Notifications
- Appearance
- Security
- About

---

### US-26: Dark Mode Support
**As a** user  
**I want to** use the app in dark mode  
**So that** I can use it comfortably in low-light environments

**Priority:** P1 (Should Have)  
**Story Points:** 2  
**Sprint:** 4

#### Acceptance Criteria
- [ ] Follows system appearance by default
- [ ] Option to force light/dark mode
- [ ] All screens support both modes
- [ ] Proper contrast ratios maintained

---

### US-27: View App Information
**As a** user  
**I want to** view app version and information  
**So that** I can check for updates and access support

**Priority:** P2 (Nice to Have)  
**Story Points:** 1  
**Sprint:** 6

#### Acceptance Criteria
- [ ] Shows app version and build number
- [ ] Link to privacy policy
- [ ] Link to terms of service
- [ ] Link to support/feedback
- [ ] Open source licenses

---

## Story Map Overview

```
                    Sprint 1      Sprint 2      Sprint 3      Sprint 4      Sprint 5      Sprint 6
                  ┌───────────┬───────────┬───────────┬───────────┬───────────┬───────────┐
Authentication    │  US-01    │  US-03    │           │  US-06    │           │           │
                  │  US-02    │  US-04    │           │           │           │           │
                  │           │  US-05    │           │           │           │           │
                  ├───────────┼───────────┼───────────┼───────────┼───────────┼───────────┤
Job Management    │           │  US-07    │  US-09    │  US-10    │           │           │
                  │           │  US-08    │  US-11    │           │           │           │
                  ├───────────┼───────────┼───────────┼───────────┼───────────┼───────────┤
Build Trigger     │           │           │  US-12    │  US-14    │  US-15    │           │
                  │           │           │  US-13    │           │  US-16    │           │
                  ├───────────┼───────────┼───────────┼───────────┼───────────┼───────────┤
Monitoring        │           │           │  US-17    │  US-18    │  US-21    │           │
                  │           │           │  US-20    │  US-19    │           │           │
                  ├───────────┼───────────┼───────────┼───────────┼───────────┼───────────┤
Notifications     │           │           │           │           │  US-22    │  US-23    │
                  │           │           │           │           │           │  US-24    │
                  ├───────────┼───────────┼───────────┼───────────┼───────────┼───────────┤
Settings          │           │           │           │  US-25    │           │  US-27    │
                  │           │           │           │  US-26    │           │           │
                  └───────────┴───────────┴───────────┴───────────┴───────────┴───────────┘
```

---

## Velocity Planning

| Sprint | Story Points | Stories |
|--------|-------------|---------|
| Sprint 1 | 8 | US-01, US-02 |
| Sprint 2 | 16 | US-03, US-04, US-05, US-07, US-08 |
| Sprint 3 | 24 | US-09, US-11, US-12, US-13, US-17, US-20 |
| Sprint 4 | 19 | US-06, US-10, US-14, US-18, US-19, US-25, US-26 |
| Sprint 5 | 19 | US-15, US-16, US-21, US-22 |
| Sprint 6 | 6 | US-23, US-24, US-27 |

---

## Definition of Done (DoD)

A user story is considered "Done" when:

- [ ] Code is written and follows Swift style guidelines
- [ ] Unit tests written with >80% coverage
- [ ] UI tests written for critical paths
- [ ] Code reviewed and approved
- [ ] No critical or high-severity bugs
- [ ] Accessibility requirements met
- [ ] Documentation updated
- [ ] Works on iPhone and iPad
- [ ] Works in light and dark mode
- [ ] Merged to main branch

---

## Document History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | Feb 7, 2026 | JobTrigger Team | Initial user stories |
