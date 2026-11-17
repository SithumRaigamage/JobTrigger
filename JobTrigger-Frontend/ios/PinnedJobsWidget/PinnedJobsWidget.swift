import SwiftUI
import WidgetKit

// US-JX-23: pinned jobs on the home screen. Renders the snapshot the app
// writes (HomeWidgetBridge); it never fetches from Jenkins and holds no
// credentials. Must match HomeWidgetBridge.appGroupId and both targets'
// entitlements.
private let appGroupId = "group.Sraig.Lab-Trigger-frontend"
private let snapshotKey = "snapshot"
// US-SQ-WIDGET-01: pinned SonarQube projects reuse everything here under their
// own key and wording. The widget renders a snapshot the app wrote; it never
// calls SonarQube and holds no credential.
private let projectsSnapshotKey = "sonarqube_snapshot"

/// The words that differ between the two widgets.
struct WidgetCopy {
  let title: String
  let empty: String
  let noun: String  // "job" / "project"
  let upgrade: String
  let description: String

  static let jobs = WidgetCopy(
    title: "Pinned jobs", empty: "Pin jobs in JobTrigger", noun: "job",
    upgrade: "Pinned jobs need Pro. Open JobTrigger to upgrade.",
    description: "Your pinned Jenkins jobs at a glance.")
  static let projects = WidgetCopy(
    title: "Pinned projects", empty: "Pin projects in JobTrigger", noun: "project",
    upgrade: "Pinned projects need Pro. Open JobTrigger to upgrade.",
    description: "Your pinned SonarQube projects and their quality gate.")
}

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
  /// Set while the app lock is on (AUD-54): only how many jobs are pinned
  /// leaves the app. Absent from snapshots written before P14-25.
  let lockedCount: Int?
  /// P20-25: on Free with billing on, the app writes no jobs and this flag,
  /// so the widget says why instead of looking empty. Absent means no.
  let upgradeRequired: Bool?
}

struct PinnedJobsEntry: TimelineEntry {
  let date: Date
  let snapshot: Snapshot?
}

struct PinnedJobsProvider: TimelineProvider {
  var key: String = snapshotKey

  private static let sample = Snapshot(
    jobs: [
      WidgetJob(
        label: "api", link: "jobtrigger://app", status: "success",
        statusText: "Success", buildNumber: 42, buildTimestamp: nil),
      WidgetJob(
        label: "web", link: "jobtrigger://app", status: "failure",
        statusText: "Failed", buildNumber: 17, buildTimestamp: nil),
    ],
    updatedAt: Date().timeIntervalSince1970 * 1000, lockedCount: nil,
    upgradeRequired: nil)

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
      let json = UserDefaults(suiteName: appGroupId)?.string(forKey: key),
      let data = json.data(using: .utf8)
    else { return nil }
    return try? JSONDecoder().decode(Snapshot.self, from: data)
  }
}

/// The app's P14 palette (AppColors), light and dark
/// (`UI-UX/screens/24-home-widget-notification`).
private func dynamic(_ light: UInt32, _ dark: UInt32) -> Color {
  func ui(_ hex: UInt32) -> UIColor {
    UIColor(
      red: CGFloat((hex >> 16) & 0xFF) / 255,
      green: CGFloat((hex >> 8) & 0xFF) / 255,
      blue: CGFloat(hex & 0xFF) / 255,
      alpha: 1)
  }
  return Color(
    UIColor { $0.userInterfaceStyle == .dark ? ui(dark) : ui(light) })
}

private enum Palette {
  static let background = dynamic(0xFFFFFF, 0x0B1120)
  static let text = dynamic(0x0F172A, 0xF1F5F9)
  static let secondary = dynamic(0x334155, 0xCBD5E1)
  static let muted = dynamic(0x475569, 0x94A3B8)

  /// (text, dot) per status.
  static func status(_ status: String) -> (Color, Color) {
    switch status {
    case "success": return (dynamic(0x15803D, 0x86EFAC), dynamic(0x16A34A, 0x4ADE80))
    case "failure": return (dynamic(0xB91C1C, 0xFCA5A5), dynamic(0xDC2626, 0xF87171))
    case "unstable": return (dynamic(0xC2410C, 0xFDBA74), dynamic(0xEA580C, 0xFB923C))
    case "running": return (dynamic(0x1D4ED8, 0x93C5FD), dynamic(0x2563EB, 0x60A5FA))
    default: return (dynamic(0x334155, 0xCBD5E1), dynamic(0x64748B, 0x94A3B8))
    }
  }
}

struct PinnedJobsView: View {
  @Environment(\.widgetFamily) private var family
  let entry: PinnedJobsEntry
  var copy: WidgetCopy = .jobs

  private var capacity: Int { family == .systemSmall ? 2 : 4 }

  var body: some View {
    Group {
      if let count = entry.snapshot?.lockedCount {
        LockedView(count: count, noun: copy.noun)
      } else if entry.snapshot?.upgradeRequired == true {
        UpgradeView(message: copy.upgrade)
      } else {
        jobsView
      }
    }
    .containerBackground(Palette.background, for: .widget)
  }

  private var jobsView: some View {
    let jobs = Array((entry.snapshot?.jobs ?? []).prefix(capacity))
    return VStack(alignment: .leading, spacing: 8) {
      HStack {
        Text(copy.title)
          .font(.caption.weight(.semibold))
          .foregroundStyle(Palette.secondary)
        Spacer()
        if let updatedAt = entry.snapshot?.updatedAt, !jobs.isEmpty,
          family != .systemSmall
        {
          (Text("Updated ")
            + Text(Date(timeIntervalSince1970: updatedAt / 1000), style: .relative)
            + Text(" ago"))
            .font(.caption)
            .foregroundStyle(Palette.muted)
        }
      }
      if jobs.isEmpty {
        Spacer()
        Text(copy.empty)
          .font(.footnote)
          .foregroundStyle(Palette.muted)
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
  }
}

/// The app lock is on: say how many, not which (AUD-54).
struct LockedView: View {
  let count: Int
  var noun: String = "job"

  var body: some View {
    HStack(spacing: 12) {
      Image(systemName: "lock")
        .font(.title3)
        .foregroundStyle(Palette.secondary)
        .accessibilityHidden(true)
      VStack(alignment: .leading, spacing: 2) {
        Text(count == 1 ? "1 pinned \(noun)" : "\(count) pinned \(noun)s")
          .font(.subheadline.weight(.semibold))
          .foregroundStyle(Palette.text)
        Text("Unlock JobTrigger to see them")
          .font(.caption)
          .foregroundStyle(Palette.muted)
      }
      Spacer(minLength: 0)
    }
    .accessibilityElement(children: .combine)
  }
}

/// P20-25: pinned jobs are a Pro feature, so on Free the widget asks for the
/// upgrade instead of pretending nothing is pinned.
struct UpgradeView: View {
  var message: String = "Pinned jobs need Pro. Open JobTrigger to upgrade."

  var body: some View {
    VStack(alignment: .leading, spacing: 4) {
      Text("Upgrade to Pro")
        .font(.subheadline.weight(.semibold))
        .foregroundStyle(Palette.text)
      Text(message)
        .font(.caption)
        .foregroundStyle(Palette.muted)
        .fixedSize(horizontal: false, vertical: true)
      Spacer(minLength: 0)
    }
    .accessibilityElement(children: .combine)
  }
}

struct JobRow: View {
  let job: WidgetJob

  var body: some View {
    let (text, dot) = Palette.status(job.status)
    HStack(spacing: 8) {
      Circle().fill(dot).frame(width: 8, height: 8)
      Text(job.label)
        .font(.subheadline.weight(.medium))
        .foregroundStyle(Palette.text)
        .lineLimit(1)
      Spacer(minLength: 4)
      // Status is spelled out, never color alone (NFR-A11Y-03).
      Text(job.statusText)
        .font(.caption.weight(.semibold))
        .foregroundStyle(text)
        .lineLimit(1)
    }
    .accessibilityElement(children: .combine)
  }
}

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

/// US-SQ-WIDGET-01: the same widget for pinned SonarQube projects, each row
/// showing the quality-gate verdict and linking to the project.
struct PinnedProjectsWidget: Widget {
  var body: some WidgetConfiguration {
    StaticConfiguration(
      kind: "PinnedProjectsWidget", provider: PinnedJobsProvider(key: projectsSnapshotKey)
    ) { entry in
      PinnedJobsView(entry: entry, copy: .projects)
    }
    .configurationDisplayName("Pinned projects")
    .description(WidgetCopy.projects.description)
    .supportedFamilies([.systemSmall, .systemMedium])
  }
}

@main
struct JobTriggerWidgets: WidgetBundle {
  var body: some Widget {
    PinnedJobsWidget()
    PinnedProjectsWidget()
  }
}
