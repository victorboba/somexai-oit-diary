import SwiftUI
import SwiftData

/// Records a prescribed dose change (usually an up-dose after a clinic visit) and updates the plan.
struct UpDoseSheet: View {
    let plan: DosePlan

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var date: Date = .now
    @State private var amount: Double = 0
    @State private var unit: DoseUnit = .mg
    @State private var form = ""
    @State private var note = ""
    @State private var phase: Phase = .buildUp

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    LabeledContent("Current dose", value: plan.doseLabel)
                    DatePicker("Changed on", selection: $date, displayedComponents: .date)
                }
                Section("New prescribed dose") {
                    HStack {
                        TextField("Amount", value: $amount, format: .number)
                            .keyboardType(.decimalPad)
                        Picker("Unit", selection: $unit) {
                            ForEach(DoseUnit.allCases) { Text($0.rawValue).tag($0) }
                        }
                        .labelsHidden()
                    }
                    TextField("Form", text: $form)
                    Picker("Phase", selection: $phase) {
                        ForEach(Phase.allCases) { Text($0.rawValue).tag($0) }
                    }
                }
                Section("Note") {
                    TextField("Up-dose visit, tolerated in clinic…", text: $note)
                }
                Section {
                    Text("Only record a change your allergist made. The report lists every change with its date.")
                        .font(.footnote).foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Record Dose Change")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("Save") { save() }.bold().disabled(amount <= 0) }
            }
            .onAppear {
                amount = plan.doseAmount
                unit = DoseUnit(rawValue: plan.doseUnit) ?? .mg
                form = plan.doseForm
                phase = Phase(rawValue: plan.phase) ?? .buildUp
            }
        }
    }

    private func save() {
        let change = DoseChange(plan: plan, date: date, toAmount: amount, unit: unit.rawValue, form: form, note: note)
        context.insert(change)
        plan.doseAmount = amount
        plan.doseUnit = unit.rawValue
        plan.doseForm = form
        plan.phase = phase.rawValue
        dismiss()
    }
}
