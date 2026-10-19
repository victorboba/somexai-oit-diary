import Foundation
import SwiftData

/// One day's dose: taken (with what was going on) or deliberately skipped (with why).
@Model
final class DoseRecord {
    var id: UUID = UUID()
    var planID: UUID = UUID()
    var date: Date = Date()
    var amount: Double = 0
    var unit: String = DoseUnit.mg.rawValue
    var form: String = ""
    var takenWithFood: Bool = true
    var skipped: Bool = false
    var skipReason: String = ""
    var cofactorsRaw: String = ""
    var notes: String = ""
    var createdAt: Date = Date()

    init(plan: DosePlan, date: Date = .now) {
        self.planID = plan.id
        self.date = date
        self.amount = plan.doseAmount
        self.unit = plan.doseUnit
        self.form = plan.doseForm
    }

    var cofactors: [Cofactor] {
        get { cofactorsRaw.tagList.compactMap(Cofactor.init(rawValue:)) }
        set { cofactorsRaw = .tags(newValue.map(\.rawValue)) }
    }

    var day: Date { Calendar.current.startOfDay(for: date) }

    var amountLabel: String {
        let base = "\(Formatters.amount(amount)) \(unit)"
        return form.isEmpty ? base : "\(base) \(form)"
    }
}
