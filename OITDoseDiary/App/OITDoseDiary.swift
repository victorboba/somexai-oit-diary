import SwiftUI
import SwiftData

@main
struct OITDoseDiary: App {
    @State private var entitlements = EntitlementStore()
    private let container: ModelContainer

    init() {
        let schema = Schema([DosePlan.self, DoseRecord.self, Reaction.self, DoseChange.self])
        let configuration = ModelConfiguration(
            schema: schema,
            cloudKitDatabase: AppConfig.iCloudSyncEnabled ? .automatic : .none
        )
        do {
            container = try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("Could not create the SwiftData container: \(error)")
        }
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("-resetData") {
            let context = container.mainContext
            try? context.delete(model: DoseRecord.self)
            try? context.delete(model: Reaction.self)
            try? context.delete(model: DoseChange.self)
            try? context.delete(model: DosePlan.self)
            try? context.save()
        }
        #endif
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(entitlements)
        }
        .modelContainer(container)
    }
}
