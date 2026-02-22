# SonarQube API Specification

## Overview
SonarQube is a self-managed, automatic code review tool that systematically helps you deliver clean code. For JobTrigger, we will focus on fetching code quality metrics (Bugs, Vulnerabilities, Coverage) to display in the user profile or job details.

## Base URL
`https://your-sonarqube-instance/api`

## Authentication
User Token.
Header: `Authorization: Basic <BASE64_TOKEN:>` (Token followed by a colon, then base64 encoded)

## Key Endpoints

### 1. Search Components
Find a project or component by its key.
`GET /components/search?qualifiers=TRK`

### 2. Get Component Measures
Retrieves metrics for a specific project.
`GET /measures/component?component={project_key}&metricKeys=bugs,vulnerabilities,code_smells,coverage,security_rating,reliability_rating`

### 3. Get Quality Gate Status
Check if a project passed its quality gate.
`GET /qualitygates/project_status?projectKey={project_key}`

### 4. List Issues
Find bugs or vulnerabilities.
`GET /issues/search?componentKeys={project_key}&types=BUG,VULNERABILITY`

## Data Mapping for JobTrigger
| JobTrigger Field | SonarQube Mapping |
|------------------|-------------------|
| Status Health    | Quality Gate Status (OK, ERROR) |
| Score/Metric     | Reliability/Security Rating (A-E) |
| Counts           | Number of Bugs, Vulnerabilities |
| Percentage       | Code Coverage % |
