//
//  AuthenticationManager.swift
//  Lab-Trigger-frontend
//
//  Created on 2026-02-09.
//

import Combine
import Foundation

/// Manages the global authentication state of the application
final class AuthenticationManager: ObservableObject {

  // MARK: - Properties

  @Published var currentUser: User?
  @Published var isAuthenticated = false

  // MARK: - Singleton

  static let shared = AuthenticationManager()

  private init() {
    // For development: check if a user is already logged in (optional persistence)
    // We could store the user ID in UserDefaults
  }

  // MARK: - Public Methods

  func setAuthenticatedUser(_ user: User) {
    self.currentUser = user
    self.isAuthenticated = true
  }

  func signOut() {
    self.currentUser = nil
    self.isAuthenticated = false
  }
}
