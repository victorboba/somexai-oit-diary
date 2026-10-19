import Foundation

/// A tiny summary the app writes to the shared App Group so the widget can render
/// without touching SwiftData. Describes the first active dosing plan.
struct WidgetSnapshot: Codable {
    var planTitle: String = ""
    var doseLabel: String = ""
    var todayTakenAt: Date? = nil
    var todaySkipped: Bool = false
    var streakDays: Int = 0
    var nextVisit: Date? = nil
    var updatedAt: Date = .now

    static let storageKey = "widget.snapshot"

    static var defaults: UserDefaults {
        UserDefaults(suiteName: AppConfig.appGroupID) ?? .standard
    }

    static func load() -> WidgetSnapshot {
        guard let data = defaults.data(forKey: storageKey),
              let snapshot = try? JSONDecoder().decode(WidgetSnapshot.self, from: data) else {
            return WidgetSnapshot()
        }
        return snapshot
    }

    func save() {
        guard let data = try? JSONEncoder().encode(self) else { return }
        Self.defaults.set(data, forKey: Self.storageKey)
    }

    static let placeholder = WidgetSnapshot(
        planTitle: "Maya · Peanut", doseLabel: "120 mg peanut flour",
        todayTakenAt: Calendar.current.date(bySettingHour: 17, minute: 30, second: 0, of: .now),
        streakDays: 34, nextVisit: Calendar.current.date(byAdding: .day, value: 9, to: .now)
    )
}
