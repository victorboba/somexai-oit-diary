import XCTest
import SwiftData
import PDFKit
@testable import OITDoseDiary

@MainActor
final class ReportExporterTests: XCTestCase {
    func testReportRendersAMultiPagePDFWithSampleData() throws {
        let schema = Schema([DosePlan.self, DoseRecord.self, Reaction.self, DoseChange.self])
        let container = try ModelContainer(for: schema, configurations: [ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)])
        let context = container.mainContext
        SampleData.insert(into: context)

        let plan = try XCTUnwrap(try context.fetch(FetchDescriptor<DosePlan>()).first)
        let records = try context.fetch(FetchDescriptor<DoseRecord>())
        let reactions = try context.fetch(FetchDescriptor<Reaction>())
        let changes = try context.fetch(FetchDescriptor<DoseChange>())
        XCTAssertGreaterThan(records.count, 40)
        XCTAssertLessThan(plan.startDate, Calendar.current.date(byAdding: .day, value: -40, to: .now)!, "sample plan must start well in the past so period reports have days to show")
        let thirtyDays = AdherenceStats.compute(records: records, reactions: reactions, from: Calendar.current.date(byAdding: .day, value: -29, to: .now)!)
        XCTAssertEqual(thirtyDays.days, 30)
        XCTAssertGreaterThan(thirtyDays.taken, 20)

        let url = try ReportExporter.export(plan: plan, records: records, reactions: reactions, changes: changes, from: plan.startDate)
        let document = try XCTUnwrap(PDFDocument(url: url))
        XCTAssertGreaterThanOrEqual(document.pageCount, 2)

        let text = (0..<document.pageCount).compactMap { document.page(at: $0)?.string }.joined()
        XCTAssertTrue(text.contains("Maya"))
        XCTAssertTrue(text.contains("Dose changes"))
        XCTAssertTrue(text.contains("Hives"))
        XCTAssertTrue(text.contains("never changes a dose"))
    }
}
