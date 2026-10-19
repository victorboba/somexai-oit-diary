import WidgetKit
import SwiftUI

struct SnapshotEntry: TimelineEntry {
    let date: Date
    let snapshot: WidgetSnapshot
}

struct SnapshotProvider: TimelineProvider {
    func placeholder(in context: Context) -> SnapshotEntry {
        SnapshotEntry(date: .now, snapshot: .placeholder)
    }

    func getSnapshot(in context: Context, completion: @escaping (SnapshotEntry) -> Void) {
        completion(SnapshotEntry(date: .now, snapshot: context.isPreview ? .placeholder : WidgetSnapshot.load()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SnapshotEntry>) -> Void) {
        let entry = SnapshotEntry(date: .now, snapshot: WidgetSnapshot.load())
        // Refresh at the next midnight so "not logged yet" resets, plus hourly as a fallback.
        let calendar = Calendar.current
        let midnight = calendar.startOfDay(for: calendar.date(byAdding: .day, value: 1, to: .now) ?? .now)
        let hourly = calendar.date(byAdding: .hour, value: 1, to: .now) ?? midnight
        completion(Timeline(entries: [entry], policy: .after(min(midnight, hourly))))
    }
}

struct OITDoseDiaryWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: SnapshotEntry

    private var snapshot: WidgetSnapshot { entry.snapshot }
    private var loggedToday: Bool { snapshot.todayTakenAt.map { Calendar.current.isDateInToday($0) } ?? false }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(snapshot.planTitle.isEmpty ? AppConfig.appName : snapshot.planTitle)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .lineLimit(1)

            if snapshot.planTitle.isEmpty {
                Text("Set up a dosing plan").font(.headline)
            } else if loggedToday, let time = snapshot.todayTakenAt {
                Label("Taken \(time.formatted(date: .omitted, time: .shortened))", systemImage: "checkmark.circle.fill")
                    .font(.headline)
                    .foregroundStyle(.tint)
            } else if snapshot.todaySkipped {
                Label("Skipped today", systemImage: "minus.circle").font(.headline).foregroundStyle(.secondary)
            } else {
                Label("Not logged yet", systemImage: "circle").font(.headline)
            }

            Text(snapshot.doseLabel).font(.caption).foregroundStyle(.secondary).lineLimit(1)

            Spacer(minLength: 0)

            HStack {
                if snapshot.streakDays > 0 {
                    Text("\(snapshot.streakDays)d streak").font(.caption2).monospacedDigit()
                }
                if family != .systemSmall, let visit = snapshot.nextVisit {
                    Spacer()
                    Text("Visit \(visit.formatted(.dateTime.month(.abbreviated).day()))").font(.caption2)
                }
            }
            .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

struct OITDoseDiaryWidget: Widget {
    let kind = "OITDoseDiaryWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: SnapshotProvider()) { entry in
            OITDoseDiaryWidgetView(entry: entry)
        }
        .configurationDisplayName(AppConfig.appName)
        .description("Whether today's dose is logged, your streak and the next clinic visit.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

@main
struct OITDoseDiaryWidgetBundle: WidgetBundle {
    var body: some Widget {
        OITDoseDiaryWidget()
    }
}
