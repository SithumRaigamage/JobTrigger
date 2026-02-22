# Azure Pipelines API Specification

## Overview
Azure Pipelines is a cloud service that you can use to automatically build and test your code project and make it available to other users. It works with just about any language or project type.

## Base URL
`https://dev.azure.com/{organization}/{project}/_apis`

## Authentication
Personal Access Token (PAT).
Header: `Authorization: Basic <BASE64_USER:PAT>`

## Key Endpoints

### 1. List Definitions (Pipelines)
Get a list of build definitions.
`GET /build/definitions?api-version=7.0`

### 2. List Builds
Retrieve a list of builds for the project.
`GET /build/builds?api-version=7.0`

### 3. Queue a Build
Triggers a new build run.
`POST /build/builds?api-version=7.0`

**Body**:
```json
{
  "definition": { "id": 123 },
  "sourceBranch": "refs/heads/main"
}
```

### 4. Get Build Details
Get specific details for a build run.
`GET /build/builds/{buildId}?api-version=7.0`

### 5. Get Build Logs
Retrieves the logs for a specific build.
`GET /build/builds/{buildId}/logs?api-version=7.0`

## Data Mapping for JobTrigger
| JobTrigger Field | Azure Pipelines Mapping |
|------------------|-------------------------|
| Job Name         | Definition Name         |
| Build Number     | Build ID / Build Number |
| Status           | Result (succeeded, failed, canceled) |
| Duration         | finishTime - startTime  |
