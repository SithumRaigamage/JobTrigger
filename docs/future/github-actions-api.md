# GitHub Actions API Specification

## Overview
GitHub Actions allows you to automate, customize, and execute your software development workflows right in your repository. For JobTrigger, we will focus on listing workflows, viewing run statuses, and triggering manual `workflow_dispatch` events.

## Base URL
`https://api.github.com`

## Authentication
Personal Access Token (PAT) or GitHub App Token.
Header: `Authorization: Bearer <TOKEN>`
Header: `Accept: application/vnd.github+json`

## Key Endpoints

### 1. List Workflows
Retrieves a list of workflows for a repository.
`GET /repos/{owner}/{repo}/actions/workflows`

### 2. Get Workflow Runs
List all workflow runs for a repository.
`GET /repos/{owner}/{repo}/actions/runs`

### 3. Create a workflow dispatch event
Triggers a manual workflow run.
`POST /repos/{owner}/{repo}/actions/workflows/{workflow_id}/dispatches`

**Body**:
```json
{
  "ref": "main",
  "inputs": {
    "name": "Value"
  }
}
```

### 4. Get a workflow run
Get details of a specific run.
`GET /repos/{owner}/{repo}/actions/runs/{run_id}`

### 5. Get workflow run logs
Download logs for a run.
`GET /repos/{owner}/{repo}/actions/runs/{run_id}/logs`

## Data Mapping for JobTrigger
| JobTrigger Field | GitHub Actions Mapping |
|------------------|------------------------|
| Job Name         | Workflow Name          |
| Build Number     | Run Number             |
| Status           | Conclusion (success, failure, etc.) |
| Duration         | updated_at - run_started_at |
