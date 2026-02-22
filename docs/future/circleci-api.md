# CircleCI API Specification

## Overview
CircleCI is a cloud-native CI/CD platform that helps teams build, test, and deploy software across multiple platforms. JobTrigger will integrate with the v2 API to track pipeline and workflow statuses.

## Base URL
`https://circleci.com/api/v2`

## Authentication
Personal API Token.
Header: `Circle-Token: <TOKEN>`

## Key Endpoints

### 1. List Pipelines
Get a list of pipelines for a specific project.
`GET /project/{project-slug}/pipeline`

### 2. Get Pipeline Details
Get details about a specific pipeline.
`GET /pipeline/{pipeline-id}`

### 3. List Workflows for a Pipeline
Retrieves workflows associated with a pipeline.
`GET /pipeline/{pipeline-id}/workflow`

### 4. Trigger a New Pipeline
Starts a new pipeline run.
`POST /project/{project-slug}/pipeline`

**Body**:
```json
{
  "branch": "feature-branch",
  "parameters": {
    "run_extra_tests": true
  }
}
```

### 5. Get Job Logs
Retrieves output for a specific job step.
`GET /project/{project-slug}/job/{job-number}/artifacts` (and step output sub-routes)

## Data Mapping for JobTrigger
| JobTrigger Field | CircleCI Mapping |
|------------------|------------------|
| Job Name         | Project Slug / Workflow Name |
| Build Number     | Pipeline Number  |
| Status           | Workflow Status (success, failed, on_hold) |
| Duration         | workflow.duration_ms |
