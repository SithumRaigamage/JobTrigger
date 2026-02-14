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

  // MARK: - Services

  private let authManager = AuthenticationManager.shared
  private let storageService = CredentialStorageService.shared

  // MARK: - Initialization

  init() {
    loadProfileData()
  }

  // MARK: - Public Methods

  func loadProfileData() {
    // Load User Info
    if let user = authManager.currentUser {
      userEmail = user.email
    }

    // Load Active Server Info
    if let credentials = storageService.load() {
      activeServerName = credentials.serverName
      activeServerURL = credentials.jenkinsURL
    }

    // Load Total Servers Count
    totalServersCount = storageService.loadAll().count

    // App Version
    if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String,
      let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String
    {
      appVersion = "\(version) (\(build))"
    }
  }

  func signOut() {
    authManager.signOut()
  }
}
