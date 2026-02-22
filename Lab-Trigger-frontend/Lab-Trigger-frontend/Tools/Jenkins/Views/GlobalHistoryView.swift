//
//  GlobalHistoryView.swift
//  Lab-Trigger-frontend
//
//  Created by Sithum Raigamage on 2026-02-20.
//

import SwiftUI

struct GlobalHistoryView: View {
  @StateObject private var viewModel = GlobalHistoryViewModel()

  var body: some View {
    ZStack {
      Color(UIColor.systemGroupedBackground)
        .ignoresSafeArea()

      VStack(spacing: 0) {
        if viewModel.isLoading && viewModel.builds.isEmpty {
          ProgressView("Loading global history...")
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if let error = viewModel.errorMessage {
          errorView(error)
        } else if viewModel.builds.isEmpty {
          emptyStateView
        } else {
          buildListView
        }
      }
    }
    .navigationTitle("Global History")
    .onAppear {
      Task {
        await viewModel.fetchGlobalHistory()
      }
    }
    .refreshable {
      await viewModel.fetchGlobalHistory()
    }
  }

  // MARK: - Subviews

  private var buildListView: some View {
    ScrollView {
      LazyVStack(spacing: 16) {
        ForEach(viewModel.builds) { globalBuild in
          globalBuildRow(globalBuild)
        }
      }
      .padding()
    }
  }

  private func globalBuildRow(_ globalBuild: GlobalBuild) -> some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack {
        VStack(alignment: .leading, spacing: 4) {
          Text(globalBuild.jobName)
            .font(.subheadline)
            .fontWeight(.semibold)
            .foregroundColor(.blue)

          Text("#\(globalBuild.build.number)")
            .font(.headline)
            .fontWeight(.bold)
        }

        Spacer()

        if let result = globalBuild.build.result {
          StatusTag(result: result)
        } else if globalBuild.build.building == true {
          Text("BUILDING")
            .font(.system(size: 10, weight: .bold))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.blue.opacity(0.12))
            .foregroundColor(.blue)
            .clipShape(Capsule())
        }
      }

      if let building = globalBuild.build.building, building {
        ProgressView(value: globalBuild.build.progress)
          .tint(.blue)
          .padding(.bottom, 4)
      }

      HStack(spacing: 16) {
        Label(formatDate(globalBuild.build.timestamp), systemImage: "calendar")
        Label(formatDuration(globalBuild.build.duration), systemImage: "clock")
      }
      .font(.caption)
      .foregroundColor(.secondary)

      NavigationLink(
        destination: BuildLogView(
          viewModel: BuildLogViewModel(
            buildURL: globalBuild.build.url, buildNumber: globalBuild.build.number))
      ) {
        Label("View Logs", systemImage: "terminal")
          .font(.caption)
          .fontWeight(.medium)
          .padding(.vertical, 8)
          .frame(maxWidth: .infinity)
          .background(Color.blue.opacity(0.1))
          .foregroundColor(.blue)
          .cornerRadius(8)
      }
      .padding(.top, 4)
    }
    .padding()
    .background(Color(UIColor.secondarySystemGroupedBackground))
    .cornerRadius(16)
    .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 4)
  }

  private var emptyStateView: some View {
    VStack(spacing: 20) {
      Image(systemName: "clock.arrow.circlepath")
        .font(.system(size: 60))
        .foregroundColor(.secondary.opacity(0.5))

      Text("No Global History")
        .font(.title3)
        .fontWeight(.bold)

      Text("No builds found across your Jenkins jobs.")
        .font(.subheadline)
        .foregroundColor(.secondary)
        .multilineTextAlignment(.center)
    }
    .padding()
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }

  private func errorView(_ message: String) -> some View {
    VStack(spacing: 16) {
      Image(systemName: "exclamationmark.triangle.fill")
        .font(.system(size: 40))
        .foregroundColor(.orange)

      Text(message)
        .font(.subheadline)
        .foregroundColor(.secondary)
        .multilineTextAlignment(.center)

      Button("Retry") {
        Task {
          await viewModel.fetchGlobalHistory()
        }
      }
      .buttonStyle(.bordered)
    }
    .padding()
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }

  // MARK: - Helpers

  private func formatDate(_ timestamp: Double?) -> String {
    guard let timestamp = timestamp else { return "Unknown date" }
    let date = Date(timeIntervalSince1970: timestamp / 1000)
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    formatter.timeStyle = .short
    return formatter.string(from: date)
  }

  private func formatDuration(_ duration: Double?) -> String {
    guard let duration = duration else { return "0s" }
    let seconds = Int(duration / 1000)
    if seconds < 60 {
      return "\(seconds)s"
    } else {
      let minutes = seconds / 60
      let remainingSeconds = seconds % 60
      return "\(minutes)m \(remainingSeconds)s"
    }
  }
}
