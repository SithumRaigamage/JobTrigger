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
    // Check for existing token
    if let token = KeychainHelper.shared.retrieve(for: "jwt_token") {
      // In a real app, we'd verify the token or fetch the user profile here
      self.isAuthenticated = true
      // Try to load user from cache
      if let userData = UserDefaults.standard.data(forKey: "current_user"),
        let user = try? JSONDecoder().decode(User.self, from: userData)
      {
        self.currentUser = user
      }
    }
  }

  // MARK: - Public Methods

  func setAuthenticatedUser(_ user: User, token: String) {
    KeychainHelper.shared.save(token, for: "jwt_token")
    if let encodedUser = try? JSONEncoder().encode(user) {
      UserDefaults.standard.set(encodedUser, forKey: "current_user")
    }

    DispatchQueue.main.async {
      self.currentUser = user
      self.isAuthenticated = true
    }
  }

  func signOut() {
    KeychainHelper.shared.delete(for: "jwt_token")
    UserDefaults.standard.removeObject(forKey: "current_user")

    DispatchQueue.main.async {
      self.currentUser = nil
      self.isAuthenticated = false
    }
  }
}
