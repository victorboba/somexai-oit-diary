import Foundation
import WidgetKit

enum WidgetSync {
    /// Summarises the first active plan for the widget and reloads timelines.
    static func update(plans: [DosePlan], records: [DoseRecord]) {
        var snapshot = WidgetSnapshot()
        if let plan = plans.first(where: \.isActive) {
            let planRecords = records.filter { $0.planID == plan.id }
            let today = planRecords.filter { Calendar.current.isDateInToday($0.date) }
            snapshot.planTitle = plan.title
            snapshot.doseLabel = plan.doseLabel
            snapshot.todayTakenAt = today.first(where: { !$0.skipped })?.date
            snapshot.todaySkipped = snapshot.todayTakenAt == nil && today.contains(where: \.skipped)
            snapshot.streakDays = AdherenceStats.streak(records: planRecords)
            snapshot.nextVisit = plan.nextVisit
        }
        snapshot.save()
        WidgetCenter.shared.reloadAllTimelines()
    }
}
