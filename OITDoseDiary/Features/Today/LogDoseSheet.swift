import SwiftUI
import SwiftData

/// Add or edit one day's dose record. Saving is the app's success moment.
struct LogDoseSheet: View {
    let plan: DosePlan
    let record: DoseRecord?

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Environment(\.requestReview) private var requestReview

    @State private var date: Date = .now
    @State private var amount: Double = 0
    @State private var unit: DoseUnit = .mg
    @State private var form = ""
    @State private var takenWithFood = true
    @State private var skipped = false
    @State private var skipReason = ""
    @State private var cofactors: Set<Cofactor> = []
    @State private var notes = ""

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    DatePicker("When", selection: $date)
                    Toggle("Skipped this dose", isOn: $skipped)
                }

                if skipped {
                    Section("Why") {
                        TextField("Sick, travelling, ran out…", text: $skipReason)
                    }
                } else {
                    Section("Dose") {
                        HStack {
                            TextField("Amount", value: $amount, format: .number)
                                .keyboardType(.decimalPad)
                            Picker("Unit", selection: $unit) {
                                ForEach(DoseUnit.allCases) { Text($0.rawValue).tag($0) }
                            }
                            .labelsHidden()
                        }
                        TextField("Form (peanut flour, Bamba, capsule)", text: $form)
                        Toggle("Taken with food", isOn: $takenWithFood)
                        if amount != plan.doseAmount || unit.rawValue != plan.doseUnit {
                            Text("Differs from the plan's current dose (\(plan.doseLabel)). Use \"Record up-dose\" on the plan if the prescription changed.")
                                .font(.footnote).foregroundStyle(.secondary)
                        }
                    }
                    Section("Anything else going on?") {
                        ChipPicker(options: Cofactor.allCases, label: { $0.rawValue }, selection: $cofactors)
                    }
                }

                Section("Notes") {
                    TextEditor(text: $notes).frame(minHeight: 80)
                }
            }
            .navigationTitle(record == nil ? "Log Dose" : "Edit Dose")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("Save") { save() }.bold() }
            }
            .onAppear(perform: load)
        }
    }

    private func load() {
        if let record {
            date = record.date
            amount = record.amount
            unit = DoseUnit(rawValue: record.unit) ?? .mg
            form = record.form
            takenWithFood = record.takenWithFood
            skipped = record.skipped
            skipReason = record.skipReason
            cofactors = Set(record.cofactors)
            notes = record.notes
        } else {
            amount = plan.doseAmount
            unit = DoseUnit(rawValue: plan.doseUnit) ?? .mg
            form = plan.doseForm
        }
    }

    private func save() {
        let target = record ?? DoseRecord(plan: plan, date: date)
        target.date = date
        target.amount = amount
        target.unit = unit.rawValue
        target.form = form
        target.takenWithFood = takenWithFood
        target.skipped = skipped
        target.skipReason = skipped ? skipReason : ""
        target.cofactors = skipped ? [] : Array(cofactors)
        target.notes = notes
        if record == nil { context.insert(target) }

        if !skipped, Calendar.current.isDateInToday(date) {
            let planID = plan.id, rest = plan.restMinutes, title = plan.title
            Task { await NotificationScheduler.scheduleRestOver(planID: planID, doseTakenAt: date, restMinutes: rest, planTitle: title) }
        }
        ReviewPrompter.recordSuccess(request: requestReview)
        dismiss()
    }
}
