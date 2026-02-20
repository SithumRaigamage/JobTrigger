//
//  JobDetailView.swift
//  Lab-Trigger-frontend
//
//  Created by Sithum Raigamage on 2026-02-20.
//

import SwiftUI

struct JobDetailView: View {
  @StateObject private var viewModel: JobDetailViewModel
  @Environment(\.dismiss) var dismiss

  init(job: JenkinsJob) {
    _viewModel = StateObject(wrappedValue: JobDetailViewModel(job: job))
  }

  var body: some View {
    ZStack {
      Color(UIColor.systemGroupedBackground)
        .ignoresSafeArea()

      ScrollView {
        VStack(alignment: .leading, spacing: 20) {
          // Header Section
          headerSection

          // Description Section
          if let desc = viewModel.job.description, !desc.isEmpty {
            descriptionSection(desc)
          }

          // Health Report Section
          if let reports = viewModel.job.healthReport, !reports.isEmpty {
            healthSection(reports)
          }

          // Parameters Section
          if let props = viewModel.job.property,
            let defs = props.first(where: { $0.parameterDefinitions != nil })?.parameterDefinitions
          {
            parametersSection(defs)
          }

          // Build Controls
          buildControls
        }
        .padding()
      }
    }
    .navigationTitle("Job Details")
    .navigationBarTitleDisplayMode(.inline)
  }

  // MARK: - Subviews

  private var headerSection: some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack {
        StatusIndicator(color: viewModel.job.color ?? "grey")
          .frame(width: 24, height: 24)
        Text(viewModel.job.name)
          .font(.title2)
          .fontWeight(.bold)
      }

      if let lastBuild = viewModel.job.lastBuild {
        VStack(alignment: .leading, spacing: 8) {
          HStack {
            Label("Last Build: #\(lastBuild.number)", systemImage: "number.circle.fill")
              .font(.headline)

            Spacer()

            if let result = lastBuild.result {
              Text(result)
                .font(.system(size: 10, weight: .bold))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(statusColor(result).opacity(0.12))
                .foregroundColor(statusColor(result))
                .clipShape(Capsule())
            } else if lastBuild.building == true {
              Text("BUILDING")
                .font(.system(size: 10, weight: .bold))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.blue.opacity(0.12))
                .foregroundColor(.blue)
                .clipShape(Capsule())
            }
          }

          if let building = lastBuild.building, building {
            VStack(alignment: .leading, spacing: 6) {
              ProgressView(value: lastBuild.progress)
                .tint(.blue)

              HStack {
                Text(lastBuild.progress > 0 ? "\(Int(lastBuild.progress * 100))%" : "Estimating...")
                Spacer()
                if let estimated = lastBuild.estimatedDuration, estimated > 0 {
                  Text("Est. \(formatDuration(estimated))")
                }
              }
              .font(.caption2)
              .foregroundColor(.secondary)
            }
            .padding(.top, 4)
          }

          HStack(spacing: 16) {
            Label(formatDate(lastBuild.timestamp), systemImage: "calendar")
            Label(formatDuration(lastBuild.duration), systemImage: "clock")
          }
          .font(.caption)
          .foregroundColor(.secondary)
        }
      }
    }
    .padding()
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(Color(UIColor.secondarySystemGroupedBackground))
    .cornerRadius(16)
    .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
  }

  private func descriptionSection(_ desc: String) -> some View {
    VStack(alignment: .leading, spacing: 8) {
      Text("Description")
        .font(.headline)
      Text(desc)
        .font(.body)
        .foregroundColor(.secondary)
    }
    .padding()
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(Color(UIColor.secondarySystemGroupedBackground))
    .cornerRadius(16)
  }

  private func healthSection(_ reports: [HealthReport]) -> some View {
    VStack(alignment: .leading, spacing: 12) {
      Text("Health Report")
        .font(.headline)

      ForEach(reports, id: \.self) { report in
        HStack(spacing: 12) {
          scoreIcon(report.score)
          VStack(alignment: .leading, spacing: 4) {
            Text(report.description)
              .font(.subheadline)
            ProgressView(value: Double(report.score), total: 100)
              .tint(scoreColor(report.score))
          }
        }
        .padding(.vertical, 4)
      }
    }
    .padding()
    .background(Color(UIColor.secondarySystemGroupedBackground))
    .cornerRadius(16)
  }

  private func parametersSection(_ definitions: [ParameterDefinition]) -> some View {
    VStack(alignment: .leading, spacing: 16) {
      Text("Parameters")
        .font(.title3)
        .fontWeight(.bold)

      ForEach(definitions, id: \.name) { param in
        VStack(alignment: .leading, spacing: 8) {
          HStack {
            Text(param.name)
              .font(.subheadline)
              .fontWeight(.semibold)
              .foregroundColor(.primary)

            Spacer()

            Text(param.type.replacingOccurrences(of: "ParameterDefinition", with: ""))
              .font(.system(size: 10, weight: .bold))
              .padding(.horizontal, 8)
              .padding(.vertical, 3)
              .background(Color.blue.opacity(0.12))
              .foregroundColor(.blue)
              .clipShape(Capsule())
          }

          parameterControl(for: param)

          if let desc = param.description, !desc.isEmpty {
            Text(desc)
              .font(.caption)
              .foregroundColor(.secondary)
              .lineLimit(2)
          }
        }
        .padding(.bottom, 4)
      }
    }
    .padding(20)
    .background(Color(UIColor.secondarySystemGroupedBackground))
    .cornerRadius(20)
    .shadow(color: Color.black.opacity(0.04), radius: 10, x: 0, y: 4)
  }

  @ViewBuilder
  private func parameterControl(for param: ParameterDefinition) -> some View {
    let binding = Binding(
      get: { viewModel.parameterValues[param.name] ?? "" },
      set: { viewModel.parameterValues[param.name] = $0 }
    )

    Group {
      if param.type.contains("BooleanParameterDefinition") {
        HStack {
          Toggle(
            isOn: Binding(
              get: { binding.wrappedValue.lowercased() == "true" },
              set: { binding.wrappedValue = $0 ? "true" : "false" }
            )
          ) {
            Text("Enable \(param.name)")
              .font(.subheadline)
              .foregroundColor(.secondary)
          }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color(UIColor.tertiarySystemGroupedBackground).opacity(0.5))
        .cornerRadius(12)
      } else if param.type.contains("ChoiceParameterDefinition"), let choices = param.choices {
        Menu {
          Picker("", selection: binding) {
            ForEach(choices, id: \.self) { choice in
              Text(choice).tag(choice)
            }
          }
        } label: {
          HStack {
            Text(binding.wrappedValue.isEmpty ? "Select \(param.name)" : binding.wrappedValue)
              .font(.subheadline)
              .foregroundColor(binding.wrappedValue.isEmpty ? .secondary : .primary)
            Spacer()
            Image(systemName: "chevron.up.chevron.down")
              .font(.caption)
              .foregroundColor(.secondary)
          }
          .padding(.horizontal, 12)
          .padding(.vertical, 12)
          .frame(maxWidth: .infinity, alignment: .leading)
          .background(Color(UIColor.tertiarySystemGroupedBackground).opacity(0.5))
          .cornerRadius(12)
        }
      } else if param.type.contains("PasswordParameterDefinition") {
        SecureField("Enter \(param.name)", text: binding)
          .font(.subheadline)
          .padding(.horizontal, 12)
          .padding(.vertical, 12)
          .background(Color(UIColor.tertiarySystemGroupedBackground).opacity(0.5))
          .cornerRadius(12)
          .overlay(
            RoundedRectangle(cornerRadius: 12)
              .stroke(Color.primary.opacity(0.05), lineWidth: 1)
          )
      } else {
        TextField("Enter \(param.name)", text: binding)
          .font(.subheadline)
          .padding(.horizontal, 12)
          .padding(.vertical, 12)
          .background(Color(UIColor.tertiarySystemGroupedBackground).opacity(0.5))
          .cornerRadius(12)
          .overlay(
            RoundedRectangle(cornerRadius: 12)
              .stroke(Color.primary.opacity(0.05), lineWidth: 1)
          )
      }
    }
  }

  private var buildControls: some View {
    VStack(spacing: 12) {
      // Build History Link
      NavigationLink(destination: HistoryView(job: viewModel.job)) {
        HStack {
          Image(systemName: "clock.arrow.circlepath")
          Text("View Build History")
        }
        .font(.headline)
        .foregroundColor(.blue)
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.blue.opacity(0.1))
        .cornerRadius(12)
      }

      Group {
        if viewModel.isTriggering {
          HStack {
            ProgressView()
            Text("Triggering...")
          }
          .frame(maxWidth: .infinity)
          .padding()
          .background(Color.blue.opacity(0.1))
          .cornerRadius(12)
        } else {
          Button(action: {
            Task { await viewModel.triggerBuild() }
          }) {
            HStack {
              Image(systemName: "play.fill")
              Text("Build Now")
            }
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.blue)
            .cornerRadius(12)
            .shadow(color: Color.blue.opacity(0.3), radius: 5, x: 0, y: 3)
          }
        }
      }
    }
  }

  // MARK: - Helpers

  private func scoreIcon(_ score: Int) -> some View {
    let iconName: String
    if score >= 80 {
      iconName = "sun.max.fill"
    } else if score >= 60 {
      iconName = "cloud.sun.fill"
    } else if score >= 40 {
      iconName = "cloud.fill"
    } else if score >= 20 {
      iconName = "cloud.rain.fill"
    } else {
      iconName = "cloud.heavyrain.fill"
    }

    return Image(systemName: iconName)
      .foregroundColor(scoreColor(score))
      .font(.title3)
  }

  private func scoreColor(_ score: Int) -> Color {
    if score >= 80 { return .orange }
    if score >= 60 { return .yellow }
    if score >= 40 { return .blue }
    if score >= 20 { return .purple }
    return .red
  }

  private func statusColor(_ result: String) -> Color {
    switch result.uppercased() {
    case "SUCCESS": return .green
    case "FAILURE": return .red
    case "ABORTED": return .gray
    case "UNSTABLE": return .orange
    default: return .gray
    }
  }

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

#Preview {
  NavigationStack {
    JobDetailView(
      job: JenkinsJob(
        name: "Example Job",
        url: "https://example.com",
        color: "blue",
        description: "A sample CI/CD pipeline for demonstration purposes.",
        jobs: nil,
        lastBuild: BuildSummary(number: 142, url: "https://example.com/142"),
        healthReport: [
          HealthReport(
            description: "Build stability: No recent builds failed.", iconClassName: "blue",
            score: 100)
        ],
        property: nil
      ))
  }
}
