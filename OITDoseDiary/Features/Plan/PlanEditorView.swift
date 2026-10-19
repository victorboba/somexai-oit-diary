import SwiftUI
import SwiftData

/// Create or edit a dosing plan: what the allergist prescribed, the clinic's rules, reminders and visits.
struct PlanEditorView: View {
    let plan: DosePlan?

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var patientName = ""
    @State private var allergen = ""
    @State private var doseAmount: Double = 0
    @State private var doseUnit: DoseUnit = .mg
    @State private var doseForm = ""
    @State private var phase: Phase = .buildUp
    @State private var restMinutes = AppConfig.defaultRestMinutes
    @State private var reminderEnabled = false
    @State private var reminderTime = Calendar.current.date(bySettingHour: 18, minute: 0, second: 0, of: .now) ?? .now
    @State private var clinicName = ""
    @State private var clinicPhone = ""
    @State private var clinicInstructions = ""
    @State private var hasNextVisit = false
    @State private var nextVisit = Calendar.current.date(byAdding: .day, value: 14, to: .now) ?? .now
    @State private var startDate = Date.now
    @State private var confirmingDelete = false
    @State private var confirmingArchive = false

    private var canSave: Bool { !allergen.trimmingCharacters(in: .whitespaces).isEmpty && doseAmount > 0 }

    var body: some View {
        NavigationStack {
            Form {
                Section("Who") {
                    TextField("Patient name (optional)", text: $patientName)
                        .textContentType(.givenName)
                    TextField("Allergen", text: $allergen)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(Allergens.common, id: \.self) { name in
                                Button(name) { allergen = name }
                                    .buttonStyle(.bordered)
                                    .controlSize(.small)
                                    .tint(allergen == name ? .accentColor : .secondary)
                            }
                        }
                    }
                    .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 8, trailing: 0))
                }

                Section("Prescribed dose") {
                    HStack {
                        TextField("Amount", value: $doseAmount, format: .number)
                            .keyboardType(.decimalPad)
                        Picker("Unit", selection: $doseUnit) {
                            ForEach(DoseUnit.allCases) { Text($0.rawValue).tag($0) }
                        }
                        .labelsHidden()
                    }
                    TextField("Form (peanut flour, Bamba, capsule, whole milk)", text: $doseForm)
                    Picker("Phase", selection: $phase) {
                        ForEach(Phase.allCases) { Text($0.rawValue).tag($0) }
                    }
                    DatePicker("Plan started", selection: $startDate, displayedComponents: .date)
                    Text("Enter exactly what your allergist prescribed. The app never suggests a dose.")
                        .font(.footnote).foregroundStyle(.secondary)
                }

                Section("Rest and reminder") {
                    Stepper("Rest after dose: \(Formatters.minutes(restMinutes))", value: $restMinutes, in: 0...240, step: 15)
                    Toggle("Daily reminder", isOn: $reminderEnabled)
                    if reminderEnabled {
                        DatePicker("Remind at", selection: $reminderTime, displayedComponents: .hourAndMinute)
                    }
                }

                Section("Clinic") {
                    TextField("Clinic or allergist", text: $clinicName)
                    TextField("Phone", text: $clinicPhone)
                        .keyboardType(.phonePad)
                        .textContentType(.telephoneNumber)
                    Toggle("Next visit scheduled", isOn: $hasNextVisit)
                    if hasNextVisit {
                        DatePicker("Next visit", selection: $nextVisit, displayedComponents: .date)
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Clinic instructions").font(.subheadline)
                        Text("Missed-dose and sick-day rules, in your clinic's words. Shown on the report.")
                            .font(.footnote).foregroundStyle(.secondary)
                        TextEditor(text: $clinicInstructions).frame(minHeight: 90)
                    }
                }

                if plan != nil {
                    Section {
                        Button("Archive plan (keeps history)") { confirmingArchive = true }
                        Button("Delete plan and all its records", role: .destructive) { confirmingDelete = true }
                    }
                }
            }
            .navigationTitle(plan == nil ? "New Dosing Plan" : "Edit Plan")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("Save") { save() }.bold().disabled(!canSave) }
            }
            .onAppear(perform: load)
            .confirmationDialog("Archive this plan?", isPresented: $confirmingArchive, titleVisibility: .visible) {
                Button("Archive") { archive() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("It leaves Today but its history stays in History and reports.")
            }
            .confirmationDialog("Delete this plan and every dose, reaction and up-dose recorded for it?", isPresented: $confirmingDelete, titleVisibility: .visible) {
                Button("Delete Everything", role: .destructive) { deleteAll() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This cannot be undone. Export a report first if you want a copy.")
            }
        }
    }

    private func load() {
        guard let plan else { return }
        patientName = plan.patientName
        allergen = plan.allergen
        doseAmount = plan.doseAmount
        doseUnit = DoseUnit(rawValue: plan.doseUnit) ?? .mg
        doseForm = plan.doseForm
        phase = Phase(rawValue: plan.phase) ?? .buildUp
        restMinutes = plan.restMinutes
        reminderEnabled = plan.reminderEnabled
        reminderTime = plan.reminderTime
        clinicName = plan.clinicName
        clinicPhone = plan.clinicPhone
        clinicInstructions = plan.clinicInstructions
        hasNextVisit = plan.nextVisit != nil
        nextVisit = plan.nextVisit ?? nextVisit
        startDate = plan.startDate
    }

    private func save() {
        let target = plan ?? DosePlan()
        target.patientName = patientName.trimmingCharacters(in: .whitespaces)
        target.allergen = allergen.trimmingCharacters(in: .whitespaces)
        target.doseAmount = doseAmount
        target.doseUnit = doseUnit.rawValue
        target.doseForm = doseForm.trimmingCharacters(in: .whitespaces)
        target.phase = phase.rawValue
        target.restMinutes = restMinutes
        target.reminderEnabled = reminderEnabled
        let components = Calendar.current.dateComponents([.hour, .minute], from: reminderTime)
        target.reminderHour = components.hour ?? 18
        target.reminderMinute = components.minute ?? 0
        target.clinicName = clinicName
        target.clinicPhone = clinicPhone
        target.clinicInstructions = clinicInstructions
        target.nextVisit = hasNextVisit ? nextVisit : nil
        target.startDate = startDate
        if plan == nil { context.insert(target) }

        let planID = target.id, enabled = target.reminderEnabled, hour = target.reminderHour, minute = target.reminderMinute
        let body = "Time for \(target.title)'s dose: \(target.doseLabel)"
        Task { await NotificationScheduler.scheduleDailyReminder(planID: planID, enabled: enabled, hour: hour, minute: minute, body: body) }
        dismiss()
    }

    private func archive() {
        guard let plan else { return }
        plan.isActive = false
        NotificationScheduler.cancelDailyReminder(planID: plan.id)
        dismiss()
    }

    private func deleteAll() {
        guard let plan else { return }
        let id = plan.id
        let records = (try? context.fetch(FetchDescriptor<DoseRecord>(predicate: #Predicate { $0.planID == id }))) ?? []
        let reactions = (try? context.fetch(FetchDescriptor<Reaction>(predicate: #Predicate { $0.planID == id }))) ?? []
        let changes = (try? context.fetch(FetchDescriptor<DoseChange>(predicate: #Predicate { $0.planID == id }))) ?? []
        records.forEach(context.delete)
        reactions.forEach(context.delete)
        changes.forEach(context.delete)
        context.delete(plan)
        NotificationScheduler.cancelDailyReminder(planID: id)
        dismiss()
    }
}
