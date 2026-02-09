//
//  AuthService.swift
//  Lab-Trigger-frontend
//
//  Created on 2026-02-09.
//

import Foundation

/// Service for handling user authentication and persistence
/// ⚠️ WARNING: This uses JSON file storage and plaintext passwords for development.
final class AuthService {

  // MARK: - Properties

  private let folderName = "Resources"
  private let fileName = "users.json"

  private var projectSourceDirectory: URL {
    let currentFile = URL(fileURLWithPath: #file)
    return
      currentFile
      .deletingLastPathComponent()  // Remove AuthService.swift
      .deletingLastPathComponent()  // Remove Services/
  }

  private var storageDirectory: URL {
    return projectSourceDirectory.appendingPathComponent(folderName, isDirectory: true)
  }

  private var fileURL: URL {
    return storageDirectory.appendingPathComponent(fileName)
  }

  // MARK: - Singleton

  static let shared = AuthService()

  private init() {}

  // MARK: - Public Methods

  /// Register a new user
  func signup(user: User) throws {
    var users = loadAllUsers()

    // Check if user already exists
    if users.contains(where: { $0.email.lowercased() == user.email.lowercased() }) {
      throw AuthError.userAlreadyExists
    }

    users.append(user)
    try saveAllUsers(users)
  }

  /// Login with email and password
  func login(email: String, password: String) -> User? {
    let users = loadAllUsers()
    return users.first(where: {
      $0.email.lowercased() == email.lowercased() && $0.password == password
    })
  }

  /// Load all users from JSON
  func loadAllUsers() -> [User] {
    guard FileManager.default.fileExists(atPath: fileURL.path) else {
      return []
    }

    do {
      let data = try Data(contentsOf: fileURL)
      let decoder = JSONDecoder()
      return try decoder.decode([User].self, from: data)
    } catch {
      print("❌ Auth Service: Error loading users: \(error)")
      return []
    }
  }

  // MARK: - Private Methods

  private func saveAllUsers(_ users: [User]) throws {
    // Ensure storage folder exists
    let fileManager = FileManager.default
    if !fileManager.fileExists(atPath: storageDirectory.path) {
      try fileManager.createDirectory(
        at: storageDirectory,
        withIntermediateDirectories: true
      )
    }

    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

    let data = try encoder.encode(users)
    try data.write(to: fileURL, options: [.atomicWrite])
  }
}

// MARK: - Auth Error
enum AuthError: LocalizedError {
  case userAlreadyExists
  case invalidCredentials
  case storageError

  var errorDescription: String? {
    switch self {
    case .userAlreadyExists: return "A user with this email already exists."
    case .invalidCredentials: return "Invalid email or password."
    case .storageError: return "Could not save user data."
    }
  }
}
