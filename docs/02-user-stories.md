# User Stories Document
## laTrigger — iOS Jenkins Build Trigger App

| Document Info | |
|---------------|---|
| **Version** | 1.0 |
| **Date** | February 7, 2026 |
| **Author** | laTrigger Team |
| **Status** | Draft |

---

## Overview

This document contains all user stories for the laTrigger iOS application, organized by epic and ready for import into Jira or similar project management tools.

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

### US-01: Connect to Jenkins Server with API Token
**As a** user  
**I want to** connect to a Jenkins server using an API token  
**So that** my credentials are secure and I can access my Jenkins instance

**Priority:** P0 (Must Have)  
**Story Points:** 5  
**Sprint:** 1

#### Acceptance Criteria
- [x] User can enter Jenkins server URL
- [x] User can enter username and API token
- [x] App validates the connection before saving
- [x] Error message shown for invalid credentials
- [x] Success confirmation shown on valid connection
- [ ] Credentials stored securely in iOS Keychain (JSON Placeholder used)

#### Technical Notes
- Use URLSession for API calls
- Validate with `/api/json` endpoint
- Store in Keychain with `kSecClassGenericPassword`

---

### US-02: Save Multiple Jenkins Servers
**As a** user  
**I want to** save multiple Jenkins server configurations  
**So that** I can manage different environments (dev, staging, prod)

**Priority:** P1 (Should Have)  
**Story Points:** 3  
**Sprint:** 1

#### Acceptance Criteria
- [ ] User can add multiple server configurations
- [ ] Each server has a unique display name
- [ ] Server list shows all saved servers
- [ ] User can set a default server
- [ ] Maximum of 10 servers supported

#### Technical Notes
- Use CoreData or UserDefaults for server metadata
- Credentials remain in Keychain with server ID reference

---

### US-03: Switch Between Jenkins Servers
**As a** user  
**I want to** switch between saved Jenkins servers  
**So that** I can work with different environments quickly

**Priority:** P1 (Should Have)  
**Story Points:** 2  
**Sprint:** 2

#### Acceptance Criteria
- [ ] Active server displayed in navigation/header
- [ ] Tap on server name shows server picker
- [ ] Switching server refreshes job list
- [ ] Last active server remembered on app launch

---

### US-04: Edit Server Configuration
**As a** user  
**I want to** edit my saved Jenkins server configurations  
**So that** I can update tokens or server URLs when they change

**Priority:** P1 (Should Have)  
**Story Points:** 2  
**Sprint:** 2

#### Acceptance Criteria
- [ ] User can edit server name, URL, and credentials
- [ ] Changes require re-validation before saving
- [ ] Cancel discards changes
- [ ] Original config preserved until save confirmed

---

### US-05: Delete Server Configuration
**As a** user  
**I want to** delete a saved Jenkins server  
**So that** I can remove servers I no longer use

**Priority:** P1 (Should Have)  
**Story Points:** 1  
**Sprint:** 2

#### Acceptance Criteria
- [ ] Swipe-to-delete on server list
- [ ] Confirmation dialog before deletion
- [ ] Associated credentials removed from Keychain
- [ ] Cannot delete if only one server exists (or can with warning)

---

### US-06: Biometric Authentication
**As a** user  
**I want to** protect the app with Face ID or Touch ID  
**So that** only I can access my Jenkins configurations

**Priority:** P2 (Nice to Have)  
**Story Points:** 3  
**Sprint:** 4

#### Acceptance Criteria
- [ ] Option to enable biometric lock in settings
- [ ] Face ID/Touch ID prompt on app launch
- [ ] Fallback to device passcode
- [ ] App locks when backgrounded (configurable)

---

## EP-02: Job Management

### US-07: View All Jenkins Jobs
**As a** user  
**I want to** view all available Jenkins jobs  
**So that** I can see what builds are available to trigger

**Priority:** P0 (Must Have)  
**Story Points:** 5  
**Sprint:** 2

#### Acceptance Criteria
- [ ] Jobs displayed in a scrollable list
- [ ] Each job shows name and last build status
- [ ] Folder structure represented (nested jobs)
- [ ] Pull-to-refresh updates job list
- [ ] Loading indicator while fetching
- [ ] Empty state when no jobs found
- [x] API Service supports fetching jobs

#### Technical Notes
- Use `/api/json?tree=jobs[name,url,color]`
- Support recursive folder traversal

---

### US-08: Search Jobs by Name
**As a** user  
**I want to** search and filter jobs by name  
**So that** I can quickly find the job I need

**Priority:** P0 (Must Have)  
**Story Points:** 3  
**Sprint:** 2

#### Acceptance Criteria
- [ ] Search bar at top of job list
- [ ] Real-time filtering as user types
- [ ] Case-insensitive search
- [ ] Highlights matching text
- [ ] "No results" message when no matches

---

### US-09: View Job Details
**As a** user  
**I want to** view detailed information about a job  
**So that** I can understand the job before triggering

**Priority:** P1 (Should Have)  
**Story Points:** 3  
**Sprint:** 3

#### Acceptance Criteria
- [ ] Tap on job opens detail view
- [ ] Shows job name, description, URL
- [ ] Shows last build number and status
- [ ] Shows job parameters (if any)
- [ ] Shows health report
- [ ] Link to open in browser

---

### US-10: Mark Jobs as Favorites
**As a** user  
**I want to** mark frequently used jobs as favorites  
**So that** I can access them quickly

**Priority:** P2 (Nice to Have)  
**Story Points:** 2  
**Sprint:** 4

#### Acceptance Criteria
- [ ] Star icon to toggle favorite status
- [ ] Favorites section at top of job list
- [ ] Favorites persisted locally
- [ ] Favorites synced per server

---

### US-11: View Job Build History
**As a** user  
**I want to** view the build history of a job  
**So that** I can see past build results and trends

**Priority:** P1 (Should Have)  
**Story Points:** 3  
**Sprint:** 3

#### Acceptance Criteria
- [ ] Build history list in job details
- [ ] Shows last 20 builds by default
- [ ] Each build shows number, status, timestamp
- [ ] Tap on build shows build details
- [ ] Load more pagination

---

## EP-03: Build Triggering

### US-12: Trigger Job with One Tap
**As a** user  
**I want to** trigger a Jenkins job with one tap  
**So that** I can quickly start builds without navigating through menus

**Priority:** P0 (Must Have)  
**Story Points:** 5  
**Sprint:** 3

#### Acceptance Criteria
- [ ] "Build" button prominently displayed
- [ ] Confirmation dialog before triggering
- [ ] Loading state during API call
- [ ] Success toast on successful trigger
- [ ] Error message on failure with retry option
- [ ] Haptic feedback on trigger

#### Technical Notes
- Use `/job/{jobName}/build` for parameterless jobs
- Handle queue response and return queue ID

---

### US-13: Trigger Build with Parameters
**As a** user  
**I want to** pass parameters before triggering a build  
**So that** I can customize the build execution

**Priority:** P0 (Must Have)  
**Story Points:** 8  
**Sprint:** 3

#### Acceptance Criteria
- [ ] Parameter form shown for parameterized jobs
- [ ] Supports text, choice, boolean, password parameters
- [ ] Default values pre-populated
- [ ] Required parameters validated
- [ ] Parameter descriptions shown as hints
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
**As a** user  
**I want to** see the current build status  
**So that** I can know if builds are passing or failing

**Priority:** P0 (Must Have)  
**Story Points:** 5  
**Sprint:** 3

#### Acceptance Criteria
- [ ] Status indicator (icon + color) for each build
- [ ] Status types: Success, Failure, Unstable, Running, Aborted, Not Built
- [ ] Last build timestamp shown
- [ ] Duration of build shown

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
**As a** user  
**I want to** see build progress percentage  
**So that** I can estimate when the build will complete

**Priority:** P1 (Should Have)  
**Story Points:** 3  
**Sprint:** 4

#### Acceptance Criteria
- [ ] Progress bar for running builds
- [ ] Percentage based on estimated vs elapsed time
- [ ] "Estimating..." for first builds
- [ ] Updates every 5 seconds

#### Technical Notes
- Use `estimatedDuration` and `timestamp` from build API

---

### US-19: View Build Logs
**As a** user  
**I want to** view build logs  
**So that** I can debug failed builds without opening a browser

**Priority:** P1 (Should Have)  
**Story Points:** 5  
**Sprint:** 4

#### Acceptance Criteria
- [ ] Console output in scrollable view
- [ ] Last 500 lines by default
- [ ] Load more option for full logs
- [ ] Syntax highlighting for common patterns
- [ ] Copy log to clipboard
- [ ] Share log via iOS share sheet

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

### US-25: App Settings Screen
**As a** user  
**I want to** access app settings  
**So that** I can customize the app behavior

**Priority:** P1 (Should Have)  
**Story Points:** 3  
**Sprint:** 4

#### Acceptance Criteria
- [x] Settings accessible from tab bar or menu
- [x] Grouped settings with clear labels
- [x] Changes applied immediately

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
| 1.0 | Feb 7, 2026 | laTrigger Team | Initial user stories |
