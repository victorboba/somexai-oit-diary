import UIKit

/// The allergist report: plan, adherence summary, dose changes, reactions (with photos), daily log.
enum ReportExporter {
    static func export(plan: DosePlan, records: [DoseRecord], reactions: [Reaction],
                       changes: [DoseChange], from start: Date, to end: Date = .now) throws -> URL {
        let periodRecords = records.filter { $0.planID == plan.id && $0.date >= start && $0.date <= end }
        let periodReactions = reactions.filter { $0.planID == plan.id && $0.date >= start && $0.date <= end }
        let periodChanges = changes.filter { $0.planID == plan.id && $0.date >= start && $0.date <= end }
        let stats = AdherenceStats.compute(records: periodRecords, reactions: periodReactions, from: start, to: end)

        let footer = "\(AppConfig.appName) · entered by the patient or caregiver · not medical advice"
        return try PDFCanvas.render(footer: footer) { pdf in
            pdf.title("\(AppConfig.appName) report")
            pdf.subtitle("\(plan.title) · \(Formatters.date.string(from: start)) to \(Formatters.date.string(from: end)) · generated \(Formatters.dateTime.string(from: .now))")

            pdf.heading("Current plan")
            var pairs: [(String, String)] = [
                ("Patient", plan.patientName.isEmpty ? "—" : plan.patientName),
                ("Allergen", plan.allergen),
                ("Current dose", plan.doseLabel),
                ("Phase", plan.phase),
                ("Rest after dose", Formatters.minutes(plan.restMinutes)),
                ("Plan started", Formatters.date.string(from: plan.startDate)),
            ]
            if !plan.clinicName.isEmpty { pairs.append(("Clinic", plan.clinicName)) }
            if let visit = plan.nextVisit { pairs.append(("Next visit", Formatters.date.string(from: visit))) }
            pdf.keyValues(pairs)
            if !plan.clinicInstructions.isEmpty {
                pdf.spacer(4)
                pdf.paragraph("Clinic instructions (as entered): \(plan.clinicInstructions)", color: .darkGray)
            }

            pdf.heading("Summary for the period")
            pdf.keyValues([
                ("Days in period", "\(stats.days)"),
                ("Doses taken", "\(stats.taken)"),
                ("Doses skipped", "\(stats.skipped)"),
                ("Days not logged", "\(stats.unlogged)"),
                ("Reactions", "\(stats.reactions)"),
                ("Current streak", "\(stats.currentStreak) day\(stats.currentStreak == 1 ? "" : "s")"),
            ])

            pdf.heading("Dose changes")
            pdf.table(
                headers: ["Date", "From", "To", "Note"],
                widths: [0.2, 0.2, 0.25, 0.35],
                rows: periodChanges.sorted { $0.date < $1.date }.map {
                    [Formatters.date.string(from: $0.date),
                     "\(Formatters.amount($0.fromAmount)) \($0.unit)",
                     "\(Formatters.amount($0.toAmount)) \($0.unit)\($0.form.isEmpty ? "" : " \($0.form)")",
                     $0.note]
                }
            )

            pdf.heading("Reactions")
            let sortedReactions = periodReactions.sorted { $0.date < $1.date }
            pdf.table(
                headers: ["Date", "After dose", "Severity", "Symptoms", "Treatment", "Notes"],
                widths: [0.17, 0.1, 0.1, 0.25, 0.13, 0.25],
                rows: sortedReactions.map {
                    [Formatters.dateTime.string(from: $0.date),
                     $0.minutesAfterDose.map { "\($0) min" } ?? "—",
                     $0.severityValue.label,
                     $0.symptomsLabel,
                     $0.treatment.rawValue,
                     $0.notes]
                }
            )
            for reaction in sortedReactions {
                if let data = reaction.photo, let image = UIImage(data: data) {
                    pdf.image(image, caption: "Photo · \(Formatters.dateTime.string(from: reaction.date))")
                }
            }

            pdf.heading("Daily dose log")
            pdf.table(
                headers: ["Date", "Status", "Dose", "Food", "Cofactors", "Notes"],
                widths: [0.17, 0.1, 0.2, 0.07, 0.2, 0.26],
                rows: periodRecords.sorted { $0.date < $1.date }.map {
                    [Formatters.dateTime.string(from: $0.date),
                     $0.skipped ? "Skipped" : "Taken",
                     $0.skipped ? ($0.skipReason.isEmpty ? "—" : $0.skipReason) : $0.amountLabel,
                     $0.skipped ? "" : ($0.takenWithFood ? "Yes" : "No"),
                     $0.cofactors.map(\.rawValue).joined(separator: ", "),
                     $0.notes]
                }
            )

            pdf.spacer(10)
            pdf.paragraph(AppConfig.disclaimer, color: .darkGray)
        }
    }
}
