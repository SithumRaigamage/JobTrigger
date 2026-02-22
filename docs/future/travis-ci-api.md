# Travis CI API Specification

## Overview
Travis CI is a hosted continuous integration service used to build and test software projects hosted at GitHub and Bitbucket. While its popularity has shifted towards other tools, it remains a key integration for many open-source projects.

## Base URL
- `https://api.travis-ci.com` (Main)
- `https://api.travis-ci.org` (Legacy Open Source)

## Authentication
API Token.
Header: `Travis-API-Version: 3`
Header: `Authorization: token <TOKEN>`

## Key Endpoints

### 1. List Repositories
Get a list of repositories for the authenticated user.
`GET /repos`

### 2. Get Builds for a Repository
Retrieve builds for a specific repository.
`GET /repo/{repository_id_or_slug}/builds`

### 3. Get Specific Build
Get details of a specific build.
`GET /build/{build_id}`

### 4. Trigger a Build (Request)
Triggers a new build request.
`POST /repo/{repository_id_or_slug}/requests`

**Body**:
```json
{
  "request": {
    "branch": "master",
    "message": "Manual trigger from JobTrigger iOS"
  }
}
```

### 5. Restart a Build
Restarts a previously executed build.
`POST /build/{build_id}/restart`

### 6. Get Job Logs
Retrieves the log output for a specific job.
`GET /job/{job_id}/log`

## Data Mapping for JobTrigger
| JobTrigger Field | Travis CI Mapping |
|------------------|-------------------|
| Job Name         | Repository Name / Branch |
| Build Number     | Build Number      |
| Status           | State (passed, failed, errored, started) |
| Duration         | duration (in seconds) |
