import Foundation

/// Day-by-day adherence over a window. Pure function so it is unit-tested.
struct AdherenceStats: Equatable {
    var taken = 0
    var skipped = 0
    var unlogged = 0
    var reactions = 0
    var currentStreak = 0
    var days = 0

    enum DayStatus { case taken, skipped, unlogged }

    static func status(of records: [DoseRecord], on day: Date, calendar: Calendar = .current) -> DayStatus {
        let sameDay = records.filter { calendar.isDate($0.date, inSameDayAs: day) }
        if sameDay.contains(where: { !$0.skipped }) { return .taken }
        if !sameDay.isEmpty { return .skipped }
        return .unlogged
    }

    static func compute(records: [DoseRecord], reactions: [Reaction],
                        from start: Date, to end: Date = .now,
                        calendar: Calendar = .current) -> AdherenceStats {
        var stats = AdherenceStats()
        let startDay = calendar.startOfDay(for: start)
        let endDay = calendar.startOfDay(for: end)
        guard startDay <= endDay else { return stats }

        var day = startDay
        while day <= endDay {
            switch status(of: records, on: day, calendar: calendar) {
            case .taken: stats.taken += 1
            case .skipped: stats.skipped += 1
            case .unlogged: stats.unlogged += 1
            }
            stats.days += 1
            day = calendar.date(byAdding: .day, value: 1, to: day) ?? endDay.addingTimeInterval(1)
        }

        stats.reactions = reactions.filter { $0.date >= startDay && $0.date <= end }.count
        stats.currentStreak = streak(records: records, endingOn: end, calendar: calendar)
        return stats
    }

    /// Consecutive days with a taken dose, ending today or (if today is not yet logged) yesterday.
    static func streak(records: [DoseRecord], endingOn end: Date = .now, calendar: Calendar = .current) -> Int {
        var day = calendar.startOfDay(for: end)
        if status(of: records, on: day, calendar: calendar) != .taken {
            guard let yesterday = calendar.date(byAdding: .day, value: -1, to: day) else { return 0 }
            day = yesterday
        }
        var count = 0
        while status(of: records, on: day, calendar: calendar) == .taken {
            count += 1
            guard let previous = calendar.date(byAdding: .day, value: -1, to: day) else { break }
            day = previous
        }
        return count
    }
}
