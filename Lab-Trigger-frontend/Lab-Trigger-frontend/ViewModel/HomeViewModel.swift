//
//  HomeViewModel.swift
//  Lab-Trigger-frontend
//
//  Created by Sithum Raigamage on 2026-02-17.
//

import Combine
import Foundation
import SwiftUI

final class HomeViewModel: ObservableObject {

  // MARK: - Published Properties
  @Published var jobs: [JenkinsJob] = []
  @Published var isLoading = false
  @Published var errorMessage: String?
  @Published var activeServerName: String = "No Server Connected"
  @Published var searchText: String = ""
  @Published var navigationStack: [String] = []  // Stack of folder names for breadcrumbs
  @Published var currentFolderJobs: [[JenkinsJob]] = []  // Stack of job lists to avoid re-fetching
  @Published var selectedJob: JenkinsJob? = nil  // For navigation to details

  @AppStorage("activeJenkinsURL") var activeJenkinsURL: String = ""

  // MARK: - Private Properties
  private let apiService = JenkinsAPIService.shared
  private let activeServerManager = ActiveServerManager.shared
  private var cancellables = Set<AnyCancellable>()

  // MARK: - Initialization
  init() {
    setupObservers()
  }

  // MARK: - Public Methods

  @MainActor
  func refreshJobs() async {
    guard let server = activeServerManager.activeServer else {
      self.jobs = []
      self.activeServerName = "No Server Connected"
      self.navigationStack = []
      self.currentFolderJobs = []
      return
    }

    self.activeServerName = server.serverName
    self.isLoading = true
    self.errorMessage = nil

    let result = await apiService.fetchJobs(
      url: activeJenkinsURL,
      username: server.username,
      password: server.password,
      paramToken: server.paramToken
    )

    switch result {
    case .success(let fetchedJobs):
      self.jobs = fetchedJobs
      // Reset navigation when server is refreshed
      self.navigationStack = []
      self.currentFolderJobs = [fetchedJobs]
    case .failure(let error):
      self.errorMessage = "Failed to fetch jobs: \(error.localizedDescription)"
      self.jobs = []
      self.currentFolderJobs = []
    }

    self.isLoading = false
  }

  // MARK: - Quick Trigger (US-14)

  @Published var isTriggeringJobId: String? = nil

  @MainActor
  func triggerJob(_ job: JenkinsJob) async {
    guard let server = activeServerManager.activeServer else { return }
    isTriggeringJobId = job.id

    let normalizedURL = apiService.normalizeURL(jobURL: job.url, baseURL: activeJenkinsURL)
    var updatedJob = job
    updatedJob.url = normalizedURL

    let result = await apiService.triggerJob(
      job: updatedJob,
      username: server.username,
      password: server.password,
      paramToken: server.paramToken,
      parameters: nil
    )

    switch result {
    case .success:
      UINotificationFeedbackGenerator().notificationOccurred(.success)
      NotificationManager.shared.show(
        type: .success,
        title: "Build Triggered",
        message: "A new build for \(job.name) has been requested."
      )
      // Optional: refresh jobs after a short delay
      try? await Task.sleep(nanoseconds: 2 * 1_000_000_000)
      await refreshJobs()
    case .failure(let error):
      UINotificationFeedbackGenerator().notificationOccurred(.error)
      NotificationManager.shared.show(
        type: .error,
        title: "Trigger Failed",
        message: error.localizedDescription
      )
    }

    isTriggeringJobId = nil
  }

  // MARK: - Search & Filtering

  /// Computed property to return jobs displayed in current folder or global search results
  var displayedJobs: [JenkinsJob] {
    if searchText.isEmpty {
      return currentFolderJobs.last ?? []
    } else {
      // Global search across all jobs
      return allJobsFlattened.filter {
        $0.name.lowercased().contains(searchText.lowercased())
      }
    }
  }

  /// Flattens the nested job tree for global search
  private var allJobsFlattened: [JenkinsJob] {
    return flattenJobs(jobs)
  }

  private func flattenJobs(_ jobs: [JenkinsJob]) -> [JenkinsJob] {
    var flattened: [JenkinsJob] = []
    for job in jobs {
      flattened.append(job)
      if let nestedJobs = job.jobs {
        flattened.append(contentsOf: flattenJobs(nestedJobs))
      }
    }
    return flattened
  }

  // MARK: - Navigation

  func navigateInto(_ job: JenkinsJob) {
    if let nestedJobs = job.jobs {
      navigationStack.append(job.name)
      currentFolderJobs.append(nestedJobs)
      searchText = ""  // Clear search when navigating
    }
  }

  func navigateBack() {
    if navigationStack.count > 0 {
      navigationStack.removeLast()
      currentFolderJobs.removeLast()
    }
  }

  // MARK: - Private Methods

  private func setupObservers() {
    activeServerManager.$activeServer
      .receive(on: DispatchQueue.main)
      .sink { [weak self] server in
        if let server = server {
          self?.activeServerName = server.serverName
          Task {
            await self?.refreshJobs()
          }
        } else {
          self?.activeServerName = "No Server Connected"
          self?.jobs = []
        }
      }
      .store(in: &cancellables)
  }
}
