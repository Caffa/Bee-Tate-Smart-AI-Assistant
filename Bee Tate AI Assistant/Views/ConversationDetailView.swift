//
//  ConversationDetailView.swift
//  Bee Tate AI Assistant
//

import SwiftUI
import SwiftData

struct ConversationDetailView: View {
    var conversation: Conversation
    @State private var showingRecordingView = false

    var body: some View {
        List {
            ForEach(conversation.messages) { message in
                MessageRow(message: message)
            }
        }
        .navigationTitle(conversation.title)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    showingRecordingView = true
                }) {
                    Image(systemName: "mic.circle.fill")
                        .font(.title2)
                }
            }
        }
        .navigationDestination(isPresented: $showingRecordingView) {
            RecordingView(conversation: conversation)
        }
    }
}

struct MessageRow: View {
    var message: Message
    @StateObject private var audioService = AudioRecordingService()

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(message.createdAt, format: .dateTime)
                    .font(.caption)
                    .foregroundColor(.secondary)

                Spacer()

                if let audioURL = message.audioURL {
                    Button(action: {
                        if audioService.recordingState == .playing {
                            audioService.stopPlayback()
                        } else {
                            audioService.playRecording(from: audioURL)
                        }
                    }) {
                        Label(
                            audioService.recordingState == .playing ? "Stop" : "Play",
                            systemImage: audioService.recordingState == .playing ? "stop.fill" : "play.fill"
                        )
                        .font(.caption)
                    }
                    .buttonStyle(.bordered)
                }
            }

            DisclosureGroup("Original Transcription") {
                Text(message.originalTranscription)
                    .padding(8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
            }

            Text(message.enhancedTranscription)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(8)
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    let conversation = Conversation(title: "Sample Conversation")
    let message = Message(
        originalTranscription: "This is a sample original transcription with um, like, filler words and stuff.",
        enhancedTranscription: "This is a sample enhanced transcription with filler words removed and improved clarity."
    )
    conversation.addMessage(message)

    return NavigationStack {
        ConversationDetailView(conversation: conversation)
            .modelContainer(for: [Conversation.self, Message.self], inMemory: true)
    }
}