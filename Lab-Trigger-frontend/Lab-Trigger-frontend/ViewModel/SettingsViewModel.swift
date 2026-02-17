//
//  SettingsViewModel.swift
//  Lab-Trigger-frontend
//
//  Created by Thamindu Dasanayake on 2026-02-08.
//

import Combine
import Foundation

final class SettingsViewModel: ObservableObject {

  // MARK: - Form Data
  @Published var serverName = ""
  @Published var jenkinsURL = ""
  @Published var username = ""
  @Published var password = ""
  @Published var paramToken = ""

  // MARK: - UI State
  @Published var isLoading = false
  @Published var showConnectionError = false
  @Published var alert: SettingsAlert?
  @Published var hasExistingCredentials = false
  @Published var connectionStatus: ConnectionStatus = .notTested
  @Published var isBackendConnected = true

  // MARK: - Services
  private let storageService = CredentialStorageService.shared
  private let apiService = JenkinsAPIService.shared

  // MARK: - Current Credentials
  private var currentCredentialID: String?

  // MARK: - Connection Status
  enum ConnectionStatus: Equatable {
    case notTested
    case testing
    case success(String)
    case failed(String)

    var message: String {
      switch self {
      case .notTested: return ""
      case .testing: return "Testing connection..."
      case .success(let msg): return msg
      case .failed(let msg): return msg
      }
    }
  }

  // MARK: - Initialization
  init() {
    Task {
      await loadExistingCredentials()
    }
  }

  // MARK: - Public Methods

  /// Load existing credentials from storage (Async)
  @MainActor
  func loadExistingCredentials() async {
    do {
      let all = try await storageService.loadAll()
      if let credentials = all.first(where: { $0.isDefault }) ?? all.first {
        currentCredentialID = credentials.id
        serverName = credentials.serverName
        jenkinsURL = credentials.jenkinsURL
        username = credentials.username
        password = credentials.password
        paramToken = credentials.paramToken
        hasExistingCredentials = true
      }
      isBackendConnected = true
    } catch {
      isBackendConnected = false
      print("❌ Settings View Model: Error loading credentials: \(error)")
      NotificationManager.shared.show(
        type: .error,
        title: "Loading Failed",
        message: "Failed to load existing server settings. Please check your connection."
      )
    }
  }

  /// Test the connection with current form values
  func testConnection() {
    guard validateForm() else { return }

    connectionStatus = .testing
    Task { @MainActor in
      let result = await apiService.testConnection(
        url: jenkinsURL,
        username: username,
        password: password,
        paramToken: paramToken
      )
      switch result {
      case .success(let connectionResult):
        connectionStatus = .success(connectionResult.message)
      case .failure(let error):
        connectionStatus = .failed(error.localizedDescription)
      }
    }
  }

  /// Save settings after validating connection
  func saveSettings() {
    guard validateForm() else {
      alert = .validationError(errors: currentCredentials.validationErrors)
      return
    }

    isLoading = true
    connectionStatus = .testing

    Task { @MainActor in
      let result = await apiService.testConnection(
        url: jenkinsURL,
        username: username,
        password: password,
        paramToken: paramToken
      )
      switch result {
      case .success(let connectionResult):
        connectionStatus = .success(connectionResult.message)
        // Save to backend
        do {
          let saved = try await storageService.save(currentCredentials)
          currentCredentialID = saved.id
          hasExistingCredentials = true
          isLoading = false
          alert = .success
        } catch {
          isLoading = false
          alert = .saveError(message: error.localizedDescription)
        }
      case .failure(let error):
        connectionStatus = .failed(error.localizedDescription)
        isLoading = false
        showConnectionError = true
      }
    }
  }

  /// Retry connection after error
  func retryConnection() {
    showConnectionError = false
    connectionStatus = .notTested
  }

  // MARK: - Private Methods

  private var currentCredentials: JenkinsCredentials {
    JenkinsCredentials(
      id: currentCredentialID ?? "",
      serverName: serverName.isEmpty ? "Default Server" : serverName,
      jenkinsURL: jenkinsURL,
      username: username,
      password: password,
      paramToken: paramToken,
      isDefault: true,
      createdAt: Date(),
      updatedAt: Date()
    )
  }

  private func validateForm() -> Bool {
    let errors = currentCredentials.validationErrors
    if !errors.isEmpty {
      alert = .validationError(errors: errors)
      return false
    }
    return true
  }
}
