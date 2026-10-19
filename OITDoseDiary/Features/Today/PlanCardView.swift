import SwiftUI

struct PlanCardView: View {
    let plan: DosePlan
    let records: [DoseRecord]
    let onLogDose: () -> Void
    let onLogReaction: () -> Void
    let onEdit: () -> Void
    let onUpDose: () -> Void

    private var todayRecords: [DoseRecord] { records.filter { Calendar.current.isDateInToday($0.date) } }
    private var takenToday: DoseRecord? { todayRecords.first { !$0.skipped } }
    private var skippedToday: DoseRecord? { takenToday == nil ? todayRecords.first { $0.skipped } : nil }
    private var streak: Int { AdherenceStats.streak(records: records) }

    private var restEnd: Date? {
        takenToday.map { $0.date.addingTimeInterval(TimeInterval(plan.restMinutes * 60)) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(plan.title).font(.title3.bold())
                    Text(plan.phase).font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                Menu {
                    Button("Record up-dose", systemImage: "arrow.up.circle", action: onUpDose)
                    Button("Edit plan", systemImage: "pencil", action: onEdit)
                } label: {
                    Image(systemName: "ellipsis.circle").font(.title3)
                }
                .accessibilityLabel("Plan options")
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("Today's dose").font(.caption).foregroundStyle(.secondary)
                Text(plan.doseLabel).font(.title2.weight(.semibold)).monospacedDigit()
            }

            statusSection

            HStack(spacing: 16) {
                WeekDots(records: records)
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text(streak == 0 ? "No streak yet" : "\(streak) day\(streak == 1 ? "" : "s") in a row")
                        .font(.caption).foregroundStyle(.secondary)
                    if let visit = plan.nextVisit {
                        Text(visitText(visit)).font(.caption).foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding(18)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
    }

    @ViewBuilder
    private var statusSection: some View {
        if let taken = takenToday, let restEnd {
            VStack(alignment: .leading, spacing: 10) {
                Label("Taken at \(Formatters.time.string(from: taken.date))", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(Color.accentColor)
                    .font(.headline)
                if restEnd > .now {
                    HStack {
                        Text("Rest period ends in")
                            .accessibilityIdentifier("Rest period ends in")
                        Text(timerInterval: taken.date...restEnd, countsDown: true)
                            .monospacedDigit().bold()
                    }
                    .font(.subheadline)
                } else {
                    Text("Rest period done").font(.subheadline).foregroundStyle(.secondary)
                }
                Button(action: onLogReaction) {
                    Label("Log a reaction", systemImage: "exclamationmark.triangle")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
        } else if let skipped = skippedToday {
            VStack(alignment: .leading, spacing: 10) {
                Label("Skipped today\(skipped.skipReason.isEmpty ? "" : ": \(skipped.skipReason)")", systemImage: "minus.circle")
                    .font(.headline).foregroundStyle(.secondary)
                Button("Log the dose anyway", action: onLogDose).buttonStyle(.bordered)
            }
        } else {
            VStack(spacing: 10) {
                Button(action: onLogDose) {
                    Label("Log today's dose", systemImage: "pills.circle.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                Button(action: onLogReaction) {
                    Label("Log a reaction", systemImage: "exclamationmark.triangle")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
        }
    }

    private func visitText(_ visit: Date) -> String {
        let days = Calendar.current.dateComponents([.day], from: Calendar.current.startOfDay(for: .now), to: Calendar.current.startOfDay(for: visit)).day ?? 0
        let when = days == 0 ? "today" : days == 1 ? "tomorrow" : days < 0 ? "was \(Formatters.date.string(from: visit))" : "in \(days) days"
        return "Clinic visit \(when)"
    }
}

/// Seven dots for the last seven days: filled = taken, minus = skipped, empty = not logged.
struct WeekDots: View {
    let records: [DoseRecord]

    private var days: [Date] {
        (0..<7).reversed().compactMap { Calendar.current.date(byAdding: .day, value: -$0, to: Calendar.current.startOfDay(for: .now)) }
    }

    var body: some View {
        HStack(spacing: 6) {
            ForEach(days, id: \.self) { day in
                let status = AdherenceStats.status(of: records, on: day)
                Image(systemName: status == .taken ? "circle.fill" : status == .skipped ? "minus.circle" : "circle")
                    .font(.system(size: 11))
                    .foregroundStyle(status == .taken ? Color.accentColor : Color.secondary)
                    .accessibilityLabel("\(day.formatted(date: .abbreviated, time: .omitted)): \(status == .taken ? "taken" : status == .skipped ? "skipped" : "not logged")")
            }
        }
    }
}
