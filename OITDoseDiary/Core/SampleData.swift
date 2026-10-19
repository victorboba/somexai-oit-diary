import Foundation
import SwiftData

#if DEBUG
/// Debug-only sample data for screenshots and manual testing. Clearly fictional.
/// If plans already exist, 45 days of history are backfilled onto each active plan (so the
/// report you are looking at fills in). Otherwise a "Maya · Peanut" plan is created.
enum SampleData {
    static func insert(into context: ModelContext) {
        let existing = (try? context.fetch(FetchDescriptor<DosePlan>(predicate: #Predicate { $0.isActive }))) ?? []
        if existing.isEmpty {
            let plan = DosePlan(patientName: "Maya", allergen: "Peanut", doseAmount: 120, doseUnit: .mg, doseForm: "peanut flour", phase: .buildUp)
            plan.clinicName = "Riverside Allergy"
            plan.clinicInstructions = "Dose with a meal. No exercise or hot showers for 2 hours. If 3+ days are missed, call before the next dose."
            plan.nextVisit = Calendar.current.date(byAdding: .day, value: 9, to: .now)
            context.insert(plan)
            backfill(plan, in: context)
        } else {
            for plan in existing { backfill(plan, in: context) }
        }
    }

    /// Adds 44 days of doses (one skipped, a few with cofactors), one mild reaction and one up-dose.
    /// Days that already have a record are left alone.
    static func backfill(_ plan: DosePlan, in context: ModelContext) {
        let calendar = Calendar.current
        let planID = plan.id
        let existingRecords = (try? context.fetch(FetchDescriptor<DoseRecord>(predicate: #Predicate { $0.planID == planID }))) ?? []
        let loggedDays = Set(existingRecords.map { calendar.startOfDay(for: $0.date) })

        let earliest = calendar.date(byAdding: .day, value: -45, to: .now) ?? .now
        if plan.startDate > earliest { plan.startDate = earliest }
        if plan.nextVisit == nil { plan.nextVisit = calendar.date(byAdding: .day, value: 9, to: .now) }

        let currentDose = plan.doseAmount > 0 ? plan.doseAmount : 120
        let previousDose = (currentDose * 2 / 3 * 10).rounded() / 10
        let change = DoseChange(plan: plan, date: calendar.date(byAdding: .day, value: -14, to: .now) ?? .now,
                                toAmount: currentDose, unit: plan.doseUnit, form: plan.doseForm, note: "Up-dose visit, tolerated in clinic")
        change.fromAmount = previousDose
        context.insert(change)

        for offset in stride(from: 44, through: 1, by: -1) {
            guard let day = calendar.date(byAdding: .day, value: -offset, to: .now),
                  !loggedDays.contains(calendar.startOfDay(for: day)),
                  let time = calendar.date(bySettingHour: 17, minute: 30 + Int.random(in: -20...20), second: 0, of: day) else { continue }
            let record = DoseRecord(plan: plan, date: time)
            record.amount = offset > 14 ? previousDose : currentDose
            if offset == 20 {
                record.skipped = true
                record.skipReason = "Fever"
            } else if offset % 9 == 0 {
                record.cofactors = [.exercise]
            }
            context.insert(record)
            if offset == 27 {
                let reaction = Reaction(plan: plan, date: time.addingTimeInterval(40 * 60))
                reaction.minutesAfterDose = 40
                reaction.symptoms = [.itchyMouth, .hives]
                reaction.severityValue = .mild
                reaction.treatment = .antihistamine
                reaction.notes = "A few hives on the chin, gone within an hour."
                context.insert(reaction)
            }
        }
    }
}
#endif
