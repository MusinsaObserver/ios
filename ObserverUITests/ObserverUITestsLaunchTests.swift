//
//  ObserverUITestsLaunchTests.swift
//  ObserverUITests
//
//  Created by Jiwon Kim on 9/10/24.
//

import XCTest

final class ObserverUITestsLaunchTests: XCTestCase {

    override class var runsForEachTargetApplicationUIConfiguration: Bool {
        true
    }

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testLaunch() throws {
        let app = XCUIApplication()
        app.launch()

        // Ensure that the login button appears on launch
        XCTAssertTrue(app.buttons["Continue with Apple"].exists)

        // Take a screenshot of the launch screen
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Launch Screen"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
