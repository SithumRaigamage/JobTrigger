//
//  JobDetailViewModel.swift
//  Lab-Trigger-frontend
//
//  Created by Sithum Raigamage on 2026-02-20.
//

import Combine
import Foundation
import SwiftUI

final class JobDetailViewModel: ObservableObject {

  // MARK: - Published Properties
  @Published var job: JenkinsJob
  @Published var isTriggering = false
  @Published var isCancelling = false
  @Published var triggerStatus: TriggerStatus = .idle
  @Published var parameterValues: [String: String] = [:]
  @Published var isPolling = false

  @AppStorage("activeJenkinsURL") var activeJenkinsURL: String = ""

  // MARK: - Private Properties
  private let apiService = JenkinsAPIService.shared
  private let activeServerManager = ActiveServerManager.shared
  private var pollingTask: Task<Void, Never>?

  // MARK: - Enums
  enum TriggerStatus {
    case idle
    case success
    case failed(String)
    case cancelled
  }

  // MARK: - Initialization
  init(job: JenkinsJob) {
    self.job = job
    Task {
      await loadJobDetails()
    }
  }

  deinit {
    stopPolling()
  }

  // MARK: - Public Methods

  @MainActor
  func loadJobDetails() async {
    guard let server = activeServerManager.activeServer else { return }

    // Normalize URL using AppStorage base URL
    let normalizedURL = apiService.normalizeURL(jobURL: job.url, baseURL: activeJenkinsURL)

    let result = await apiService.fetchJobDetails(
      url: normalizedURL,
      username: server.username,
      password: server.password,
      paramToken: server.paramToken
    )

    if case .success(let detailedJob) = result {
      self.job = detailedJob
      self.initializeParameters(for: detailedJob)

      // Start/Stop polling based on build state
      if detailedJob.lastBuild?.building == true {
        startPolling()
      } else {
        stopPolling()
      }
    }
  }

  func startPolling() {
    guard pollingTask == nil else { return }
    isPolling = true

    pollingTask = Task {
      while !Task.isCancelled {
        try? await Task.sleep(nanoseconds: 5 * 1_000_000_000)  // 5 seconds
        if Task.isCancelled { break }
        await loadJobDetails()

        // If build finished, stop polling
        if job.lastBuild?.building != true {
          break
        }
      }
      isPolling = false
      pollingTask = nil
    }
  }

  func stopPolling() {
    pollingTask?.cancel()
    pollingTask = nil
    isPolling = false
  }

  private func initializeParameters(for job: JenkinsJob) {
    var defaults: [String: String] = [:]

    if let props = job.property {
      for prop in props {
        if let defs = prop.parameterDefinitions {
          for param in defs {
            defaults[param.name] = param.defaultValue
          }
        }
      }
    }

    self.parameterValues = defaults
  }

  @MainActor
  func triggerBuild() async {
    guard let server = activeServerManager.activeServer else {
      self.triggerStatus = .failed("No active server connected")
      return
    }

    isTriggering = true
    triggerStatus = .idle

    // Normalize before triggering
    let normalizedURL = apiService.normalizeURL(jobURL: job.url, baseURL: activeJenkinsURL)

    // Update local job URL for consistency
    self.job.url = normalizedURL

    let result = await apiService.triggerJob(
      job: job,
      username: server.username,
      password: server.password,
      paramToken: server.paramToken,
      parameters: parameterValues
    )

    switch result {
    case .success:
      triggerStatus = .success
      UINotificationFeedbackGenerator().notificationOccurred(.success)
      NotificationManager.shared.show(
        type: .success,
        title: "Build Triggered",
        message: "A new build for \(job.name) has been requested."
      )
      // Optimistically flip the building state so the UI reacts smoothly right away.
      if var lastBuild = self.job.lastBuild {
        // Create a new mock build summarizing our start state
        let optimisticBuild = BuildSummary(
          number: (lastBuild.number) + 1,
          url: lastBuild.url,
          result: nil,
          timestamp: Date().timeIntervalSince1970 * 1000,
          duration: nil,
          estimatedDuration: lastBuild.estimatedDuration,
          building: true
        )
        self.job = JenkinsJob(
          name: self.job.name,
          url: self.job.url,
          color: self.job.color,
          description: self.job.description,
          jobs: self.job.jobs,
          lastBuild: optimisticBuild,
          healthReport: self.job.healthReport,
          property: self.job.property,
          builds: self.job.builds
        )
      } else {
        // Even if there wasn't a previous build, inject an optimistic one
        let optimisticBuild = BuildSummary(
          number: 1,
          url: self.job.url,
          result: nil,
          timestamp: Date().timeIntervalSince1970 * 1000,
          duration: nil,
          estimatedDuration: nil,
          building: true
        )
        self.job = JenkinsJob(
          name: self.job.name,
          url: self.job.url,
          color: self.job.color,
          description: self.job.description,
          jobs: self.job.jobs,
          lastBuild: optimisticBuild,
          healthReport: self.job.healthReport,
          property: self.job.property,
          builds: self.job.builds
        )
      }
      // Immediately start polling to see the transition to 'building'
      startPolling()
    case .failure(let error):
      triggerStatus = .failed(error.localizedDescription)
      UINotificationFeedbackGenerator().notificationOccurred(.error)
      NotificationManager.shared.show(
        type: .error,
        title: "Trigger Failed",
        message: error.localizedDescription
      )
    }

    isTriggering = false
  }

  @MainActor
  func cancelRunningBuild() async {
    guard let server = activeServerManager.activeServer else {
      self.triggerStatus = .failed("No active server connected")
      return
    }

    guard let buildNumber = job.lastBuild?.number, job.lastBuild?.building == true else {
      self.triggerStatus = .failed("No active build running to cancel")
      return
    }

    isCancelling = true
    triggerStatus = .idle

    let normalizedURL = apiService.normalizeURL(jobURL: job.url, baseURL: activeJenkinsURL)

    let result = await apiService.cancelBuild(
      jobURL: normalizedURL,
      buildNumber: buildNumber,
      username: server.username,
      password: server.password,
      paramToken: server.paramToken
    )

    switch result {
    case .success:
      triggerStatus = .cancelled
      UINotificationFeedbackGenerator().notificationOccurred(.success)
      NotificationManager.shared.show(
        type: .success,
        title: "Cancel Requested",
        message: "Requested cancellation of build #\(buildNumber)."
      )
      // Force an immediate reload to fetch the ABORTED status
      await loadJobDetails()
    case .failure(let error):
      triggerStatus = .failed(error.localizedDescription)
      UINotificationFeedbackGenerator().notificationOccurred(.error)
      NotificationManager.shared.show(
        type: .error,
        title: "Cancel Failed",
        message: error.localizedDescription
      )
    }

    isCancelling = false
  }
}
