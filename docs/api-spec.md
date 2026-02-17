# JobTrigger API Specification

## 1. Overview
JobTrigger utilizes a hybrid API architecture:
1. **Management API**: A Node.js + MongoDB backend handles user authentication and Jenkins credential synchronization.
2. **Execution API**: The mobile client interacts directly with Jenkins servers using credentials retrieved from the Management API.

---

## 2. Management API (Node.js)

**Base URL:** `http://127.0.0.1:5001/api`

### 2.1 Authentication

#### POST /auth/signup
Registers a new user.
- **Body**: `{ "email": "user@example.com", "password": "securepassword" }`
- **Response**: `200 OK` with JWT token in `x-auth-token` header.

#### POST /auth/login
Authenticates an existing user.
- **Body**: `{ "email": "user@example.com", "password": "securepassword" }`
- **Response**: `200 OK` with JWT token in `x-auth-token` header.

### 2.2 Credentials Management
*Requires `x-auth-token` header*

#### GET /credentials
Retrieves all saved Jenkins server configurations for the authenticated user.

#### POST /credentials
Saves a new Jenkins server configuration.
- **Body**: `{ "name": "Prod", "url": "...", "username": "...", "password": "...", "token": "..." }`

#### PUT /credentials/:id
Updates an existing configuration.

#### DELETE /credentials/:id
Removes a configuration.

---

## 3. Execution API (Jenkins Direct)

The app interacts with Jenkins using standard REST endpoints.

### 3.1 Fetch Jobs
**URL:** `{SERVER_URL}/api/json?tree=jobs[name,url,color]`
**Method:** `GET`
**Auth:** Basic (Base64 encoded `username:api_token`)

### 3.2 Trigger Build
**URL:** `{SERVER_URL}/job/{JOB_PATH}/buildWithParameters`
**Method:** `POST`
**Query Params:** `token={PARAM_TOKEN}` (if configured)

---

## 4. Security
- **JWT**: Used for all management requests. Stored in iOS Keychain.
- **Basic Auth**: Used for direct Jenkins requests. Sent over HTTPS only.
- **Encryption**: Passwords are hashed with Bcrypt on the backend.

**Last Updated:** 2026-02-17