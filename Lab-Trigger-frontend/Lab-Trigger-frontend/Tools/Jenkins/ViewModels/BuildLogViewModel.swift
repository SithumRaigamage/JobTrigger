//
//  BuildLogViewModel.swift
//  Lab-Trigger-frontend
//
//  Created by Sithum Raigamage on 2026-02-20.
//

import Combine
import Foundation
import SwiftUI

final class BuildLogViewModel: ObservableObject {
  // MARK: - Published Properties
  @Published var logs: String = ""
  @Published var isLoading = false
  @Published var error: String?
  @Published var isFinished = false
  @Published var autoScroll = true

  @AppStorage("activeJenkinsURL") var activeJenkinsURL: String = ""

  // MARK: - Private Properties
  private let buildURL: String
  let buildNumber: Int
  private var currentOffset: Int = 0
  private let apiService = JenkinsAPIService.shared
  private let activeServerManager = ActiveServerManager.shared
  private var timerTask: Task<Void, Never>?

  // MARK: - Initialization
  init(buildURL: String, buildNumber: Int) {
    self.buildURL = buildURL
    self.buildNumber = buildNumber
  }

  // MARK: - Public Methods
  @MainActor
  func startFetching() async {
    guard !isLoading else { return }
    isLoading = true
    error = nil

    await fetchNextSegment()
  }

  func stopFetching() {
    timerTask?.cancel()
    timerTask = nil
  }

  @MainActor
  func fetchNextSegment() async {
    guard let server = activeServerManager.activeServer else {
      self.error = "No active server"
      self.isLoading = false
      return
    }

    // Normalize URL
    let normalizedURL = apiService.normalizeURL(jobURL: buildURL, baseURL: activeJenkinsURL)

    let result = await apiService.fetchBuildLogs(
      buildURL: normalizedURL,
      startOffset: currentOffset,
      username: server.username,
      password: server.password
    )

    switch result {
    case .success(let response):
      self.logs += response.text
      self.currentOffset = response.nextOffset
      self.isFinished = !response.hasMoreData

      if !isFinished {
        setupTimer()
      }
    case .failure(let apiError):
      self.error = apiError.localizedDescription
    }

    self.isLoading = false
  }

  func copyToClipboard() {
    UIPasteboard.general.string = logs
  }

  func shareLogs() {
    let activityController = UIActivityViewController(
      activityItems: [logs], applicationActivities: nil)
    if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
      let rootVC = windowScene.windows.first?.rootViewController
    {
      rootVC.present(activityController, animated: true)
    }
  }

  // MARK: - Private Methods
  private func setupTimer() {
    timerTask?.cancel()
    timerTask = Task {
      try? await Task.sleep(nanoseconds: 3 * 1_000_000_000)  // Poll every 3 seconds
      if !Task.isCancelled {
        await fetchNextSegment()
      }
    }
  }
}
