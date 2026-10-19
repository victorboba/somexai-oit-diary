import XCTest

/// Drives the app with sample data and attaches App Store screenshots to the test result.
/// Extract them with: xcrun xcresulttool export attachments --path <result.xcresult> --output-path <dir>
final class ScreenshotTests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testAppScreens() {
        addUIInterruptionMonitor(withDescription: "System alerts") { alert in
            for label in ["Allow", "OK"] where alert.buttons[label].exists {
                alert.buttons[label].tap()
                return true
            }
            return false
        }
        let app = XCUIApplication()
        app.launchArguments = ["-unlock", "-resetData", "-sampleData", "-skipOnboarding", "-uiTesting"]
        app.launch()

        XCTAssertTrue(app.buttons["Log today's dose"].waitForExistence(timeout: 10))
        snap("01-today", app)

        app.buttons["Log today's dose"].firstMatch.tap()
        XCTAssertTrue(app.navigationBars["Log Dose"].waitForExistence(timeout: 5))
        snap("02-log-dose", app)
        app.buttons["Save"].tap()
        dismissSystemAlert()
        XCTAssertTrue(app.staticTexts["Rest period ends in"].waitForExistence(timeout: 10))
        snap("03-rest-timer", app)

        app.buttons["Log a reaction"].firstMatch.tap()
        XCTAssertTrue(app.navigationBars["Log Reaction"].waitForExistence(timeout: 5))
        snap("04-reaction", app)
        app.buttons["Cancel"].tap()

        app.tabBars.buttons["History"].tap()
        XCTAssertTrue(app.navigationBars["History"].waitForExistence(timeout: 5))
        snap("05-history", app)

        app.tabBars.buttons["Report"].tap()
        XCTAssertTrue(app.navigationBars["Report"].waitForExistence(timeout: 5))
        snap("06-report", app)
    }

    func testPaywall() {
        let app = XCUIApplication()
        app.launchArguments = ["-skipOnboarding", "-uiTesting", "-mockPrices"]
        app.launch()
        XCTAssertTrue(app.staticTexts["Lifetime"].waitForExistence(timeout: 10))
        snap("paywall", app)
    }

    /// Taps Allow on the notification permission alert if it is showing (it belongs to SpringBoard, not the app).
    private func dismissSystemAlert() {
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        let allow = springboard.buttons["Allow"]
        if allow.waitForExistence(timeout: 4) { allow.tap() }
    }

    private func snap(_ name: String, _ app: XCUIApplication) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
