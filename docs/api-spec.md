# Jenkins Job Trigger API Specification

## Overview
This API endpoint allows you to trigger a Jenkins CI/CD pipeline with custom parameters for building and deploying your application.

## Endpoint Details

**URL:** `http://localhost:8080/job/Projects/job/Hello-World-Node-JS/job/CI/job/CI-Pipleine/buildWithParameters`

**Method:** `POST`

**Authentication:** Basic Authentication (required)

**Query Parameters:**
- `token` (required): Authentication token for triggering the build
  - Example: `sithum`

## Request Headers

| Header | Value | Required |
|--------|-------|----------|
| Content-Type | `application/x-www-form-urlencoded` | Yes |
| Authorization | `Basic <base64-encoded-credentials>` | Yes |

## Form Parameters

| Parameter | Type | Description | Example | Required |
|-----------|------|-------------|---------|----------|
| RELEASE_VERSION | string | Version number for the release | `1.0.4` | Yes |
| ENVIRONMENT | string | Target deployment environment | `dev`, `staging`, `prod` | Yes |
| BRANCH | string | Git branch to build from | `main`, `develop`, `feature/*` | Yes |
| GIT_REPO_URL | string | Full URL of the Git repository | `https://github.com/user-name/repo-name.git` | Yes |
| SEND_EMAIL | boolean | Whether to send email notifications | `true`, `false` | No |

## Example Request

### cURL

```bash
curl --location 'http://localhost:8080/job/Projects/job/Hello-World-Node-JS/job/CI/job/CI-Pipleine/buildWithParameters?token=sithum' \
  --header 'Content-Type: application/x-www-form-urlencoded' \
  --header 'Authorization: Basic U2l0aHVtOjExYjdlYmU2YmIwMDVhMTRhMTNkNzU0MmVlNDE4k=' \
  --form 'RELEASE_VERSION="1.0.4"' \
  --form 'ENVIRONMENT="dev"' \
  --form 'BRANCH="main"' \
  --form 'GIT_REPO_URL="https://github.com/user-name/repo-name.git"' \
  --form 'SEND_EMAIL="true"'
```

### JavaScript (Fetch)

```javascript
const formData = new FormData();
formData.append('RELEASE_VERSION', '1.0.4');
formData.append('ENVIRONMENT', 'dev');
formData.append('BRANCH', 'main');
formData.append('GIT_REPO_URL', 'https://github.com/user-name/repo-name.git');
formData.append('SEND_EMAIL', 'true');

fetch('http://localhost:8080/job/Projects/job/Hello-World-Node-JS/job/CI/job/CI-Pipleine/buildWithParameters?token=sithum', {
  method: 'POST',
  headers: {
    'Authorization': 'Basic U2l0aHVtOjExYjdlYmU2YmIwMDVhMTRhMTNkNzU0MmVlNDE4k='
  },
  body: formData
})
.then(response => response.json())
.then(data => console.log(data))
.catch(error => console.error('Error:', error));
```

### Python (Requests)

```python
import requests

url = "http://localhost:8080/job/Projects/job/Hello-World-Node-JS/job/CI/job/CI-Pipleine/buildWithParameters"
params = {"token": "sithum"}
headers = {
    "Authorization": "Basic U2l0aHVtOjExYjdlYmU2YmIwMDVhMTRhMTNkNzU0MmVlNDE4k="
}
data = {
    "RELEASE_VERSION": "1.0.4",
    "ENVIRONMENT": "dev",
    "BRANCH": "main",
    "GIT_REPO_URL": "https://github.com/user-name/repo-name.git",
    "SEND_EMAIL": "true"
}

response = requests.post(url, params=params, headers=headers, data=data)
print(response.status_code)
```

## Response

Jenkins typically returns a `201 Created` status code when a build is successfully queued.

**Success Response:**
- **Status Code:** 201
- **Headers:** Location header containing the queue item URL

## Security Notes

⚠️ **Important Security Considerations:**

1. **Never commit credentials** to version control
2. Store the Authorization token and API credentials in environment variables or secure vaults
3. Use HTTPS in production environments instead of HTTP
4. Rotate API tokens regularly
5. Implement IP whitelisting for additional security

## Environment-Specific Configuration

| Environment | Recommended Settings |
|-------------|---------------------|
| `dev` | Frequent builds, all notifications enabled |
| `staging` | Pre-production testing, selective notifications |
| `prod` | Manual approvals, critical notifications only |

## Troubleshooting

### Common Issues

1. **401 Unauthorized:** Check your Authorization header and token parameter
2. **404 Not Found:** Verify the Jenkins job path is correct
3. **403 Forbidden:** Ensure the user has build permissions for this job
4. **Build not triggered:** Check Jenkins job configuration for required parameters

---

**Last Updated:** 2026-02-07