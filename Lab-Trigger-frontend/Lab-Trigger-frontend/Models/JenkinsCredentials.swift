//
//  JenkinsCredentials.swift
//  Lab-Trigger-frontend
//
//  Created on 2026-02-08.
//

import Foundation

/// Represents Jenkins server credentials
struct JenkinsCredentials: Codable, Identifiable, Equatable {
  var id: String
  var serverName: String
  var jenkinsURL: String
  var username: String
  var password: String
  var paramToken: String
  var isDefault: Bool
  var createdAt: Date
  var updatedAt: Date

  enum CodingKeys: String, CodingKey {
    case id = "_id"
    case serverName
    case jenkinsURL
    case username
    case password
    case paramToken
    case isDefault
    case createdAt
    case updatedAt
  }

  init(
    id: String = UUID().uuidString,
    serverName: String = "",
    jenkinsURL: String = "",
    username: String = "",
    password: String = "",
    paramToken: String = "",
    isDefault: Bool = false,
    createdAt: Date = Date(),
    updatedAt: Date = Date()
  ) {
    self.id = id
    self.serverName = serverName
    self.jenkinsURL = jenkinsURL
    self.username = username
    self.password = password
    self.paramToken = paramToken
    self.isDefault = isDefault
    self.createdAt = createdAt
    self.updatedAt = updatedAt
  }

}

// MARK: - Validation Extension
extension JenkinsCredentials {
  /// Validates that all required fields are filled
  var isValid: Bool {
    !jenkinsURL.isEmpty && !username.isEmpty && !password.isEmpty
  }

  /// Returns validation errors if any
  var validationErrors: [String] {
    var errors: [String] = []

    if jenkinsURL.isEmpty {
      errors.append("Jenkins URL is required")
    } else if !jenkinsURL.hasPrefix("http://") && !jenkinsURL.hasPrefix("https://") {
      errors.append("Jenkins URL must start with http:// or https://")
    }

    if username.isEmpty {
      errors.append("Username is required")
    }

    if password.isEmpty {
      errors.append("Password is required")
    }

    return errors
  }
}
