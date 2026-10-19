import SwiftUI
import SwiftData

/// Doses, reactions and up-doses in one timeline, newest first, grouped by month.
struct HistoryView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \DosePlan.createdAt) private var plans: [DosePlan]
    @Query(sort: \DoseRecord.date, order: .reverse) private var records: [DoseRecord]
    @Query(sort: \Reaction.date, order: .reverse) private var reactions: [Reaction]
    @Query(sort: \DoseChange.date, order: .reverse) private var changes: [DoseChange]

    @State private var planFilter: UUID?
    @State private var editingRecord: DoseRecord?
    @State private var editingReaction: Reaction?

    private enum Item: Identifiable {
        case dose(DoseRecord), reaction(Reaction), change(DoseChange)
        var id: UUID {
            switch self {
            case .dose(let r): r.id
            case .reaction(let r): r.id
            case .change(let c): c.id
            }
        }
        var date: Date {
            switch self {
            case .dose(let r): r.date
            case .reaction(let r): r.date
            case .change(let c): c.date
            }
        }
        var planID: UUID {
            switch self {
            case .dose(let r): r.planID
            case .reaction(let r): r.planID
            case .change(let c): c.planID
            }
        }
    }

    private var plansByID: [UUID: DosePlan] { Dictionary(uniqueKeysWithValues: plans.map { ($0.id, $0) }) }

    private var items: [Item] {
        var all = records.map(Item.dose) + reactions.map(Item.reaction) + changes.map(Item.change)
        if let planFilter { all = all.filter { $0.planID == planFilter } }
        return all.sorted { $0.date > $1.date }
    }

    private var sections: [(month: Date, items: [Item])] {
        let calendar = Calendar.current
        let groups = Dictionary(grouping: items) { item in
            calendar.date(from: calendar.dateComponents([.year, .month], from: item.date)) ?? item.date
        }
        return groups.keys.sorted(by: >).map { (month: $0, items: groups[$0] ?? []) }
    }

    var body: some View {
        NavigationStack {
            Group {
                if items.isEmpty {
                    ContentUnavailableView("Nothing logged yet", systemImage: "calendar", description: Text("Doses, reactions and up-doses will appear here."))
                } else {
                    List {
                        ForEach(sections, id: \.month) { section in
                            Section(Formatters.month.string(from: section.month)) {
                                ForEach(section.items) { item in
                                    row(for: item)
                                }
                                .onDelete { offsets in delete(offsets.map { section.items[$0] }) }
                            }
                        }
                    }
                }
            }
            .navigationTitle("History")
            .toolbar {
                if plans.count > 1 {
                    ToolbarItem(placement: .topBarTrailing) {
                        Menu {
                            Picker("Plan", selection: $planFilter) {
                                Text("All plans").tag(UUID?.none)
                                ForEach(plans) { Text($0.title).tag(Optional($0.id)) }
                            }
                        } label: {
                            Image(systemName: "line.3.horizontal.decrease.circle")
                        }
                        .accessibilityLabel("Filter by plan")
                    }
                }
            }
            .sheet(item: $editingRecord) { record in
                if let plan = plansByID[record.planID] { LogDoseSheet(plan: plan, record: record) }
            }
            .sheet(item: $editingReaction) { reaction in
                if let plan = plansByID[reaction.planID] { ReactionEditorView(plan: plan, reaction: reaction) }
            }
        }
    }

    @ViewBuilder
    private func row(for item: Item) -> some View {
        let planTitle = plans.count > 1 ? plansByID[item.planID]?.title : nil
        switch item {
        case .dose(let record):
            Button { editingRecord = record } label: {
                HistoryRow(
                    symbol: record.skipped ? "minus.circle" : "checkmark.circle.fill",
                    tint: record.skipped ? .secondary : .accentColor,
                    title: record.skipped ? "Skipped\(record.skipReason.isEmpty ? "" : " · \(record.skipReason)")" : record.amountLabel,
                    subtitle: [planTitle, record.cofactors.map(\.rawValue).joined(separator: ", "), record.notes].compactMap { $0 }.filter { !$0.isEmpty }.joined(separator: " · "),
                    date: record.date
                )
            }
            .buttonStyle(.plain)
        case .reaction(let reaction):
            Button { editingReaction = reaction } label: {
                HistoryRow(
                    symbol: "exclamationmark.triangle.fill",
                    tint: .orange,
                    title: "\(reaction.severityValue.label) reaction\(reaction.minutesAfterDose.map { " · \($0) min after dose" } ?? "")",
                    subtitle: [planTitle, reaction.symptomsLabel, reaction.treatment == .none ? nil : reaction.treatment.rawValue].compactMap { $0 }.joined(separator: " · "),
                    date: reaction.date
                )
            }
            .buttonStyle(.plain)
        case .change(let change):
            HistoryRow(
                symbol: "arrow.up.circle.fill",
                tint: .blue,
                title: "Dose changed \(change.label)",
                subtitle: [planTitle, change.note].compactMap { $0 }.filter { !$0.isEmpty }.joined(separator: " · "),
                date: change.date
            )
        }
    }

    private func delete(_ toDelete: [Item]) {
        for item in toDelete {
            switch item {
            case .dose(let r): context.delete(r)
            case .reaction(let r): context.delete(r)
            case .change(let c): context.delete(c)
            }
        }
    }
}

struct HistoryRow: View {
    let symbol: String
    let tint: Color
    let title: String
    let subtitle: String
    let date: Date

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: symbol).foregroundStyle(tint).font(.title3).frame(width: 24)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.body)
                if !subtitle.isEmpty {
                    Text(subtitle).font(.caption).foregroundStyle(.secondary).lineLimit(2)
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text(date.formatted(.dateTime.day().month(.abbreviated))).font(.caption).monospacedDigit()
                Text(date.formatted(date: .omitted, time: .shortened)).font(.caption2).foregroundStyle(.secondary)
            }
        }
        .contentShape(Rectangle())
    }
}
