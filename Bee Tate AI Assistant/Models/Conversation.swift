//
//  Conversation.swift
//  Bee Tate AI Assistant
//

import Foundation
import SwiftData

@Model
final class Conversation {
    var id: UUID
    var title: String
    var createdAt: Date
    var updatedAt: Date
    @Relationship(deleteRule: .cascade) var messages: [Message] = []

    init(title: String = "New Conversation", createdAt: Date = Date()) {
        self.id = UUID()
        self.title = title
        self.createdAt = createdAt
        self.updatedAt = createdAt
    }

    func addMessage(_ message: Message) {
        messages.append(message)
        updatedAt = Date()
    }

    func updateTitle(_ newTitle: String) {
        title = newTitle
        updatedAt = Date()
    }
}