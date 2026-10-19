import Foundation

/// The one file to edit when starting a new app from this template.
/// Everything user-facing that changes per app (name, copy, product IDs, links) lives here.
/// Compiled into both the app and the widget, so keep it free of UIKit/SwiftUI imports.
enum AppConfig {
    // MARK: Identity
    static let appName = "OIT Dose Diary"
    static let bundleID = "com.example.oit-diary"
    static let appGroupID = "group.com.example.oit-diary"
    /// Your App Store ID once the app is live. The Rate button stays hidden while it is empty.(the number in the App Store URL).
    static let appStoreID = ""

    // MARK: Sync
    /// Set to true only after enabling iCloud + CloudKit on the App ID (see docs/capabilities.md).
    static let iCloudSyncEnabled = false

    // MARK: StoreKit (must match App Store Connect and StoreKit/Products.storekit)
    /// Apple allows only letters, digits, underscores and periods in product IDs, so hyphens in the bundle ID are dropped.
    static let productPrefix = bundleID.replacingOccurrences(of: "-", with: "")
    static let annualProductID = "\(productPrefix).pro.annual"
    static let lifetimeProductID = "\(productPrefix).pro.lifetime"

    // MARK: Links
    static let supportEmail = "support@somexai.com"
    /// Hosted copy of PrivacyPolicyView, one page per app under somexai.com/privacy (somexai_corp repo, scripts/privacy.py).
    static let privacyPolicyURL = URL(string: "https://somexai.com/privacy/oit-diary/")!
    static let termsURL = URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!

    // MARK: Copy
    static let entryNoun = "Dose"
    static let entryNounPlural = "Doses"
    static let exportFileStem = "oit-dose-diary"

    static let onboarding: [OnboardingPage] = [
        OnboardingPage(symbol: "pills.circle.fill", title: "Log today's dose in one tap",
                       body: "Record the dose your allergist prescribed, when it was taken, and what else was going on that day."),
        OnboardingPage(symbol: "timer", title: "Rest period, handled",
                       body: "Logging a dose starts the after-dose rest countdown and notifies you when it ends."),
        OnboardingPage(symbol: "doc.text.fill", title: "A report your allergist will read",
                       body: "Adherence, up-doses and reactions in one PDF, ready before every clinic visit. Everything stays on your phone."),
    ]

    static let paywallSymbol = "checkmark.seal.fill"
    static let paywallHeadline = "Unlock \(appName)"
    static let paywallBenefits = [
        "Unlimited dosing plans and history",
        "Reaction log with photos and cofactors",
        "PDF report for your allergist",
        "Daily reminder, rest timer, widget and Siri",
        "Private: nothing leaves your phone",
    ]

    /// Shown on Today, in Settings and in the report footer. Never soften it.
    static let disclaimer = "\(appName) records what your allergist prescribed. It never changes a dose or tells you whether to take one. Follow your clinic's instructions and contact them with any concern."

    /// Display prices used only by DEBUG screenshot runs (`-mockPrices`). Keep in sync with StoreKit/Products.storekit.
    static let mockPrices = (annual: "$9.99", lifetime: "$24.99")

    // MARK: Behaviour
    static let reviewAfterSuccesses = 3
    static let defaultRestMinutes = 120
}

struct OnboardingPage: Identifiable, Hashable {
    var id: String { title }
    let symbol: String
    let title: String
    let body: String
}
