//
//  ProfileViewModel.swift
//  Lab-Trigger-frontend
//
//  Created on 2026-02-09.
//

import Combine
import Foundation

final class ProfileViewModel: ObservableObject {

  // MARK: - Published Properties

  @Published var userEmail: String = ""
  @Published var activeServerName: String = "No Server Configured"
  @Published var activeServerURL: String = "-"
  @Published var totalServersCount: Int = 0
  @Published var appVersion: String = "1.0.0 (1)"
  @Published var backendAppInfo: AppInfo?

  // MARK: - Services

  private let authManager = AuthenticationManager.shared
  private let storageService = CredentialStorageService.shared

  // MARK: - Initialization

  init() {
    Task {
      await loadProfileData()
    }
  }

  // MARK: - Public Methods

  @MainActor
  func loadProfileData() async {
    // Load User Info
    if let user = authManager.currentUser {
      userEmail = user.email
    }

    // Load Credentials Info
    do {
      let all = try await storageService.loadAll()
      totalServersCount = all.count

      if let credentials = all.first(where: { $0.isDefault }) ?? all.first {
        activeServerName = credentials.serverName
        activeServerURL = credentials.jenkinsURL
      }
    } catch {
      print("❌ Profile View Model: Error loading data: \(error)")
      NotificationManager.shared.show(
        type: .error,
        title: "Data Loading Failed",
        message: "Failed to load profile data. Please check your connection."
      )
    }

    // App Version
    if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String,
      let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String
    {
      appVersion = "\(version) (\(build))"
    }

    // Load Backend App Info
    await fetchBackendAppInfo()
  }

  @MainActor
  private func fetchBackendAppInfo() async {
    do {
      let info: AppInfo = try await BackendClient.shared.request(
        APIConfig.appInfo, requiresAuth: false)
      self.backendAppInfo = info
      // Override local version with backend version if it exists
      self.appVersion = "\(info.appVersion) (\(info.buildNumber))"
    } catch {
      print("⚠️ Profile View Model: Failed to fetch backend app info: \(error)")
    }
  }

  func signOut() {
    authManager.signOut()
  }
}
