//
//  GlobalHistoryViewModel.swift
//  Lab-Trigger-frontend
//
//  Created by Sithum Raigamage on 2026-02-20.
//

import Combine
import Foundation
import SwiftUI

final class GlobalHistoryViewModel: ObservableObject {

  // MARK: - Published Properties
  @Published var builds: [GlobalBuild] = []
  @Published var isLoading = false
  @Published var errorMessage: String?

  @AppStorage("activeJenkinsURL") var activeJenkinsURL: String = ""

  // MARK: - Private Properties
  private let apiService = JenkinsAPIService.shared
  private let activeServerManager = ActiveServerManager.shared

  // MARK: - Public Methods

  @MainActor
  func fetchGlobalHistory() async {
    // Retry logic if server is still loading
    var retries = 0
    while activeServerManager.activeServer == nil && retries < 5 {
      print("⏳ [GlobalHistoryViewModel] Waiting for active server... (Attempt \(retries + 1))")
      try? await Task.sleep(nanoseconds: 500_000_000)  // 0.5s
      retries += 1
    }

    guard let server = activeServerManager.activeServer else {
      print("❌ [GlobalHistoryViewModel] No active server found after retries")
      self.errorMessage = "No active server connected. Please check your settings."
      self.isLoading = false
      return
    }

    if activeJenkinsURL.isEmpty {
      print("⚠️ [GlobalHistoryViewModel] activeJenkinsURL is empty in AppStorage")
      self.errorMessage = "Jenkins URL not configured."
      self.isLoading = false
      return
    }

    self.isLoading = true
    self.errorMessage = nil

    print("🔍 [GlobalHistoryViewModel] Fetching global history for: \(activeJenkinsURL)")

    let result = await apiService.fetchGlobalBuildHistory(
      baseURL: activeJenkinsURL,
      username: server.username,
      password: server.password
    )

    switch result {
    case .success(let fetchedBuilds):
      print("✅ [GlobalHistoryViewModel] Successfully fetched \(fetchedBuilds.count) builds")
      self.builds = fetchedBuilds
    case .failure(let error):
      print("❌ [GlobalHistoryViewModel] Fetch failed: \(error)")
      self.errorMessage = "Failed to fetch global history: \(error.localizedDescription)"
      self.builds = []
    }

    self.isLoading = false
  }
}
