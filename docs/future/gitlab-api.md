# GitLab CI/CD API Specification

## Overview
GitLab CI/CD is a tool built into GitLab for software development through the continuous methodologies. JobTrigger will integrate with the Pipeline API to monitor and trigger builds.

## Base URL
`https://gitlab.com/api/v4` (or self-hosted instance URL)

## Authentication
Personal Access Token.
Header: `PRIVATE-TOKEN: <TOKEN>`

## Key Endpoints

### 1. List Project Pipelines
Get a list of pipelines for a project.
`GET /projects/{id}/pipelines`

### 2. Get a single pipeline
Get details of a specific pipeline.
`GET /projects/{id}/pipelines/{pipeline_id}`

### 3. Create a new pipeline
Triggers a new pipeline run.
`POST /projects/{id}/pipeline`

**Query Parameters**:
- `ref`: The branch or tag to build.

### 4. List pipeline jobs
Get a list of jobs for a specific pipeline.
`GET /projects/{id}/pipelines/{pipeline_id}/jobs`

### 5. Get job log file
Retrieves the trace/log of a specific job.
`GET /projects/{id}/jobs/{job_id}/trace`

## Data Mapping for JobTrigger
| JobTrigger Field | GitLab CI Mapping |
|------------------|-------------------|
| Job Name         | Project Name      |
| Build Number     | Pipeline ID       |
| Status           | Status (success, failed, running) |
| Duration         | duration (in seconds) |
