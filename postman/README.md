# Jenkins Job Trigger - Postman Collection

This folder contains Postman collections and environments for testing the Jenkins Job Trigger API.

## Files

| File | Description |
|------|-------------|
| `Jenkins-JobTrigger.postman_collection.json` | Main API collection with all endpoints |
| `Jenkins-Local.postman_environment.json` | Environment for local development |
| `Jenkins-Production.postman_environment.json` | Environment for production server |

## Quick Start

### 1. Import the Collection

1. Open Postman
2. Click **Import** (top-left)
3. Drag and drop `Jenkins-JobTrigger.postman_collection.json` or click **Upload Files**
4. The collection will appear in your sidebar

### 2. Import the Environment

1. Click **Import** again
2. Import `Jenkins-Local.postman_environment.json` (for local development)
3. Click the environment dropdown (top-right) and select **Jenkins - Local Development**

### 3. Configure Your Credentials

1. Click the **eye icon** next to the environment dropdown
2. Click **Edit** on your environment
3. Update these variables:
   - `jenkins_username`: Your Jenkins username
   - `jenkins_api_token`: Your Jenkins API token (not your password!)
   - `jenkins_base_url`: Your Jenkins server URL
   - `job_path`: Path to your Jenkins job

### 4. Test the Connection

1. Expand **Server Information** folder
2. Run **Test Connection (Ping)**
3. If successful, you'll get a JSON response with server info

## Collection Structure

```
Jenkins Job Trigger API/
├── Build Triggers/
│   ├── Trigger Build with Parameters     # Main build trigger with all params
│   ├── Trigger Build - Development       # Pre-configured for dev environment
│   ├── Trigger Build - Staging           # Pre-configured for staging
│   ├── Trigger Build - Production        # Pre-configured for production
│   └── Trigger Build - Simple            # Build without parameters
│
├── Job Information/
│   ├── Get Job Info                       # Detailed job information
│   ├── Get Last Build Info                # Last build details
│   ├── Get Last Successful Build          # Last successful build
│   ├── Get Last Failed Build              # Last failed build
│   ├── Get Specific Build Info            # Build by number
│   └── Get Build Console Output           # Build logs
│
├── Queue Management/
│   ├── Get Queue Info                     # View build queue
│   ├── Get Queue Item                     # Specific queue item
│   └── Cancel Queued Build                # Cancel pending build
│
├── Build Control/
│   ├── Stop Running Build                 # Stop a build in progress
│   └── Delete Build                       # Remove build from history
│
└── Server Information/
    ├── Test Connection (Ping)             # Test server connectivity
    ├── Get All Jobs                       # List all jobs
    ├── Get Current User                   # Authenticated user info
    └── Get Crumb (CSRF Token)             # CSRF protection token
```

## Environment Variables

| Variable | Description | Example |
|----------|-------------|---------|
| `jenkins_base_url` | Base URL of Jenkins server | `http://localhost:8080` |
| `jenkins_username` | Your Jenkins username | `admin` |
| `jenkins_api_token` | Jenkins API token | `11b7ebe6bb005a14a...` |
| `build_token` | Build trigger token | `sithum` |
| `job_path` | Path to the Jenkins job | `Projects/job/MyProject/job/CI` |
| `git_repo_url` | Git repository URL | `https://github.com/user/repo.git` |
| `build_number` | Build number for queries | `42` |
| `queue_id` | Queue item ID | `123` |

## Getting Your Jenkins API Token

1. Log in to Jenkins
2. Click your username (top-right corner)
3. Click **Configure** in the left sidebar
4. Scroll to **API Token** section
5. Click **Add new Token**
6. Give it a name (e.g., "Postman")
7. Click **Generate**
8. **Copy the token immediately** (it won't be shown again!)

## Build Parameters

When triggering a build, you can customize these parameters:

| Parameter | Type | Description | Values |
|-----------|------|-------------|--------|
| `RELEASE_VERSION` | string | Version number | `1.0.0`, `2.1.3` |
| `ENVIRONMENT` | string | Target environment | `dev`, `staging`, `prod` |
| `BRANCH` | string | Git branch | `main`, `develop`, `feature/xyz` |
| `GIT_REPO_URL` | string | Repository URL | Full GitHub/GitLab URL |
| `SEND_EMAIL` | boolean | Send notifications | `true`, `false` |

## Security Best Practices

⚠️ **Important:**

1. **Never commit credentials** to version control
2. Use **HTTPS** in production environments
3. **Rotate API tokens** regularly
4. Use **IP whitelisting** when possible
5. Store sensitive values as **secret** type in Postman

## Troubleshooting

### 401 Unauthorized
- Check your username and API token
- Ensure the token hasn't expired
- Verify Basic Auth is enabled

### 403 Forbidden
- User doesn't have permission to trigger builds
- Check Jenkins security settings

### 404 Not Found
- Job path is incorrect
- Use `/api/json` to explore available jobs

### Build Not Starting
- Check if another build is running
- Verify all required parameters are provided
- Check Jenkins executor availability

## Response Codes

| Code | Meaning |
|------|---------|
| 200 | Success (GET requests) |
| 201 | Build queued successfully |
| 401 | Authentication failed |
| 403 | Permission denied |
| 404 | Job/build not found |
| 500 | Server error |

## Example: Trigger a Build

```bash
# Using cURL (for reference)
curl -X POST \
  "http://localhost:8080/job/Projects/job/MyApp/job/CI/buildWithParameters?token=mytoken" \
  -H "Authorization: Basic $(echo -n 'user:token' | base64)" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "RELEASE_VERSION=1.0.0" \
  -d "ENVIRONMENT=dev" \
  -d "BRANCH=main" \
  -d "GIT_REPO_URL=https://github.com/user/repo.git"
```

---

## Links

- [Jenkins REST API Documentation](https://www.jenkins.io/doc/book/using/remote-access-api/)
- [Postman Documentation](https://learning.postman.com/docs/getting-started/introduction/)

---

**Last Updated:** February 8, 2026
