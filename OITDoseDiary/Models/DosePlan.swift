import Foundation
import SwiftData

/// One allergen for one patient, as prescribed by the allergist. A family with two children on OIT,
/// or one child on multi-allergen OIT, has several plans. Records reference a plan by `id`, not by a
/// relationship, which keeps queries simple and the models CloudKit-compatible.
@Model
final class DosePlan {
    var id: UUID = UUID()
    var patientName: String = ""
    var allergen: String = ""
    var doseAmount: Double = 0
    var doseUnit: String = DoseUnit.mg.rawValue
    /// What the dose physically is: "peanut flour", "Bamba", "capsule", "whole milk".
    var doseForm: String = ""
    var phase: String = Phase.buildUp.rawValue
    var restMinutes: Int = AppConfig.defaultRestMinutes
    var reminderEnabled: Bool = false
    var reminderHour: Int = 18
    var reminderMinute: Int = 0
    var clinicName: String = ""
    var clinicPhone: String = ""
    /// The clinic's own rules, entered by the caregiver (missed-dose policy, sick-day policy). Shown verbatim.
    var clinicInstructions: String = ""
    var nextVisit: Date? = nil
    var startDate: Date = Date()
    var isActive: Bool = true
    var createdAt: Date = Date()

    init(patientName: String = "", allergen: String = "", doseAmount: Double = 0,
         doseUnit: DoseUnit = .mg, doseForm: String = "", phase: Phase = .buildUp,
         restMinutes: Int = AppConfig.defaultRestMinutes) {
        self.patientName = patientName
        self.allergen = allergen
        self.doseAmount = doseAmount
        self.doseUnit = doseUnit.rawValue
        self.doseForm = doseForm
        self.phase = phase.rawValue
        self.restMinutes = restMinutes
    }

    var title: String {
        patientName.isEmpty ? allergen : "\(patientName) · \(allergen)"
    }

    /// "120 mg peanut flour"
    var doseLabel: String {
        let base = "\(Formatters.amount(doseAmount)) \(doseUnit)"
        return doseForm.isEmpty ? base : "\(base) \(doseForm)"
    }

    var reminderTime: Date {
        Calendar.current.date(bySettingHour: reminderHour, minute: reminderMinute, second: 0, of: .now) ?? .now
    }
}
