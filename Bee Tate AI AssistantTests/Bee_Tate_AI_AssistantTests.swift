//
//  Bee_Tate_AI_AssistantTests.swift
//  Bee Tate AI AssistantTests
//
//  Created by Pamela on 15/3/25.
//

import XCTest

// Make sure XCTest framework is properly linked in your Xcode project:
// 1. In Xcode, go to your test target's Build Phases
// 2. Under 'Link Binary With Libraries', add XCTest.framework if not present
// 3. Verify that your test target is properly configured as a test bundle
@testable import Bee_Tate_AI_Assistant

final class BeeTateAIAssistantTests: XCTestCase {

    // MARK: - Setup

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    override func tearDownWithError() throws {
        // Clean up after each test
    }

    // MARK: - Audio Recording Tests

    func testAudioRecordingInitialization() throws {
        let recordHelper = AudioRecordHelper()
        XCTAssertNotNil(recordHelper, "AudioRecordHelper should initialize successfully")
    }

    func testAudioRecordingPermissions() async throws {
        let recordHelper = AudioRecordHelper()
        let hasPermission = await recordHelper.requestPermission()
        XCTAssertTrue(hasPermission, "App should have microphone permissions")
    }

    // MARK: - Transcription Service Tests

    func testWhisperServiceInitialization() throws {
        let whisperService = WhisperService()
        XCTAssertNotNil(whisperService, "WhisperService should initialize successfully")
    }

    func testTranscriptionWithSampleAudio() async throws {
        let whisperService = WhisperService()
        // Create a sample audio file path
        let sampleAudioPath = Bundle(for: type(of: self)).path(forResource: "sample_audio", ofType: "wav")
        XCTAssertNotNil(sampleAudioPath, "Sample audio file should exist")

        if let audioPath = sampleAudioPath {
            let result = await whisperService.transcribe(audioPath: audioPath)
            XCTAssertFalse(result.isEmpty, "Transcription result should not be empty")
        }
    }

    // MARK: - LMStudio Service Tests

    func testLMStudioServiceConnection() async throws {
        let lmStudioService = LMStudioService()
        let isConnected = await lmStudioService.testConnection()
        XCTAssertTrue(isConnected, "LMStudio service should be connected")
    }

    func testAIResponseGeneration() async throws {
        let lmStudioService = LMStudioService()
        let response = await lmStudioService.generateResponse(prompt: "Test prompt")
        XCTAssertFalse(response.isEmpty, "AI should generate a non-empty response")
    }

    // MARK: - Model Tests

    func testConversationModel() {
        let conversation = Conversation(id: UUID(), title: "Test Conversation", messages: [])
        XCTAssertEqual(conversation.title, "Test Conversation")
        XCTAssertTrue(conversation.messages.isEmpty)
    }

    func testMessageModel() {
        let message = Message(id: UUID(), content: "Test message", isUser: true)
        XCTAssertEqual(message.content, "Test message")
        XCTAssertTrue(message.isUser)
    }

    // MARK: - Performance Tests

    func testTranscriptionPerformance() throws {
        measure {
            let whisperService = WhisperService()
            let expectation = XCTestExpectation(description: "Transcription completion")

            Task {
                if let samplePath = Bundle(for: type(of: self)).path(forResource: "sample_audio", ofType: "wav") {
                    _ = await whisperService.transcribe(audioPath: samplePath)
                    expectation.fulfill()
                }
            }

            wait(for: [expectation], timeout: 10.0)
        }
    }

}

