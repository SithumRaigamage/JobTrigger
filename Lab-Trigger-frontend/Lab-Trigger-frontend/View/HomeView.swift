//
//  HomeView.swift
//  Lab-Trigger-frontend
//
//  Created by Sithum Raigamage on 2026-02-07.
//

import SwiftUI

struct HomeView: View {
  @StateObject private var viewModel = HomeViewModel()

  var body: some View {
    ZStack {
      Color(UIColor.systemGroupedBackground)
        .ignoresSafeArea()

      VStack(spacing: 0) {
        // 🔹 Breadcrumbs & Navigation Header
        if !viewModel.navigationStack.isEmpty || !viewModel.searchText.isEmpty {
          headerView
            .transition(.move(edge: .top).combined(with: .opacity))
        }

        if viewModel.isLoading && viewModel.jobs.isEmpty {
          loadingView
        } else if let error = viewModel.errorMessage {
          errorView(error)
        } else {
          jobListView
        }
      }
    }
    .navigationTitle(viewModel.navigationStack.last ?? "Jobs")
    .searchable(text: $viewModel.searchText, prompt: "Search Jobs")
    .onAppear {
      checkConnectivity()
    }
    .animation(.spring(response: 0.4, dampingFraction: 0.8), value: viewModel.navigationStack)
    .animation(.easeInOut, value: viewModel.searchText)
  }

  // MARK: - Subviews

  private var headerView: some View {
    VStack(alignment: .leading, spacing: 8) {
      if !viewModel.searchText.isEmpty {
        HStack {
          Image(systemName: "magnifyingglass")
            .foregroundColor(.blue)
          Text("Searching across all folders")
            .font(.subheadline)
            .foregroundColor(.secondary)
        }
        .padding(.horizontal)
      } else if !viewModel.navigationStack.isEmpty {
        HStack {
          Button {
            viewModel.navigateBack()
          } label: {
            HStack(spacing: 4) {
              Image(systemName: "chevron.left")
              Text("Back")
            }
            .font(.subheadline)
            .fontWeight(.medium)
          }

          ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 4) {
              Text("Home")
                .foregroundColor(.secondary)
              ForEach(viewModel.navigationStack, id: \.self) { folder in
                Text("/")
                  .foregroundColor(.secondary)
                Text(folder)
                  .fontWeight(.semibold)
                  .foregroundColor(.blue)
              }
            }
            .font(.caption)
          }
        }
        .padding(.horizontal)
      }
    }
    .padding(.vertical, 12)
    .background(Color(UIColor.secondarySystemGroupedBackground))
    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    .padding(.horizontal)
    .padding(.bottom, 8)
    .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
  }

  private var jobListView: some View {
    List {
      if viewModel.displayedJobs.isEmpty {
        emptyStateView
      } else {
        Section(
          header: Text(
            viewModel.searchText.isEmpty
              ? (viewModel.navigationStack.isEmpty
                ? "All Jobs" : "Jobs in \(viewModel.navigationStack.last!)")
              : "Search Results"
          )
          .font(.caption)
          .fontWeight(.bold)
          .foregroundColor(.secondary)
          .textCase(.uppercase)
        ) {
          ForEach(viewModel.displayedJobs) { job in
            JobRow(job: job, highlight: viewModel.searchText) {
              if job.isFolder {
                viewModel.navigateInto(job)
              } else {
                viewModel.selectedJob = job
              }
            }
            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
          }
        }
      }
    }
    .listStyle(.plain)
    .navigationDestination(item: $viewModel.selectedJob) { job in
      JobDetailView(job: job)
    }
    .refreshable {
      await viewModel.refreshJobs()
    }
  }

  private var loadingView: some View {
    VStack(spacing: 16) {
      ProgressView()
        .scaleEffect(1.5)
      Text("Fetching jobs from Jenkins...")
        .font(.subheadline)
        .foregroundColor(.secondary)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }

  private func errorView(_ error: String) -> some View {
    VStack(spacing: 20) {
      Image(systemName: "exclamationmark.triangle.fill")
        .font(.system(size: 60))
        .foregroundColor(.orange)
      Text(error)
        .multilineTextAlignment(.center)
        .padding()
      Button("Retry") {
        Task { await viewModel.refreshJobs() }
      }
      .buttonStyle(.borderedProminent)
      .buttonBorderShape(.capsule)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }

  private var emptyStateView: some View {
    VStack(spacing: 12) {
      Image(systemName: "magnifyingglass")
        .font(.system(size: 40))
        .foregroundColor(.secondary.opacity(0.5))
      Text(
        viewModel.searchText.isEmpty
          ? "No jobs found" : "No results for \"\(viewModel.searchText)\""
      )
      .foregroundColor(.secondary)
    }
    .frame(maxWidth: .infinity)
    .padding(.vertical, 40)
    .listRowBackground(Color.clear)
  }

  private func checkConnectivity() {
    Task {
      do {
        // Simple health check or ping
        let _: EmptyResponse = try await BackendClient.shared.request(
          APIConfig.rootURL, requiresAuth: false)
      } catch {
        NotificationManager.shared.show(
          type: .warning,
          title: "Offline Mode",
          message: "Could not connect to the backend server. Some features may be unavailable."
        )
      }
    }
  }
}

#Preview {
  HomeView()
}

// MARK: - Row Component

struct JobRow: View {
  let job: JenkinsJob
  var highlight: String = ""
  let action: () -> Void

  var body: some View {
    Button(action: action) {
      HStack(spacing: 16) {
        if job.isFolder {
          ZStack {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
              .fill(Color.orange.opacity(0.1))
              .frame(width: 44, height: 44)
            Image(systemName: "folder.fill")
              .foregroundColor(.orange)
              .font(.system(size: 20))
          }
        } else {
          StatusIndicator(color: job.color ?? "grey")
            .frame(width: 44, height: 44)
        }

        VStack(alignment: .leading, spacing: 4) {
          HighlightedText(text: job.name, highlight: highlight)
            .foregroundColor(.primary)

          HStack(spacing: 8) {
            if let lastBuild = job.lastBuild {
              Label("#\(lastBuild.number)", systemImage: "number")
                .font(.caption2)
                .fontWeight(.medium)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Color.blue.opacity(0.1))
                .foregroundColor(.blue)
                .cornerRadius(4)
            } else if !job.isFolder {
              Text("No builds")
                .font(.caption2)
                .foregroundColor(.secondary)
            }

            if let desc = job.description, !desc.isEmpty {
              Text(desc)
                .font(.caption2)
                .foregroundColor(.secondary)
                .lineLimit(1)
            }
          }
        }

        Spacer()

        Image(systemName: "chevron.right")
          .foregroundColor(.secondary.opacity(0.5))
          .font(.system(size: 14, weight: .bold))
      }
      .padding(12)
      .background(Color(UIColor.secondarySystemGroupedBackground))
      .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
      .shadow(color: Color.black.opacity(0.03), radius: 3, x: 0, y: 1)
    }
    .buttonStyle(.plain)
  }
}
