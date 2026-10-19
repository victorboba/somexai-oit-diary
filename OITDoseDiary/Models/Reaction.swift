import Foundation
import SwiftData

/// A reaction the caregiver observed. Linked to a plan; `minutesAfterDose` is derived from the
/// most recent dose when the reaction is saved, and can be edited.
@Model
final class Reaction {
    var id: UUID = UUID()
    var planID: UUID = UUID()
    var date: Date = Date()
    var minutesAfterDose: Int? = nil
    var symptomsRaw: String = ""
    var severity: Int = Severity.mild.rawValue
    var treatmentRaw: String = Treatment.none.rawValue
    var notes: String = ""
    @Attribute(.externalStorage) var photo: Data? = nil
    var createdAt: Date = Date()

    init(plan: DosePlan, date: Date = .now) {
        self.planID = plan.id
        self.date = date
    }

    var symptoms: [Symptom] {
        get { symptomsRaw.tagList.compactMap(Symptom.init(rawValue:)) }
        set { symptomsRaw = .tags(newValue.map(\.rawValue)) }
    }

    var severityValue: Severity {
        get { Severity(rawValue: severity) ?? .mild }
        set { severity = newValue.rawValue }
    }

    var treatment: Treatment {
        get { Treatment(rawValue: treatmentRaw) ?? .none }
        set { treatmentRaw = newValue.rawValue }
    }

    var symptomsLabel: String {
        symptoms.isEmpty ? "No symptoms listed" : symptoms.map(\.rawValue).joined(separator: ", ")
    }
}
