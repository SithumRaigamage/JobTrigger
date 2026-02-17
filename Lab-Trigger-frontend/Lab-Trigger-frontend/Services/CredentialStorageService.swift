//
//  CredentialStorageService.swift
//  Lab-Trigger-frontend
//
//  Created by Sithum Raigamage on 2026-02-08.
//

import Foundation

// MARK: - Storage Service Protocol

protocol CredentialStorageProtocol {
  func save(_ credentials: JenkinsCredentials) async throws -> JenkinsCredentials
  func loadAll() async throws -> [JenkinsCredentials]
  func delete(_ id: String) async throws
}

// MARK: - Backend Credential Storage Service

/// Service for storing credentials in the Node.js backend
final class CredentialStorageService: CredentialStorageProtocol {

  // MARK: - Singleton
  static let shared = CredentialStorageService()
  private init() {}

  // MARK: - Public Methods

  /// Save credentials (adds new or updates existing)
  func save(_ credentials: JenkinsCredentials) async throws -> JenkinsCredentials {
    let data = try JSONEncoder().encode(credentials)

    if credentials.id.isEmpty || credentials.id.count < 10 {  // New credential (placeholder ID)
      return try await BackendClient.shared.request(
        APIConfig.Credentials.base,
        method: "POST",
        body: data
      )
    } else {
      return try await BackendClient.shared.request(
        APIConfig.Credentials.forId(credentials.id),
        method: "PUT",
        body: data
      )
    }
  }

  /// Load all saved credentials
  func loadAll() async throws -> [JenkinsCredentials] {
    return try await BackendClient.shared.request(APIConfig.Credentials.base)
  }

  /// Delete a credential
  func delete(_ id: String) async throws {
    let _: EmptyResponse = try await BackendClient.shared.request(
      APIConfig.Credentials.forId(id),
      method: "DELETE"
    )
  }
}
