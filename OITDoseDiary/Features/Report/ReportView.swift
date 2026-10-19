import SwiftUI
import SwiftData

/// Summary numbers for a plan over a period, and the exports the allergist gets.
struct ReportView: View {
    @Query(sort: \DosePlan.createdAt) private var plans: [DosePlan]
    @Query(sort: \DoseRecord.date, order: .reverse) private var records: [DoseRecord]
    @Query(sort: \Reaction.date, order: .reverse) private var reactions: [Reaction]
    @Query(sort: \DoseChange.date, order: .reverse) private var changes: [DoseChange]

    @State private var selectedPlanID: UUID?
    @State private var period: Period = .days30
    @State private var exportFile: ExportFile?
    @State private var exportError: String?

    enum Period: String, CaseIterable, Identifiable {
        case days30 = "30 days", days90 = "90 days", days180 = "6 months", all = "All"
        var id: String { rawValue }
        func start(planStart: Date) -> Date {
            switch self {
            case .days30: Calendar.current.date(byAdding: .day, value: -29, to: .now) ?? planStart
            case .days90: Calendar.current.date(byAdding: .day, value: -89, to: .now) ?? planStart
            case .days180: Calendar.current.date(byAdding: .day, value: -179, to: .now) ?? planStart
            case .all: planStart
            }
        }
    }

    /// The chosen plan, else the plan with the most recent dose, else the first active plan.
    private var plan: DosePlan? {
        if let selectedPlanID, let chosen = plans.first(where: { $0.id == selectedPlanID }) { return chosen }
        if let latest = records.first, let logged = plans.first(where: { $0.id == latest.planID }) { return logged }
        return plans.first { $0.isActive } ?? plans.first
    }

    private var planStartDay: Date {
        Calendar.current.startOfDay(for: plan?.startDate ?? .now)
    }

    /// Period start, never earlier than the day the plan started.
    private var start: Date {
        guard let plan else { return .now }
        return max(period.start(planStart: plan.startDate), planStartDay)
    }

    private var isClampedToPlanStart: Bool {
        guard let plan, period != .all else { return false }
        return period.start(planStart: plan.startDate) < planStartDay
    }

    private var stats: AdherenceStats {
        guard let plan else { return AdherenceStats() }
        return AdherenceStats.compute(
            records: records.filter { $0.planID == plan.id },
            reactions: reactions.filter { $0.planID == plan.id },
            from: start
        )
    }

    var body: some View {
        NavigationStack {
            Group {
                if let plan {
                    List {
                        if plans.count > 1 {
                            Section {
                                Picker("Plan", selection: Binding(get: { plan.id }, set: { selectedPlanID = $0 })) {
                                    ForEach(plans) { Text($0.title).tag($0.id) }
                                }
                            }
                        }
                        Section {
                            Picker("Period", selection: $period) {
                                ForEach(Period.allCases) { Text($0.rawValue).tag($0) }
                            }
                            .pickerStyle(.segmented)
                            .listRowBackground(Color.clear)
                            .listRowInsets(EdgeInsets())
                        }
                        Section {
                            StatRow(label: "Doses taken", value: stats.taken, total: stats.days)
                            StatRow(label: "Doses skipped", value: stats.skipped, total: stats.days)
                            StatRow(label: "Days not logged", value: stats.unlogged, total: stats.days)
                            LabeledContent("Reactions", value: "\(stats.reactions)")
                            LabeledContent("Current streak", value: "\(stats.currentStreak) day\(stats.currentStreak == 1 ? "" : "s")")
                            LabeledContent("Current dose", value: plan.doseLabel)
                            LabeledContent("Dose changes", value: "\(changes.filter { $0.planID == plan.id && $0.date >= start }.count)")
                        } header: {
                            Text("\(plan.title) · \(Formatters.date.string(from: start)) to today · \(stats.days) day\(stats.days == 1 ? "" : "s")")
                        } footer: {
                            if isClampedToPlanStart {
                                Text("This plan started on \(Formatters.date.string(from: plan.startDate)), so the report covers \(stats.days) day\(stats.days == 1 ? "" : "s"), not the full \(period.rawValue). Edit the plan's start date if it began earlier.")
                            }
                        }
                        Section("Export") {
                            Button { export { try ReportExporter.export(plan: plan, records: records, reactions: reactions, changes: changes, from: start) } } label: {
                                Label("PDF report for the allergist", systemImage: "doc.richtext")
                            }
                            Button { export { try CSVExporter.write(CSVExporter.doseCSV(records: records.filter { $0.planID == plan.id && $0.date >= start }, plans: plansByID), suffix: "doses") } } label: {
                                Label("Dose log CSV", systemImage: "tablecells")
                            }
                            Button { export { try CSVExporter.write(CSVExporter.reactionCSV(reactions: reactions.filter { $0.planID == plan.id && $0.date >= start }, plans: plansByID), suffix: "reactions") } } label: {
                                Label("Reactions CSV", systemImage: "tablecells")
                            }
                        }
                        Section {
                            Text(AppConfig.disclaimer).font(.footnote).foregroundStyle(.secondary)
                        }
                    }
                } else {
                    ContentUnavailableView("No dosing plan yet", systemImage: "doc.text", description: Text("Set up a plan on Today to start a report."))
                }
            }
            .navigationTitle("Report")
            .sheet(item: $exportFile) { file in ShareSheet(url: file.url) }
            .alert("Export failed", isPresented: Binding(get: { exportError != nil }, set: { if !$0 { exportError = nil } })) {
                Button("OK") { exportError = nil }
            } message: {
                Text(exportError ?? "")
            }
        }
    }

    private var plansByID: [UUID: DosePlan] { Dictionary(uniqueKeysWithValues: plans.map { ($0.id, $0) }) }

    private func export(_ make: () throws -> URL) {
        do { exportFile = ExportFile(url: try make()) } catch { exportError = error.localizedDescription }
    }
}

private struct StatRow: View {
    let label: String
    let value: Int
    let total: Int

    var body: some View {
        HStack {
            Text(label)
            Spacer()
            Text("\(value)").monospacedDigit()
            if total > 0 {
                Text("(\(Int((Double(value) / Double(total) * 100).rounded()))%)")
                    .foregroundStyle(.secondary).monospacedDigit()
            }
        }
    }
}
