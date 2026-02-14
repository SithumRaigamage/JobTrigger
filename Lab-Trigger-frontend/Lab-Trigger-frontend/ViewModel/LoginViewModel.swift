//
//  LoginViewModel.swift
//  Lab-Trigger-frontend
//
//  Created on 2026-02-09.
//

import Combine
import Foundation

final class LoginViewModel: ObservableObject {

  // MARK: - Form Data
  @Published var email = ""
  @Published var password = ""

  // MARK: - UI State
  @Published var isLoading = false
  @Published var errorMessage: String?
  @Published var showSignup = false

  // MARK: - Services
  private let authService = AuthService.shared
  private let authManager = AuthenticationManager.shared

  // MARK: - Public Methods

  func login() {
    guard validateForm() else { return }

    isLoading = true
    errorMessage = nil

    // Simulate a small delay for UI feedback
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
      guard let self = self else { return }

      if let user = self.authService.login(email: self.email, password: self.password) {
        self.authManager.setAuthenticatedUser(user)
        NotificationManager.shared.show(
          type: .success, title: "Welcome back!", message: "Successfully signed in.")
        self.isLoading = false
      } else {
        NotificationManager.shared.show(
          type: .error, title: "Login Failed", message: "Invalid email or password.")
        self.isLoading = false
      }
    }
  }

  // MARK: - Private Methods

  private func validateForm() -> Bool {
    if email.isEmpty || password.isEmpty {
      NotificationManager.shared.show(
        type: .warning, title: "Missing Info", message: "Please fill in all fields.")
      return false
    }

    if !email.contains("@") || !email.contains(".") {
      NotificationManager.shared.show(
        type: .warning, title: "Invalid Email", message: "Please enter a valid email address.")
      return false
    }

    return true
  }
}
