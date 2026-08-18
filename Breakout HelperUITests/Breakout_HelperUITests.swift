//
//  Breakout_HelperUITests.swift
//  Breakout HelperUITests
//
//  Created by Matt Greathouse on 2/4/26.
//

import XCTest

final class Breakout_HelperUITests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    @MainActor
    func testParticipantCanGenerateGroups() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-hasLaunchedBefore.v1", "YES"]
        app.launch()

        app.tabBars.buttons["Settings"].tap()
        let studentField = app.textFields["Add student"]
        for name in ["Avery", "Jordan", "Sam"] {
            studentField.tap()
            studentField.typeText(name)
            app.buttons["Add"].firstMatch.tap()
        }

        app.tabBars.buttons["Breakout"].tap()
        app.buttons["Break Out"].tap()

        XCTAssertTrue(app.otherElements["groupCard-1"].waitForExistence(timeout: 3))
    }

    @MainActor
    func testLaunchPerformance() throws {
        // This measures how long it takes to launch your application.
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
}
