import XCTest
@testable import OITDoseDiary

@MainActor
final class AdherenceStatsTests: XCTestCase {
    private let calendar = Calendar.current

    private func day(_ offset: Int, hour: Int = 17) -> Date {
        let base = calendar.date(byAdding: .day, value: offset, to: calendar.startOfDay(for: .now))!
        return calendar.date(bySettingHour: hour, minute: 0, second: 0, of: base)!
    }

    private func record(_ plan: DosePlan, dayOffset: Int, skipped: Bool = false) -> DoseRecord {
        let r = DoseRecord(plan: plan, date: day(dayOffset))
        r.skipped = skipped
        return r
    }

    func testCountsTakenSkippedAndUnloggedDays() {
        let plan = DosePlan(allergen: "Peanut", doseAmount: 120)
        let records = [record(plan, dayOffset: -4), record(plan, dayOffset: -3, skipped: true), record(plan, dayOffset: -1), record(plan, dayOffset: 0)]
        let stats = AdherenceStats.compute(records: records, reactions: [], from: day(-4), to: day(0))
        XCTAssertEqual(stats.days, 5)
        XCTAssertEqual(stats.taken, 3)
        XCTAssertEqual(stats.skipped, 1)
        XCTAssertEqual(stats.unlogged, 1)
    }

    func testStreakCountsConsecutiveTakenDaysEndingToday() {
        let plan = DosePlan(allergen: "Milk", doseAmount: 3)
        let records = [record(plan, dayOffset: -3, skipped: true), record(plan, dayOffset: -2), record(plan, dayOffset: -1), record(plan, dayOffset: 0)]
        XCTAssertEqual(AdherenceStats.streak(records: records), 3)
    }

    func testStreakSurvivesTodayNotYetLogged() {
        let plan = DosePlan(allergen: "Egg", doseAmount: 1)
        let records = [record(plan, dayOffset: -2), record(plan, dayOffset: -1)]
        XCTAssertEqual(AdherenceStats.streak(records: records), 2)
    }

    func testStreakIsZeroAfterMissedYesterday() {
        let plan = DosePlan(allergen: "Egg", doseAmount: 1)
        let records = [record(plan, dayOffset: -3), record(plan, dayOffset: -2)]
        XCTAssertEqual(AdherenceStats.streak(records: records), 0)
    }

    func testTakenWinsOverSkippedOnTheSameDay() {
        let plan = DosePlan(allergen: "Cashew", doseAmount: 50)
        let records = [record(plan, dayOffset: 0, skipped: true), record(plan, dayOffset: 0)]
        XCTAssertEqual(AdherenceStats.status(of: records, on: day(0)), .taken)
    }
}
