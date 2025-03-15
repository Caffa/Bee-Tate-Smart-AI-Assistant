//
//  RecordingView.swift
//  Bee Tate AI Assistant
//

import SwiftUI
import AVFoundation

struct RecordingView: View {
    var conversation: Conversation

    @StateObject private var audioService = AudioRecordingService()
    @StateObject private var whisperService = WhisperService()
    @State private var isRecording = false
    @State private var isProcessing = false
    @State private var recordingURL: URL? = nil
    @State private var originalTranscription = ""
    @State private var enhancedTranscription = ""
    @State private var showFollowUpQuestions = false
    @State private var followUpQuestions: [String] = []
    @State private var transcriptionError: String? = nil

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    private let lmStudioService = LMStudioService()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Show model status if not ready
                if whisperService.modelStatus != .ready {
                    ModelStatusView(whisperService: whisperService)
                        .padding(.vertical, 10)
                }

                // Show error message if transcription failed
                if let error = transcriptionError {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Transcription Error")
                            .font(.headline)
                            .foregroundColor(.red)

                        Text(error)
                            .font(.subheadline)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(8)
                    }
                    .padding()
                }

                // Recording controls
                HStack {
                    Spacer()

                    VStack {
                        // Audio level visualization
                        ZStack {
                            Circle()
                                .stroke(Color.gray.opacity(0.2), lineWidth: 4)
                                .frame(width: 100, height: 100)

                            Circle()
                                .trim(from: 0, to: isRecording ? 1 : 0)
                                .stroke(Color.blue, lineWidth: 4)
                                .frame(width: 100, height: 100)
                                .rotationEffect(.degrees(-90))
                                .animation(.linear(duration: 1), value: isRecording)

                            // Audio level indicator
                            if isRecording {
                                AudioLevelView(level: audioService.audioLevels)
                                    .frame(width: 80, height: 80)
                            }

                            Button(action: {
                                if isRecording {
                                    stopRecording()
                                } else {
                                    startRecording()
                                }
                            }) {
                                Image(systemName: isRecording ? "stop.fill" : "mic.fill")
                                    .font(.system(size: 40))
                                    .foregroundColor(isRecording ? .red : .blue)
                            }
                            .disabled(isProcessing || whisperService.modelStatus == .downloading)
                        }

                        if isRecording {
                            Text(formatDuration(audioService.recordingDuration))
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.top, 8)
                        }
                    }

                    Spacer()
                }
                .padding()

                if isProcessing {
                    HStack {
                        Spacer()
                        ProgressView("Processing...")
                        Spacer()
                    }
                }

                // Display transcription results
                if !originalTranscription.isEmpty {
                    VStack(alignment: .leading, spacing: 16) {
                        // Playback controls for the recording
                        if let url = recordingURL {
                            HStack {
                                Button(action: {
                                    if audioService.recordingState == .playing {
                                        audioService.stopPlayback()
                                    } else {
                                        audioService.playRecording(from: url)
                                    }
                                }) {
                                    Label(
                                        audioService.recordingState == .playing ? "Stop" : "Play Recording",
                                        systemImage: audioService.recordingState == .playing ? "stop.fill" : "play.fill"
                                    )
                                }
                                .buttonStyle(.bordered)
                            }
                            .padding(.bottom, 8)
                        }

                        // Transcription sections
                        TranscriptionSection(title: "Original Transcription", content: originalTranscription)

                        TranscriptionSection(title: "Enhanced Transcription", content: enhancedTranscription)

                        // Follow-up questions
                        if showFollowUpQuestions && !followUpQuestions.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Follow-up Questions")
                                    .font(.headline)
                                    .padding(.top, 8)

                                ForEach(followUpQuestions, id: \.self) { question in
                                    Button(action: {
                                        // In a real app, this would start a new recording with context
                                    }) {
                                        Text(question)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                            .padding()
                                            .background(Color.blue.opacity(0.1))
                                            .cornerRadius(8)
                                    }
                                }
                            }
                            .padding(.top, 8)
                        }

                        // Generate follow-up questions button
                        if !enhancedTranscription.isEmpty && !showFollowUpQuestions {
                            Button("Generate Follow-up Questions") {
                                generateFollowUpQuestions()
                            }
                            .buttonStyle(.bordered)
                            .padding(.top, 8)
                        }
                    }
                    .padding()
                }
            }
        }
        .navigationTitle(conversation.title)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button("Convert to Twitter Post") {
                        convertToPost(format: "Twitter")
                    }
                    Button("Convert to Substack Post") {
                        convertToPost(format: "Substack")
                    }
                } label: {
                    Label("Convert", systemImage: "arrow.up.doc")
                }
                .disabled(enhancedTranscription.isEmpty)
            }
        }
    }

    private func startRecording() {
        audioService.startRecording()
        isRecording = true

        // Reset state
        originalTranscription = ""
        enhancedTranscription = ""
        showFollowUpQuestions = false
        followUpQuestions = []
        transcriptionError = nil
    }

    private func stopRecording() {
        guard let url = audioService.stopRecording() else { return }

        isRecording = false
        isProcessing = true
        recordingURL = url

        // Process the recording
        processRecording(url: url)
    }

    private func processRecording(url: URL) {
        // Use the async version of transcribeAudio that handles model downloading
        Task {
            do {
                // This will automatically handle downloading the model if needed
                let transcription = try await whisperService.transcribeAudio(from: url)
                await MainActor.run {
                    self.originalTranscription = transcription
                    // Step 2: Enhance the transcription using LM Studio
                    self.enhanceTranscription(transcription)
                }
            } catch {
                await MainActor.run {
                    self.isProcessing = false
                    self.transcriptionError = error.localizedDescription
                }
            }
        }
    }

    private func enhanceTranscription(_ transcription: String) {
        lmStudioService.enhanceTranscription(transcription) { enhanceResult in
            switch enhanceResult {
            case .success(let enhanced):
                self.enhancedTranscription = enhanced

                // Step 3: Generate a title for the conversation
                self.lmStudioService.generateTitle(from: enhanced) { titleResult in
                    switch titleResult {
                    case .success(let title):
                        // Update the conversation title
                        self.conversation.updateTitle(title)

                        // Step 4: Save the message
                        let message = Message(
                            audioURL: self.recordingURL!,
                            originalTranscription: self.originalTranscription,
                            enhancedTranscription: self.enhancedTranscription
                        )
                        self.conversation.addMessage(message)

                    case .failure(let error):
                        print("Failed to generate title: \(error)")
                    }

                    self.isProcessing = false
                }

            case .failure(let error):
                print("Failed to enhance transcription: \(error)")
                self.isProcessing = false
            }
        }
    }

    private func generateFollowUpQuestions() {
        lmStudioService.generateFollowUpQuestions(from: enhancedTranscription) { result in
            switch result {
            case .success(let questions):
                self.followUpQuestions = questions
                self.showFollowUpQuestions = true
            case .failure(let error):
                print("Failed to generate follow-up questions: \(error)")
            }
        }
    }

    private func convertToPost(format: String) {
        // In a real app, this would open a new view to edit and save the post
        lmStudioService.convertToPost(text: enhancedTranscription, format: format) { result in
            switch result {
            case .success(let post):
                print("Generated \(format) post: \(post)")
                // In a real app, this would save the post or open a view to edit it
            case .failure(let error):
                print("Failed to convert to \(format) post: \(error)")
            }
        }
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

struct TranscriptionSection: View {
    var title: String
    var content: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)

            Text(content)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
        }
    }
}

struct AudioLevelView: View {
    var level: Float

    var body: some View {
        // Convert the audio level (which is typically negative) to a positive scale
        let normalizedLevel = min(max(1.0 + level / 50.0, 0.05), 1.0)

        ZStack {
            ForEach(0..<5, id: \.self) { i in
                Circle()
                    .stroke(Color.blue.opacity(Double(i) / 5.0), lineWidth: 2)
                    .scaleEffect(CGFloat(normalizedLevel) * (1.0 + Double(i) / 10.0))
                    .animation(.easeInOut(duration: 0.1), value: normalizedLevel)
            }
        }
    }
}

#Preview {
    NavigationStack {
        RecordingView(conversation: Conversation())
            .modelContainer(for: [Conversation.self, Message.self], inMemory: true)
    }
}

