//
//  HistoryView.swift
//  Lab-Trigger-frontend
//
//  Created by Sithum Raigamage on 2026-02-20.
//

import SwiftUI

struct HistoryView: View {
  @StateObject private var viewModel: HistoryViewModel
  @Environment(\.dismiss) var dismiss

  init(job: JenkinsJob) {
    _viewModel = StateObject(wrappedValue: HistoryViewModel(job: job))
  }

  var body: some View {
    ZStack {
      Color(UIColor.systemGroupedBackground)
        .ignoresSafeArea()

      VStack(spacing: 0) {
        if viewModel.isLoading && viewModel.builds.isEmpty {
          ProgressView("Loading history...")
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
    .navigationTitle("Build History")
    .navigationBarTitleDisplayMode(.inline)
    .onAppear {
      Task {
        await viewModel.fetchHistory()
      }
    }
  }

  // MARK: - Subviews

  private var buildListView: some View {
    ScrollView {
      LazyVStack(spacing: 16) {
        ForEach(viewModel.builds) { build in
          buildRow(build)
        }
      }
      .padding()
    }
  }

  private func buildRow(_ build: JenkinsBuild) -> some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack {
        Text("#\(build.number)")
          .font(.headline)
          .fontWeight(.bold)

        Spacer()

        if let result = build.result {
          StatusTag(result: result)
        } else if build.building == true {
          Text("BUILDING")
            .font(.system(size: 10, weight: .bold))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.blue.opacity(0.12))
            .foregroundColor(.blue)
            .clipShape(Capsule())
        }
      }

      if let building = build.building, building {
        ProgressView(value: build.progress)
          .tint(.blue)
          .padding(.bottom, 4)
      }

      HStack(spacing: 16) {
        Label(formatDate(build.timestamp), systemImage: "calendar")
        Label(formatDuration(build.duration), systemImage: "clock")
      }
      .font(.caption)
      .foregroundColor(.secondary)

      if let displayName = build.displayName, displayName != "#\(build.number)" {
        Text(displayName)
          .font(.caption2)
          .italic()
          .foregroundColor(.secondary)
      }

      NavigationLink(
        destination: BuildLogView(
          viewModel: BuildLogViewModel(buildURL: build.url, buildNumber: build.number))
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

      Text("No Build History")
        .font(.title3)
        .fontWeight(.bold)

      Text("This job hasn't been triggered yet or history is unavailable.")
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
          await viewModel.fetchHistory()
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

struct StatusTag: View {
  let result: String

  var body: some View {
    Text(result)
      .font(.system(size: 10, weight: .bold))
      .padding(.horizontal, 8)
      .padding(.vertical, 4)
      .background(backgroundColor.opacity(0.12))
      .foregroundColor(backgroundColor)
      .clipShape(Capsule())
  }

  private var backgroundColor: Color {
    switch result.uppercased() {
    case "SUCCESS": return .green
    case "FAILURE": return .red
    case "ABORTED": return .gray
    case "UNSTABLE": return .orange
    default: return .gray
    }
  }
}
