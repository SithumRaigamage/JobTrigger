//
//  ActiveServerManager.swift
//  Lab-Trigger-frontend
//
//  Created by Sithum Raigamage on 2026-02-17.
//

import Combine
import Foundation
import SwiftUI

/// Singleton manager for the currently active Jenkins server
final class ActiveServerManager: ObservableObject {

  // MARK: - Singleton
  static let shared = ActiveServerManager()

  // MARK: - Published Properties
  @Published var activeServer: JenkinsCredentials? {
    didSet {
      if let server = activeServer {
        activeJenkinsURL = server.jenkinsURL
      } else {
        activeJenkinsURL = ""
      }
    }
  }

  // Persist the active URL for context sharing across views/vms
  @AppStorage("activeJenkinsURL") var activeJenkinsURL: String = ""

  private init() {}

  // MARK: - Public Methods

  @MainActor
  func setActiveServer(_ server: JenkinsCredentials) {
    self.activeServer = server
  }

  @MainActor
  func clearActiveServer() {
    self.activeServer = nil
    self.activeJenkinsURL = ""
  }

  /// Load the default or first available server from storage
  @MainActor
  func loadInitialServer() async {
    print("🔍 [ActiveServerManager] Loading initial server...")
    do {
      let servers = try await CredentialStorageService.shared.loadAll()
      if let defaultServer = servers.first(where: { $0.isDefault }) ?? servers.first {
        print("✅ [ActiveServerManager] Found initial server: \(defaultServer.serverName)")
        self.setActiveServer(defaultServer)
      } else {
        print("⚠️ [ActiveServerManager] No servers found in storage.")
      }
    } catch {
      print("❌ [ActiveServerManager] Error loading initial server: \(error)")
    }
  }

  /// Set the active server and notify observers
  func setActiveServer(_ server: JenkinsCredentials?) {
    DispatchQueue.main.async {
      self.activeServer = server
    }
  }
}
