//
//  ObserverUITests.swift
//  ObserverUITests
//
//  Created by Jiwon Kim on 9/10/24.
//

import XCTest

final class ObserverUITests: XCTestCase {

    let app = XCUIApplication()

    override func setUpWithError() throws {
        continueAfterFailure = false
        app.launch()
    }

    override func tearDownWithError() throws {
        // Add code for clean up, if needed
    }

    // Test for Apple Sign-In button in the login flow
    func testAppleSignInButton() {
        // Check if the Apple sign-in button exists
        let signInButton = app.buttons["Continue with Apple"]
        XCTAssertTrue(signInButton.exists)

        // Simulate a tap and handle a successful login flow
        signInButton.tap()

        // Mock response and check if navigated to home or agreement
        XCTAssertTrue(app.otherElements["HomeView"].exists || app.otherElements["AgreementView"].exists)
    }

    // Test for Like/Unlike button functionality in ProductDetailView
    func testLikeButtonFunctionality() {
        // Navigate to product detail
        let productDetail = app.buttons["ProductDetailButton"] // assuming button exists for navigation
        productDetail.tap()

        // Check if the like button exists and its default state
        let likeButton = app.buttons["heart"]
        XCTAssertTrue(likeButton.exists)

        // Toggle the like button and check state change
        likeButton.tap()
        XCTAssertTrue(app.buttons["heart.fill"].exists)

        // Simulate logged-out state and ensure alert appears
        app.buttons["heart.fill"].tap()
        XCTAssertTrue(app.alerts["로그인 필요"].exists)
    }

    // Test the search bar and search result view
    func testSearchFunctionality() {
        // Tap search bar and enter a query
        let searchBar = app.textFields["상품 검색"]
        XCTAssertTrue(searchBar.exists)
        searchBar.tap()
        searchBar.typeText("셔츠")

        // Simulate search action and check for results
        app.buttons["검색"].tap()

        // Validate search results are displayed or no results message
        let product = app.staticTexts["오버사이즈 셔츠"]
        XCTAssertTrue(product.exists || app.staticTexts["검색 결과가 없습니다."].exists)
    }

    // Test for checking agreement view and continue button functionality
    func testAgreementView() {
        // Navigate to Agreement View
        let agreementView = app.buttons["ContinueToAgreement"] // assuming navigation
        agreementView.tap()

        // Verify all checkboxes
        let agreeAllCheckbox = app.buttons["전체 동의"]
        let termsCheckbox = app.buttons["(필수) 서비스 이용 약관 동의"]

        XCTAssertTrue(agreeAllCheckbox.exists)
        XCTAssertTrue(termsCheckbox.exists)

        // Test that the continue button is disabled until agreements are checked
        let continueButton = app.buttons["동의하고 계속하기"]
        XCTAssertFalse(continueButton.isEnabled)

        // Check all agreements and verify button is enabled
        agreeAllCheckbox.tap()
        XCTAssertTrue(continueButton.isEnabled)

        // Tap continue and check if navigated to Home
        continueButton.tap()
        XCTAssertTrue(app.otherElements["HomeView"].exists)
    }

    // Test for infinite scrolling in search results
    func testInfiniteScroll() {
        // Navigate to Search Results
        app.textFields["상품 검색"].tap()
        app.textFields["상품 검색"].typeText("셔츠")
        app.buttons["검색"].tap()

        // Simulate scrolling to the bottom
        let lastProduct = app.staticTexts["Product Name Last"]
        app.swipeUp()  // Simulate scroll

        // Check that more products are loaded after scrolling
        XCTAssertTrue(lastProduct.exists)
    }

    // Test the logout flow
    func testLogoutFlow() {
        // Perform logout
        let logoutButton = app.buttons["로그아웃"]
        XCTAssertTrue(logoutButton.exists)
        logoutButton.tap()

        // Check that user is navigated back to login screen
        XCTAssertTrue(app.buttons["Continue with Apple"].exists)
    }

    // Performance test for app launch time
    func testLaunchPerformance() throws {
        if #available(iOS 13.0, *) {
            measure(metrics: [XCTApplicationLaunchMetric()]) {
                app.launch()
            }
        }
    }
}
