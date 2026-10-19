import SwiftUI
import SwiftData

/// One card per active plan: today's dose, the rest countdown, streak, next visit. The screen a parent opens daily.
struct TodayView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.scenePhase) private var scenePhase
    @Query(filter: #Predicate<DosePlan> { $0.isActive }, sort: \DosePlan.createdAt) private var plans: [DosePlan]
    @Query(sort: \DoseRecord.date, order: .reverse) private var records: [DoseRecord]

    @State private var loggingPlan: DosePlan?
    @State private var reactionPlan: DosePlan?
    @State private var editingPlan: DosePlan?
    @State private var upDosePlan: DosePlan?
    @State private var showingNewPlan = false
    @State private var showingSettings = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    if plans.isEmpty {
                        ContentUnavailableView {
                            Label("No dosing plan yet", systemImage: "pills.circle")
                        } description: {
                            Text("Enter the dose your allergist prescribed and start logging.")
                        } actions: {
                            Button("Set Up Dosing Plan") { showingNewPlan = true }
                                .buttonStyle(.borderedProminent)
                        }
                        .padding(.top, 40)
                    } else {
                        ForEach(plans) { plan in
                            PlanCardView(
                                plan: plan,
                                records: records.filter { $0.planID == plan.id },
                                onLogDose: { loggingPlan = plan },
                                onLogReaction: { reactionPlan = plan },
                                onEdit: { editingPlan = plan },
                                onUpDose: { upDosePlan = plan }
                            )
                        }
                    }
                    Text(AppConfig.disclaimer)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 8)
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Today")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { showingSettings = true } label: { Image(systemName: "gearshape") }
                        .accessibilityLabel("Settings")
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showingNewPlan = true } label: { Image(systemName: "plus") }
                        .accessibilityLabel("Add dosing plan")
                }
            }
            .sheet(item: $loggingPlan) { plan in LogDoseSheet(plan: plan, record: nil) }
            .sheet(item: $reactionPlan) { plan in ReactionEditorView(plan: plan, reaction: nil) }
            .sheet(item: $editingPlan) { plan in PlanEditorView(plan: plan) }
            .sheet(item: $upDosePlan) { plan in UpDoseSheet(plan: plan) }
            .sheet(isPresented: $showingNewPlan) { PlanEditorView(plan: nil) }
            .sheet(isPresented: $showingSettings) { SettingsView() }
        }
        .task {
            #if DEBUG
            if ProcessInfo.processInfo.arguments.contains("-sampleData"), plans.isEmpty {
                SampleData.insert(into: context)
            }
            #endif
        }
        .onChange(of: records.count, initial: true) { WidgetSync.update(plans: plans, records: records) }
        .onChange(of: plans.count) { WidgetSync.update(plans: plans, records: records) }
        .onChange(of: scenePhase, initial: true) { _, phase in
            guard phase == .active else { return }
            openLogSheetIfRequestedByShortcut()
        }
    }

    private func openLogSheetIfRequestedByShortcut() {
        let defaults = WidgetSnapshot.defaults
        guard defaults.bool(forKey: LogDoseIntent.pendingKey) else { return }
        defaults.removeObject(forKey: LogDoseIntent.pendingKey)
        if let plan = plans.first { loggingPlan = plan } else { showingNewPlan = true }
    }
}
