//
//  SignupViewModel.swift
//  Lab-Trigger-frontend
//
//  Created on 2026-02-09.
//

import Combine
import Foundation

final class SignupViewModel: ObservableObject {

  // MARK: - Form Data
  @Published var email = ""
  @Published var password = ""
  @Published var confirmPassword = ""

  // MARK: - UI State
  @Published var isLoading = false
  @Published var errorMessage: String?
  @Published var isSuccess = false

  // MARK: - Services
  private let authService = AuthService.shared
  private let authManager = AuthenticationManager.shared

  // MARK: - Public Methods

  func signup() {
    guard validateForm() else { return }

    isLoading = true
    errorMessage = nil

    // Simulate a small delay for UI feedback
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
      guard let self = self else { return }

      let newUser = User(email: self.email, password: self.password)

      do {
        try self.authService.signup(user: newUser)
        self.authManager.setAuthenticatedUser(newUser)
        NotificationManager.shared.show(
          type: .success, title: "Success", message: "Account created successfully.")
        self.isSuccess = true
        self.isLoading = false
      } catch {
        NotificationManager.shared.show(
          type: .error, title: "Signup Failed", message: error.localizedDescription)
        self.isLoading = false
      }
    }
  }

  // MARK: - Private Methods

  private func validateForm() -> Bool {
    if email.isEmpty || password.isEmpty || confirmPassword.isEmpty {
      NotificationManager.shared.show(
        type: .warning, title: "Missing Info", message: "Please fill in all fields.")
      return false
    }

    if !email.contains("@") || !email.contains(".") {
      NotificationManager.shared.show(
        type: .warning, title: "Invalid Email", message: "Please enter a valid email address.")
      return false
    }

    if password.count < 6 {
      NotificationManager.shared.show(
        type: .warning, title: "Weak Password",
        message: "Password must be at least 6 characters long.")
      return false
    }

    if password != confirmPassword {
      NotificationManager.shared.show(
        type: .warning, title: "Mismatch", message: "Passwords do not match.")
      return false
    }

    return true
  }
}
