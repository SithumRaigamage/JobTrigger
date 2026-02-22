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

  // MARK: - Validation State
  @Published var isEmailValid = true
  @Published var isPasswordValid = true
  @Published var passwordsMatch = true
  @Published var isFormValid = false
  @Published var showErrors = false

  // MARK: - Services
  private let authService = AuthService.shared
  private let authManager = AuthenticationManager.shared
  private var cancellables = Set<AnyCancellable>()

  // MARK: - Initialization

  init() {
    setupValidation()
  }

  // MARK: - Public Methods

  func signup() {
    showErrors = true
    guard validateForm() else { return }

    isLoading = true
    errorMessage = nil

    Task {
      do {
        let response = try await authService.signup(email: email, password: password)

        await MainActor.run {
          self.authManager.setAuthenticatedUser(response.user, token: response.token)
          NotificationManager.shared.show(
            type: .success, title: "Success", message: "Account created successfully.")
          self.isSuccess = true
          self.isLoading = false
        }
      } catch {
        await MainActor.run {
          NotificationManager.shared.show(
            type: .error, title: "Signup Failed", message: error.localizedDescription)
          self.isLoading = false
        }
      }
    }
  }

  // MARK: - Private Methods

  private func setupValidation() {
    // Email Validation
    $email
      .map { $0.contains("@") && $0.contains(".") }
      .assign(to: \.isEmailValid, on: self)
      .store(in: &cancellables)

    // Password Validation
    $password
      .map { $0.count >= 6 }
      .assign(to: \.isPasswordValid, on: self)
      .store(in: &cancellables)

    // Passwords Match
    Publishers.CombineLatest($password, $confirmPassword)
      .map { password, confirm in
        password == confirm || confirm.isEmpty
      }
      .assign(to: \.passwordsMatch, on: self)
      .store(in: &cancellables)

    // Global Form Validation
    Publishers.CombineLatest3($isEmailValid, $isPasswordValid, $passwordsMatch)
      .map { email, password, match in
        email && password && match && !self.email.isEmpty && !self.password.isEmpty
          && !self.confirmPassword.isEmpty
      }
      .assign(to: \.isFormValid, on: self)
      .store(in: &cancellables)
  }

  private func validateForm() -> Bool {
    if !isEmailValid {
      if showErrors {
        NotificationManager.shared.show(
          type: .warning, title: "Invalid Email", message: "Please enter a valid email address.")
      }
      return false
    }

    if !isPasswordValid {
      if showErrors {
        NotificationManager.shared.show(
          type: .warning, title: "Weak Password", message: "Password must be at least 6 characters."
        )
      }
      return false
    }

    if !passwordsMatch {
      if showErrors {
        NotificationManager.shared.show(
          type: .warning, title: "Mismatch", message: "Passwords do not match.")
      }
      return false
    }

    return isFormValid
  }
}
