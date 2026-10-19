import Foundation

/// Fixed vocabularies. Stored as raw strings so the SwiftData models stay CloudKit-friendly.

enum Cofactor: String, CaseIterable, Identifiable {
    case exercise = "Exercise"
    case illness = "Illness or fever"
    case poorSleep = "Poor sleep"
    case hotShower = "Hot shower or bath"
    case emptyStomach = "Empty stomach"
    case stress = "Stress"
    case menstruation = "Menstruation"
    case nsaid = "NSAID (ibuprofen)"
    case heat = "Hot weather"
    case pollen = "Allergy season"
    case alcohol = "Alcohol"
    var id: String { rawValue }
}

enum Symptom: String, CaseIterable, Identifiable {
    case itchyMouth = "Itchy mouth or throat"
    case hives = "Hives"
    case swelling = "Swelling"
    case stomachPain = "Stomach pain"
    case nausea = "Nausea or vomiting"
    case diarrhea = "Diarrhea"
    case runnyNose = "Runny nose or sneezing"
    case cough = "Cough"
    case wheeze = "Wheeze or trouble breathing"
    case dizziness = "Dizziness or faintness"
    case other = "Other"
    var id: String { rawValue }
}

enum Severity: Int, CaseIterable, Identifiable {
    case mild = 1, moderate = 2, severe = 3
    var id: Int { rawValue }
    var label: String {
        switch self {
        case .mild: "Mild"
        case .moderate: "Moderate"
        case .severe: "Severe"
        }
    }
}

enum Treatment: String, CaseIterable, Identifiable {
    case none = "None"
    case antihistamine = "Antihistamine"
    case inhaler = "Inhaler"
    case epinephrine = "Epinephrine"
    case emergency = "ER or 911"
    var id: String { rawValue }
}

enum DoseUnit: String, CaseIterable, Identifiable {
    case mg, mL, g, tsp, tbsp, pieces, capsules, scoops
    var id: String { rawValue }
}

enum Phase: String, CaseIterable, Identifiable {
    case buildUp = "Up-dosing"
    case maintenance = "Maintenance"
    var id: String { rawValue }
}

enum Allergens {
    static let common = ["Peanut", "Milk", "Egg", "Cashew", "Walnut", "Almond", "Hazelnut", "Pistachio", "Sesame", "Wheat", "Soy", "Shrimp"]
}

extension String {
    /// "a|b|c" -> ["a", "b", "c"]
    var tagList: [String] {
        split(separator: "|").map(String.init).filter { !$0.isEmpty }
    }

    static func tags(_ list: [String]) -> String {
        list.joined(separator: "|")
    }
}
