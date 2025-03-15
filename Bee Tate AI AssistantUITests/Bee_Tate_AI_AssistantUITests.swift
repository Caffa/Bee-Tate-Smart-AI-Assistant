//
//  Bee_Tate_AI_AssistantUITests.swift
//  Bee Tate AI AssistantUITests
//
//  Created by Pamela on 15/3/25.
//

import XCTest

final class Bee_Tate_AI_AssistantUITests: XCTestCase {

    let app = XCUIApplication()

    override func setUpWithError() throws {
        continueAfterFailure = false
        app.launch()
    }

    override func tearDownWithError() throws {
        // Clean up after each test
    }

    // MARK: - Navigation Tests

    @MainActor
    func testNavigationFlow() throws {
        // Test conversation list navigation
        XCTAssertTrue(app.navigationBars["Conversations"].exists)

        // Test creating new conversation
        app.buttons["New Conversation"].tap()
        XCTAssertTrue(app.navigationBars["New Conversation"].exists)
    }

    // MARK: - Recording Tests

    @MainActor
    func testRecordingFlow() throws {
        // Navigate to recording view
        app.buttons["New Conversation"].tap()

        // Test recording button states
        let recordButton = app.buttons["Record"]
        XCTAssertTrue(recordButton.exists)
        recordButton.tap()

        // Wait for recording state
        let stopButton = app.buttons["Stop"]
        XCTAssertTrue(stopButton.waitForExistence(timeout: 5))
        stopButton.tap()

        // Verify transcription appears
        let transcriptionText = app.staticTexts["TranscriptionText"]
        XCTAssertTrue(transcriptionText.waitForExistence(timeout: 10))
    }

    // MARK: - Accessibility Tests

    @MainActor
    func testAccessibility() throws {
        // Test main navigation accessibility
        XCTAssertTrue(app.navigationBars["Conversations"].buttons["New Conversation"].isAccessibilityElement)

        // Test recording controls accessibility
        app.buttons["New Conversation"].tap()
        XCTAssertTrue(app.buttons["Record"].isAccessibilityElement)
    }

    // MARK: - Performance Tests

    @MainActor
    func testLaunchPerformance() throws {
        if #available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 7.0, *) {
            measure(metrics: [XCTApplicationLaunchMetric()]) {
                XCUIApplication().launch()
            }
        }
    }

    @MainActor
    func testConversationListPerformance() throws {
        measure {
            app.buttons["New Conversation"].tap()
            app.navigationBars.buttons["Back"].tap()
        }
    }
}

