import SwiftUI
import SwiftData
import PhotosUI

struct ReactionEditorView: View {
    let plan: DosePlan
    let reaction: Reaction?

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \DoseRecord.date, order: .reverse) private var records: [DoseRecord]

    @State private var date: Date = .now
    @State private var symptoms: Set<Symptom> = []
    @State private var severity: Severity = .mild
    @State private var treatment: Treatment = .none
    @State private var notes = ""
    @State private var photo: Data?
    @State private var pickerItem: PhotosPickerItem?

    /// The most recent taken dose in the 24 hours before the reaction.
    private var precedingDose: DoseRecord? {
        records.first { $0.planID == plan.id && !$0.skipped && $0.date <= date && date.timeIntervalSince($0.date) < 86_400 }
    }

    private var minutesAfterDose: Int? {
        precedingDose.map { Int(date.timeIntervalSince($0.date) / 60) }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    DatePicker("When", selection: $date)
                    if let dose = precedingDose, let minutes = minutesAfterDose {
                        LabeledContent("After dose", value: "\(minutes) min after the \(Formatters.time.string(from: dose.date)) dose")
                    } else {
                        Text("No dose logged in the 24 hours before this time.")
                            .font(.footnote).foregroundStyle(.secondary)
                    }
                }
                Section("Symptoms") {
                    ChipPicker(options: Symptom.allCases, label: { $0.rawValue }, selection: $symptoms)
                }
                Section("Severity") {
                    Picker("Severity", selection: $severity) {
                        ForEach(Severity.allCases) { Text($0.label).tag($0) }
                    }
                    .pickerStyle(.segmented)
                }
                Section("Treatment given") {
                    Picker("Treatment", selection: $treatment) {
                        ForEach(Treatment.allCases) { Text($0.rawValue).tag($0) }
                    }
                    .pickerStyle(.menu)
                }
                Section("Photo") {
                    if let photo, let image = UIImage(data: photo) {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 220)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        Button("Remove photo", role: .destructive) { self.photo = nil }
                    }
                    PhotosPicker(selection: $pickerItem, matching: .images) {
                        Label(photo == nil ? "Add photo" : "Replace photo", systemImage: "photo")
                    }
                }
                Section("Notes") {
                    TextEditor(text: $notes).frame(minHeight: 80)
                }
                Section {
                    Text("If symptoms are severe or getting worse, follow your emergency action plan and call 911. This app only records what happened.")
                        .font(.footnote).foregroundStyle(.secondary)
                }
            }
            .navigationTitle(reaction == nil ? "Log Reaction" : "Edit Reaction")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("Save") { save() }.bold() }
            }
            .onAppear(perform: load)
            .onChange(of: pickerItem) {
                guard let pickerItem else { return }
                Task {
                    if let data = try? await pickerItem.loadTransferable(type: Data.self) {
                        photo = ImageCompressor.compress(data)
                    }
                }
            }
        }
    }

    private func load() {
        guard let reaction else { return }
        date = reaction.date
        symptoms = Set(reaction.symptoms)
        severity = reaction.severityValue
        treatment = reaction.treatment
        notes = reaction.notes
        photo = reaction.photo
    }

    private func save() {
        let target = reaction ?? Reaction(plan: plan, date: date)
        target.date = date
        target.minutesAfterDose = minutesAfterDose
        target.symptoms = Array(symptoms)
        target.severityValue = severity
        target.treatment = treatment
        target.notes = notes
        target.photo = photo
        if reaction == nil { context.insert(target) }
        dismiss()
    }
}

enum ImageCompressor {
    /// Keeps reaction photos small (max 1200 px, JPEG) so the store and the PDF stay light.
    static func compress(_ data: Data, maxDimension: CGFloat = 1200) -> Data? {
        guard let image = UIImage(data: data) else { return nil }
        let scale = min(1, maxDimension / max(image.size.width, image.size.height))
        let size = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        let renderer = UIGraphicsImageRenderer(size: size)
        let resized = renderer.image { _ in image.draw(in: CGRect(origin: .zero, size: size)) }
        return resized.jpegData(compressionQuality: 0.7)
    }
}
