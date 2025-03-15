//
//  Message.swift
//  Bee Tate AI Assistant
//

import Foundation
import SwiftData

@Model
final class Message {
    var id: UUID
    var audioURL: URL?
    var originalTranscription: String
    var enhancedTranscription: String
    var createdAt: Date

    init(audioURL: URL? = nil, originalTranscription: String = "", enhancedTranscription: String = "", createdAt: Date = Date()) {
        self.id = UUID()
        self.audioURL = audioURL
        self.originalTranscription = originalTranscription
        self.enhancedTranscription = enhancedTranscription
        self.createdAt = createdAt
    }
}