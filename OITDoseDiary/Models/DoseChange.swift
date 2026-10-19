import Foundation
import SwiftData

/// An up-dose (or any prescribed change) recorded when the caregiver updates the plan's dose.
/// The history of these is the first thing an allergist looks for in the report.
@Model
final class DoseChange {
    var id: UUID = UUID()
    var planID: UUID = UUID()
    var date: Date = Date()
    var fromAmount: Double = 0
    var toAmount: Double = 0
    var unit: String = DoseUnit.mg.rawValue
    var form: String = ""
    var note: String = ""
    var createdAt: Date = Date()

    init(plan: DosePlan, date: Date, toAmount: Double, unit: String, form: String, note: String) {
        self.planID = plan.id
        self.date = date
        self.fromAmount = plan.doseAmount
        self.toAmount = toAmount
        self.unit = unit
        self.form = form
        self.note = note
    }

    var label: String {
        "\(Formatters.amount(fromAmount)) → \(Formatters.amount(toAmount)) \(unit)\(form.isEmpty ? "" : " \(form)")"
    }
}
