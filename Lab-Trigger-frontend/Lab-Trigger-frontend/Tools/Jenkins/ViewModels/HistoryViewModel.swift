//
//  HistoryViewModel.swift
//  Lab-Trigger-frontend
//
//  Created by Sithum Raigamage on 2026-02-20.
//

import Combine
import Foundation
import SwiftUI

final class HistoryViewModel: ObservableObject {

  // MARK: - Published Properties
  @Published var job: JenkinsJob
  @Published var builds: [JenkinsBuild] = []
  @Published var isLoading = false
  @Published var errorMessage: String?

  @AppStorage("activeJenkinsURL") var activeJenkinsURL: String = ""

  // MARK: - Private Properties
  private let apiService = JenkinsAPIService.shared
  private let activeServerManager = ActiveServerManager.shared

  // MARK: - Initialization
  init(job: JenkinsJob) {
    self.job = job
  }

  // MARK: - Public Methods

  @MainActor
  func fetchHistory() async {
    guard let server = activeServerManager.activeServer else {
      self.errorMessage = "No active server connected"
      return
    }

    self.isLoading = true
    self.errorMessage = nil

    // Normalize URL using AppStorage base URL
    let normalizedURL = apiService.normalizeURL(jobURL: job.url, baseURL: activeJenkinsURL)

    let result = await apiService.fetchBuildHistory(
      url: normalizedURL,
      username: server.username,
      password: server.password,
      paramToken: server.paramToken
    )

    switch result {
    case .success(let fetchedBuilds):
      self.builds = fetchedBuilds
    case .failure(let error):
      self.errorMessage = "Failed to fetch build history: \(error.localizedDescription)"
      self.builds = []
    }

    self.isLoading = false
  }
}
