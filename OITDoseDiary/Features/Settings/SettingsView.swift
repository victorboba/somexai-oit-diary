import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(EntitlementStore.self) private var store
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @Query(sort: \DosePlan.createdAt) private var plans: [DosePlan]

    @State private var confirmingDeleteAll = false
    @State private var editingPlan: DosePlan?
    #if DEBUG
    @State private var sampleDataImported = false
    @AppStorage(DebugFlags.unlockKey) private var debugUnlock = false
    @AppStorage("onboarding.completed") private var onboardingCompleted = true
    #endif

    private var version: String {
        let short = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "?"
        return "\(short) (\(build))"
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Dosing plans") {
                    ForEach(plans) { plan in
                        Button { editingPlan = plan } label: {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(plan.title).foregroundStyle(.primary)
                                    Text(plan.doseLabel).font(.caption).foregroundStyle(.secondary)
                                }
                                Spacer()
                                if !plan.isActive { Text("Archived").font(.caption).foregroundStyle(.secondary) }
                            }
                        }
                    }
                    if plans.isEmpty {
                        Text("No plans yet. Add one from Today.").foregroundStyle(.secondary)
                    }
                }

                Section("Your plan") {
                    LabeledContent("Status", value: planDescription)
                    if store.isEntitled && !store.isLifetime {
                        Button("Manage Subscription") {
                            openURL(URL(string: "https://apps.apple.com/account/subscriptions")!)
                        }
                    }
                    Button("Restore Purchases") { Task { await store.restore() } }
                    if let error = store.lastError {
                        Text(error).font(.footnote).foregroundStyle(.red)
                    }
                }

                Section("Your data") {
                    Text("Everything you record stays on this device\(AppConfig.iCloudSyncEnabled ? " and in your private iCloud" : ""). Nothing is sent to us.")
                        .font(.footnote).foregroundStyle(.secondary)
                    Button("Delete All Data", role: .destructive) { confirmingDeleteAll = true }
                }

                Section("About") {
                    Text(AppConfig.disclaimer).font(.footnote).foregroundStyle(.secondary)
                    if !AppConfig.appStoreID.isEmpty {
                        Button("Rate \(AppConfig.appName)") {
                            openURL(URL(string: "https://apps.apple.com/app/id\(AppConfig.appStoreID)?action=write-review")!)
                        }
                    }
                    Button("Contact Support") {
                        let subject = "\(AppConfig.appName) \(version)".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
                        openURL(URL(string: "mailto:\(AppConfig.supportEmail)?subject=\(subject)")!)
                    }
                    NavigationLink("Privacy Policy") { PrivacyPolicyView() }
                    Link("Terms of Use", destination: AppConfig.termsURL)
                    LabeledContent("Version", value: version)
                }

                #if DEBUG
                Section("Debug (not in release builds)") {
                    Toggle("Unlock without purchase", isOn: $debugUnlock)
                        .onChange(of: debugUnlock) { Task { await store.refreshEntitlements() } }
                    Button("Show onboarding again") {
                        onboardingCompleted = false
                        dismiss()
                    }
                    Button(sampleDataImported ? "Imported ✓" : "Insert sample data (45 days onto your plans)") {
                        SampleData.insert(into: context)
                        sampleDataImported = true
                        Task { try? await Task.sleep(for: .seconds(2)); sampleDataImported = false }
                    }
                    .disabled(sampleDataImported)
                }
                #endif
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } }
            }
            .sheet(item: $editingPlan) { plan in PlanEditorView(plan: plan) }
            .confirmationDialog("Delete every plan, dose, reaction and up-dose on this device?", isPresented: $confirmingDeleteAll, titleVisibility: .visible) {
                Button("Delete All", role: .destructive) {
                    try? context.delete(model: DoseRecord.self)
                    try? context.delete(model: Reaction.self)
                    try? context.delete(model: DoseChange.self)
                    try? context.delete(model: DosePlan.self)
                    NotificationScheduler.cancelAll()
                    WidgetSync.update(plans: [], records: [])
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This cannot be undone. Export a report first if you want a copy.")
            }
        }
    }

    private var planDescription: String {
        guard store.isEntitled else { return "Not active" }
        if store.isLifetime { return "Lifetime" }
        if let expiry = store.expiresAt {
            return "Annual, renews \(expiry.formatted(date: .abbreviated, time: .omitted))"
        }
        return "Active"
    }
}
