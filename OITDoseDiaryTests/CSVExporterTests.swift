import XCTest
@testable import OITDoseDiary

@MainActor
final class CSVExporterTests: XCTestCase {
    func testQuotesAndEscapesFields() {
        XCTAssertEqual(CSVExporter.quote(#"say "hi""#), #""say ""hi""""#)
    }

    func testDoseCSVHasHeaderAndRowPerRecord() {
        let plan = DosePlan(patientName: "Maya", allergen: "Peanut", doseAmount: 120, doseUnit: .mg, doseForm: "peanut flour")
        let taken = DoseRecord(plan: plan, date: Date(timeIntervalSince1970: 0))
        taken.cofactors = [.exercise, .poorSleep]
        let skipped = DoseRecord(plan: plan, date: Date(timeIntervalSince1970: 86_400))
        skipped.skipped = true
        skipped.skipReason = "Fever"

        let csv = CSVExporter.doseCSV(records: [skipped, taken], plans: [plan.id: plan])
        let lines = csv.split(separator: "\n")
        XCTAssertEqual(lines.count, 3)
        XCTAssertTrue(lines[0].hasPrefix("date,patient,allergen,status"))
        XCTAssertTrue(lines[1].contains("\"taken\",\"120\",\"mg\",\"peanut flour\",\"yes\",\"Exercise; Poor sleep\""))
        XCTAssertTrue(lines[2].contains("\"skipped\",\"\",\"\",\"\",\"\",\"\",\"Fever\""))
    }

    func testAmountFormatting() {
        XCTAssertEqual(Formatters.amount(120), "120")
        XCTAssertEqual(Formatters.amount(0.25), "0.25")
        XCTAssertEqual(Formatters.amount(2.5), "2.5")
    }
}
