# OIT Dose Diary

A private diary for families doing oral immunotherapy (OIT) for food allergy. It records what the allergist prescribed and produces the report the allergist wants at each visit. It is for patients and caregivers in OIT.

One of a set of niche iPhone apps built from a shared SwiftUI template. It was never released on the App Store; the code is here for anyone to use. The template is [somexai-ios-template](https://github.com/victorboba/somexai-ios-template) and the collection is [somexai-ios-apps](https://github.com/victorboba/somexai-ios-apps).

## What it does

- Dosing plans: one per patient per allergen, with the prescribed dose (amount, unit, form), phase, rest period, clinic, the clinic's instructions in its own words, next visit and a daily reminder.
- Today: one card per plan. Log the day's dose in one tap (prefilled from the plan), with a with-food toggle and cofactors such as exercise, illness, poor sleep or a hot shower, or skip with a reason. Logging starts the rest countdown and schedules a notification when the rest period is over. Shows streak, last-7-days dots and a visit countdown.
- Reactions: time, minutes after the last dose (computed), symptoms, severity, treatment given, a compressed photo and notes.
- Dose changes: "Record dose change" writes a dated change and updates the plan; the report lists every change.
- History: doses, reactions and changes in one timeline by month, filterable by plan.
- Report: adherence over 30, 90 or 180 days or all time, a PDF for the allergist, and dose and reaction CSVs.
- Widget (today's status, streak, next visit), a Siri App Shortcut and a How-to guide.

## The boundary

The app records what your allergist prescribed. It never computes, suggests or changes a dose or a schedule, and never tells you whether to take one. Missed-dose and sick-day rules are shown only as the caregiver typed them from the clinic. The disclaimer appears on Today, in Settings and in the report footer. Follow your clinic's instructions and contact them with any concern.

## Privacy

Data stays on the device in SwiftData. There is no account, no analytics and no network access, and iCloud sync is off (`iCloudSyncEnabled = false`). Nothing leaves the phone unless you export a PDF or CSV and share it yourself.

## Build and run

- Requirements: Xcode 26 or later, [XcodeGen](https://github.com/yonaskolb/XcodeGen) (`brew install xcodegen`), iOS 17 or later.
- Run `xcodegen generate`, open `OITDoseDiary.xcodeproj`, pick the `OITDoseDiary` scheme and an iPhone simulator, and Run.
- Tests: `xcodebuild -scheme OITDoseDiary -destination 'platform=iOS Simulator,name=iPhone 16 Pro Max' test`.
- Paywall: the app has a hard paywall (annual subscription or lifetime purchase). Running from Xcode uses the bundled `Products.storekit` file, so purchases are simulated and free. Debug builds can also skip it with the `-unlock` launch argument or the Debug switch in Settings.
- To run on your own device or ship it: set your team in `project.yml` (`DEVELOPMENT_TEAM`), change the `com.example` bundle ID prefix in `project.yml`, both `.entitlements` files and `Products.storekit`, and update `supportEmail`, `privacyPolicyURL` and `appStoreID` in `Shared/AppConfig.swift`.

## Project layout

- `OITDoseDiary/App/`, `OITDoseDiary/Core/`: app entry and root gate, StoreKit entitlement, export, review prompt, App Shortcut, widget sync.
- `OITDoseDiary/Features/`: the screens.
- `OITDoseDiary/Models/`: SwiftData models.
- `OITDoseDiary/Core/Stats/`, `Core/Notifications/`: adherence statistics and local reminders.
- `OITDoseDiaryWidget/`: the Home Screen widget, fed from a snapshot in the App Group.
- `Shared/AppConfig.swift`: everything that changes per app (name, copy, product IDs, links, How-to guide, disclaimer).
- `OITDoseDiaryTests/`, `OITDoseDiaryUITests/`: unit and UI tests.
- `scripts/`, `docs/`: icon and screenshot helpers, capability notes.

## License

MIT. See [LICENSE](LICENSE).
