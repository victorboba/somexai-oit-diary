import AppIntents
import Foundation

/// "Log a dose in OIT Dose Diary" from Siri, Spotlight or the Shortcuts app. Opens the app on the log sheet.
struct LogDoseIntent: AppIntent {
    static var title: LocalizedStringResource = "Log a Dose"
    static var description = IntentDescription("Opens the diary ready to record today's dose.")
    static var openAppWhenRun = true

    static let pendingKey = "intent.openLogDose"

    func perform() async throws -> some IntentResult {
        WidgetSnapshot.defaults.set(true, forKey: Self.pendingKey)
        return .result()
    }
}

struct OITDoseDiaryShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: LogDoseIntent(),
            phrases: ["Log a dose in \(.applicationName)", "Log today's dose in \(.applicationName)"],
            shortTitle: "Log Dose",
            systemImageName: "pills.circle"
        )
    }
}
