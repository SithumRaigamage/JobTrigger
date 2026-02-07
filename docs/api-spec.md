# Jenkins Job Trigger API Specification

## Overview
This API endpoint triggers a Jenkins CI pipeline with parameters for building and deploying applications.

## Endpoint Details

**URL:** `http://localhost:8080/job/Projects/job/Hello-World-Node-JS/job/CI/job/CI-Pipleine/buildWithParameters`

**Method:** `POST`

**Authentication:** Basic Auth (Base64 encoded)

**Token:** `sithum`

---

## Headers

| Header | Value | Required |
|--------|-------|----------|
| `Content-Type` | `application/x-www-form-urlencoded` | Yes |
| `Authorization` | `Basic <base64_credentials>` | Yes |

---

## Parameters

| Parameter | Type | Description | Example Value |
|-----------|------|-------------|---------------|
| `RELEASE_VERSION` | string | Version number for the release | `1.0.4` |
| `ENVIRONMENT` | string | Target deployment environment | `dev`, `staging`, `prod` |
| `BRANCH` | string | Git branch to build from | `main`, `develop`, `feature/xyz` |
| `GIT_REPO_URL` | string | Git repository URL | `https://github.com/user-name/repo-name.git` |
| `SEND_EMAIL` | boolean | Send email notification after build | `true`, `false` |

---

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
const formData = new URLSearchParams();
formData.append('RELEASE_VERSION', '1.0.4');
formData.append('ENVIRONMENT', 'dev');
formData.append('BRANCH', 'main');
formData.append('GIT_REPO_URL', 'https://github.com/user-name/repo-name.git');
formData.append('SEND_EMAIL', 'true');

fetch('http://localhost:8080/job/Projects/job/Hello-World-Node-JS/job/CI/job/CI-Pipleine/buildWithParameters?token=sithum', {
  method: 'POST',
  headers: {
    'Content-Type': 'application/x-www-form-urlencoded',
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
headers = {
    "Content-Type": "application/x-www-form-urlencoded",
    "Authorization": "Basic U2l0aHVtOjExYjdlYmU2YmIwMDVhMTRhMTNkNzU0MmVlNDE4k="
}
params = {
    "token": "sithum"
}
data = {
    "RELEASE_VERSION": "1.0.4",
    "ENVIRONMENT": "dev",
    "BRANCH": "main",
    "GIT_REPO_URL": "https://github.com/user-name/repo-name.git",
    "SEND_EMAIL": "true"
}

response = requests.post(url, headers=headers, params=params, data=data)
print(response.status_code)
print(response.text)
```

---

## Response

### Success Response
**Status Code:** `201 Created` or `200 OK`

Jenkins will queue the build job and return a response indicating the job has been triggered successfully.

### Error Responses

| Status Code | Description |
|-------------|-------------|
| `401 Unauthorized` | Invalid credentials or authentication token |
| `403 Forbidden` | User doesn't have permission to trigger the job |
| `404 Not Found` | Job or pipeline doesn't exist |
| `500 Internal Server Error` | Jenkins server error |

---

## Notes

⚠️ **Security Reminder:** 
- Never commit actual credentials to version control
- Use environment variables or secure credential management systems
- Rotate tokens and passwords regularly
- The Authorization header contains sensitive credentials (currently visible in this example)

📝 **Usage Tips:**
- Ensure Jenkins is running and accessible at the specified URL
- Verify the job path matches your Jenkins folder structure
- Test with `SEND_EMAIL="false"` during development to avoid spam
- Use appropriate environment values based on your deployment pipeline
