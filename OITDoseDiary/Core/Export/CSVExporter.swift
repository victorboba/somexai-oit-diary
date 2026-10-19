import Foundation

enum CSVExporter {
    static func doseCSV(records: [DoseRecord], plans: [UUID: DosePlan]) -> String {
        let iso = ISO8601DateFormatter()
        var lines = ["date,patient,allergen,status,amount,unit,form,with_food,cofactors,skip_reason,notes"]
        for record in records.sorted(by: { $0.date < $1.date }) {
            let plan = plans[record.planID]
            lines.append([
                iso.string(from: record.date),
                plan?.patientName ?? "",
                plan?.allergen ?? "",
                record.skipped ? "skipped" : "taken",
                record.skipped ? "" : Formatters.amount(record.amount),
                record.skipped ? "" : record.unit,
                record.skipped ? "" : record.form,
                record.skipped ? "" : (record.takenWithFood ? "yes" : "no"),
                record.cofactors.map(\.rawValue).joined(separator: "; "),
                record.skipReason,
                record.notes,
            ].map(quote).joined(separator: ","))
        }
        return lines.joined(separator: "\n") + "\n"
    }

    static func reactionCSV(reactions: [Reaction], plans: [UUID: DosePlan]) -> String {
        let iso = ISO8601DateFormatter()
        var lines = ["date,patient,allergen,minutes_after_dose,severity,symptoms,treatment,notes"]
        for reaction in reactions.sorted(by: { $0.date < $1.date }) {
            let plan = plans[reaction.planID]
            lines.append([
                iso.string(from: reaction.date),
                plan?.patientName ?? "",
                plan?.allergen ?? "",
                reaction.minutesAfterDose.map(String.init) ?? "",
                reaction.severityValue.label,
                reaction.symptoms.map(\.rawValue).joined(separator: "; "),
                reaction.treatment.rawValue,
                reaction.notes,
            ].map(quote).joined(separator: ","))
        }
        return lines.joined(separator: "\n") + "\n"
    }

    static func write(_ csv: String, suffix: String) throws -> URL {
        let url = ExportFile.temporaryURL(suffix: suffix, extension: "csv")
        try csv.write(to: url, atomically: true, encoding: .utf8)
        return url
    }

    static func quote(_ field: String) -> String {
        "\"" + field.replacingOccurrences(of: "\"", with: "\"\"") + "\""
    }
}

/// A file URL wrapped so it can drive `.sheet(item:)`.
struct ExportFile: Identifiable {
    let url: URL
    var id: String { url.path }

    static func temporaryURL(suffix: String, extension ext: String) -> URL {
        let stamp = Formatters.fileStamp.string(from: .now)
        return FileManager.default.temporaryDirectory
            .appendingPathComponent("\(AppConfig.exportFileStem)-\(suffix)-\(stamp)")
            .appendingPathExtension(ext)
    }
}
