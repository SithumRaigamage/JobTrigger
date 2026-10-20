import SwiftUI
import WidgetKit

// US-JX-23: pinned jobs on the home screen. Renders the snapshot the app
// writes (HomeWidgetBridge); it never fetches from Jenkins and holds no
// credentials. Must match HomeWidgetBridge.appGroupId and both targets'
// entitlements.
private let appGroupId = "group.Sraig.Lab-Trigger-frontend"
private let snapshotKey = "snapshot"

struct WidgetJob: Decodable, Identifiable {
  let label: String
  let link: String
  let status: String
  let statusText: String
  let buildNumber: Int?
  let buildTimestamp: Double?

  var id: String { link }
}

struct Snapshot: Decodable {
  let jobs: [WidgetJob]
  let updatedAt: Double
}

struct PinnedJobsEntry: TimelineEntry {
  let date: Date
  let snapshot: Snapshot?
}

struct PinnedJobsProvider: TimelineProvider {
  private static let sample = Snapshot(
    jobs: [
      WidgetJob(
        label: "api", link: "jobtrigger://app", status: "success",
        statusText: "Success", buildNumber: 42, buildTimestamp: nil),
      WidgetJob(
        label: "web", link: "jobtrigger://app", status: "failure",
        statusText: "Failed", buildNumber: 17, buildTimestamp: nil),
    ],
    updatedAt: Date().timeIntervalSince1970 * 1000)

  func placeholder(in context: Context) -> PinnedJobsEntry {
    PinnedJobsEntry(date: Date(), snapshot: Self.sample)
  }

  func getSnapshot(in context: Context, completion: @escaping (PinnedJobsEntry) -> Void) {
    completion(
      context.isPreview
        ? placeholder(in: context)
        : PinnedJobsEntry(date: Date(), snapshot: load()))
  }

  func getTimeline(
    in context: Context, completion: @escaping (Timeline<PinnedJobsEntry>) -> Void
  ) {
    // The app reloads the widget whenever it refreshes the pins; the
    // timeline only has to keep the relative times honest.
    let entry = PinnedJobsEntry(date: Date(), snapshot: load())
    completion(Timeline(entries: [entry], policy: .after(Date().addingTimeInterval(30 * 60))))
  }

  private func load() -> Snapshot? {
    guard
      let json = UserDefaults(suiteName: appGroupId)?.string(forKey: snapshotKey),
      let data = json.data(using: .utf8)
    else { return nil }
    return try? JSONDecoder().decode(Snapshot.self, from: data)
  }
}

struct PinnedJobsView: View {
  @Environment(\.widgetFamily) private var family
  let entry: PinnedJobsEntry

  private var capacity: Int { family == .systemSmall ? 2 : 4 }

  var body: some View {
    let jobs = Array((entry.snapshot?.jobs ?? []).prefix(capacity))
    VStack(alignment: .leading, spacing: 6) {
      HStack {
        Text("Pinned jobs")
          .font(.caption.bold())
          .foregroundStyle(Color.accentColor)
        Spacer()
        if let updatedAt = entry.snapshot?.updatedAt, !jobs.isEmpty {
          Text(Date(timeIntervalSince1970: updatedAt / 1000), style: .relative)
            .font(.caption2)
            .foregroundStyle(.secondary)
        }
      }
      if jobs.isEmpty {
        Spacer()
        Text("Pin jobs in JobTrigger")
          .font(.footnote)
          .foregroundStyle(.secondary)
          .frame(maxWidth: .infinity)
          .multilineTextAlignment(.center)
        Spacer()
      } else {
        ForEach(jobs) { job in
          if family == .systemSmall {
            JobRow(job: job)
          } else if let url = URL(string: job.link) {
            Link(destination: url) { JobRow(job: job) }
          }
        }
        Spacer(minLength: 0)
      }
    }
    .containerBackground(.fill.tertiary, for: .widget)
  }
}

struct JobRow: View {
  let job: WidgetJob

  private var color: Color {
    switch job.status {
    case "success": return .green
    case "failure": return .red
    case "unstable": return .orange
    case "running": return .blue
    default: return .gray
    }
  }

  var body: some View {
    HStack(spacing: 8) {
      Circle().fill(color).frame(width: 10, height: 10)
      VStack(alignment: .leading, spacing: 0) {
        Text(job.label).font(.subheadline.bold()).lineLimit(1)
        HStack(spacing: 0) {
          // Status is spelled out, never color alone (NFR-A11Y-03).
          Text(job.statusText)
          if let number = job.buildNumber { Text(" · #\(number)") }
        }
        .font(.caption)
        .foregroundStyle(.secondary)
        .lineLimit(1)
      }
    }
    .accessibilityElement(children: .combine)
  }
}

@main
struct PinnedJobsWidget: Widget {
  var body: some WidgetConfiguration {
    StaticConfiguration(kind: "PinnedJobsWidget", provider: PinnedJobsProvider()) { entry in
      PinnedJobsView(entry: entry)
    }
    .configurationDisplayName("Pinned jobs")
    .description("Your pinned Jenkins jobs at a glance.")
    // A small widget is one tap target, so it opens the app (pins lead
    // Home); a medium one links each job.
    .supportedFamilies([.systemSmall, .systemMedium])
  }
}
