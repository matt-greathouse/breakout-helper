import XCTest

final class Breakout_HelperUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testClassesKeepTheirRostersSeparate() throws {
        let app = XCUIApplication()
        app.launchEnvironment["UITEST_RESET_DATA"] = "1"
        app.launch()

        app.tabBars.buttons["Settings"].tap()
        let studentNameField = app.textFields["studentNameField"]
        XCTAssertTrue(studentNameField.waitForExistence(timeout: 2))
        studentNameField.tap()
        studentNameField.typeText("Avery")
        app.buttons["addStudent"].tap()
        XCTAssertTrue(app.staticTexts["Avery"].waitForExistence(timeout: 2))

        app.buttons["classroomSelector"].tap()
        XCTAssertTrue(app.buttons["addClassroom"].waitForExistence(timeout: 2))
        app.buttons["addClassroom"].tap()
        let newClassNameField = app.textFields["newClassNameField"]
        XCTAssertTrue(newClassNameField.waitForExistence(timeout: 2))
        newClassNameField.typeText("Science")
        app.alerts["New Class"].buttons["Add"].tap()
        app.buttons["Done"].tap()

        XCTAssertFalse(app.staticTexts["Avery"].exists)

        app.buttons["classroomSelector"].tap()
        app.staticTexts["My Class"].tap()
        XCTAssertTrue(app.staticTexts["Avery"].waitForExistence(timeout: 2))
    }
}
