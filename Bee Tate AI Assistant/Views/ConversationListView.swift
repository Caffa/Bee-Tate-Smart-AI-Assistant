//
//  ConversationListView.swift
//  Bee Tate AI Assistant
//

import SwiftUI
import SwiftData

struct ConversationListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var conversations: [Conversation]
    @State private var isRecording = false
    @State private var showingNewConversation = false

    var body: some View {
        NavigationStack {
            VStack {
                List {
                    ForEach(conversations) { conversation in
                        NavigationLink(destination: ConversationDetailView(conversation: conversation)) {
                            VStack(alignment: .leading) {
                                Text(conversation.title)
                                    .font(.headline)
                                Text("\(conversation.messages.count) messages")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                Text(conversation.updatedAt, format: .dateTime)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .onDelete(perform: deleteConversations)
                }
                .listStyle(InsetGroupedListStyle())
                .navigationTitle("Conversations")
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        EditButton()
                    }
                }

                Button(action: {
                    let newConversation = Conversation()
                    modelContext.insert(newConversation)
                    showingNewConversation = true
                }) {
                    ZStack {
                        Circle()
                            .fill(Color.blue)
                            .frame(width: 70, height: 70)

                        Image(systemName: "mic.fill")
                            .font(.system(size: 30))
                            .foregroundColor(.white)
                    }
                }
                .padding(.bottom, 20)
                .navigationDestination(isPresented: $showingNewConversation) {
                    if let newConversation = conversations.first {
                        RecordingView(conversation: newConversation)
                    }
                }
            }
        }
    }

    private func deleteConversations(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(conversations[index])
            }
        }
    }
}

#Preview {
    ConversationListView()
        .modelContainer(for: [Conversation.self, Message.self], inMemory: true)
}