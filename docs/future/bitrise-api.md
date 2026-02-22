# Bitrise API Specification

## Overview
Bitrise is a Continuous Integration and Delivery (CI/CD) Platform as a Service (PaaS) with a main focus on mobile app development. JobTrigger will integrate with Bitrise to provide a native mobile CI/CD experience.

## Base URL
`https://api.bitrise.io/v0.1`

## Authentication
Personal Access Token.
Header: `Authorization: <TOKEN>`

## Key Endpoints

### 1. List Apps
Get a list of apps for the authenticated user.
`GET /apps`

### 2. List Builds for an App
Retrieve builds for a specific app.
`GET /apps/{app_slug}/builds`

### 3. Trigger a Build
Triggers a new build for an app.
`POST /apps/{app_slug}/builds`

**Body**:
```json
{
  "hook_info": { "type": "bitrise" },
  "build_params": {
    "branch": "master",
    "workflow_id": "primary"
  }
}
```

### 4. Get Build Log
Retrieves the log for a specific build.
`GET /apps/{app_slug}/builds/{build_slug}/log`

### 5. Abort a Build
Stops a running build.
`POST /apps/{app_slug}/builds/{build_slug}/abort`

## Data Mapping for JobTrigger
| JobTrigger Field | Bitrise Mapping |
|------------------|-----------------|
| Job Name         | App Title / Workflow ID |
| Build Number     | Build Number    |
| Status           | Status (1=success, 2=error, 0=on-hold) |
| URL              | Public Install Page URL |
