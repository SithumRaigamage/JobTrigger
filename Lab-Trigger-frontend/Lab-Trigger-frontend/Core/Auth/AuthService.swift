//
//  AuthService.swift
//  Lab-Trigger-frontend
//
//  Created on 2026-02-09.
//

import Foundation

/// Service for handling user authentication via the Node.js backend
final class AuthService {

  // MARK: - Singleton
  static let shared = AuthService()
  private init() {}

  // MARK: - Public Methods

  /// Register a new user
  func signup(email: String, password: String) async throws -> AuthResponse {
    let body = ["email": email, "password": password]
    let data = try JSONEncoder().encode(body)

    return try await BackendClient.shared.request(
      APIConfig.Auth.signup,
      method: "POST",
      body: data,
      requiresAuth: false
    )
  }

  /// Login with email and password
  func login(email: String, password: String) async throws -> AuthResponse {
    let body = ["email": email, "password": password]
    let data = try JSONEncoder().encode(body)

    return try await BackendClient.shared.request(
      APIConfig.Auth.login,
      method: "POST",
      body: data,
      requiresAuth: false
    )
  }
}

// MARK: - Models

struct AuthResponse: Decodable {
  let token: String
  let user: User
}
