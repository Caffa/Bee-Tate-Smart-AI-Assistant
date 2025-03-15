import SwiftUI

@main
struct BeeTateAssistantApp: App {
    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            #if DEBUG
            // In debug mode, start with our debug launcher
            DebugLauncherView()
                .environmentObject(appState)
            #else
            // In release mode, use the normal app flow
            // Replace ContentView with your actual main view
            ContentView()
                .environmentObject(appState)
            #endif
        }
        .commands {
            CommandGroup(after: .help) {
                Button("Show Diagnostic View") {
                    openDiagnosticWindow()
                }
                .keyboardShortcut("D", modifiers: [.command, .option])
            }
        }
    }

    private func openDiagnosticWindow() {
        #if os(macOS)
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 600, height: 800),
            styleMask: [.titled, .closable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "Diagnostic View"
        window.contentView = NSHostingView(rootView: DiagnosticView().environmentObject(appState))
        window.center()
        window.makeKeyAndOrderFront(nil)
        #endif
    }
}

// Application state manager
class AppState: ObservableObject {
    @Published var isRecording = false
    @Published var currentConversation: Conversation?
    @Published var conversations: [Conversation] = []
    @Published var isProcessing = false
    @Published var errorMessage: String?

    // Debug properties
    @Published var isDebugMode = true
    @Published var logMessages: [String] = []

    func log(_ message: String) {
        let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .medium)
        let logMessage = "[\(timestamp)] \(message)"

        print(logMessage)

        DispatchQueue.main.async {
            self.logMessages.append(logMessage)
            // Keep log size manageable
            if self.logMessages.count > 100 {
                self.logMessages.removeFirst()
            }
        }
    }
}

// Simple model for conversation
struct Conversation: Identifiable {
    let id: UUID
    var title: String
    var messages: [Message]
    var createdAt: Date

    init(id: UUID = UUID(), title: String = "New Conversation", messages: [Message] = [], createdAt: Date = Date()) {
        self.id = id
        self.title = title
        self.messages = messages
        self.createdAt = createdAt
    }
}

struct Message: Identifiable {
    let id: UUID
    var audioURL: URL?
    var rawTranscription: String?
    var enhancedTranscription: String?
    var createdAt: Date

    init(id: UUID = UUID(), audioURL: URL? = nil, rawTranscription: String? = nil, enhancedTranscription: String? = nil, createdAt: Date = Date()) {
        self.id = id
        self.audioURL = audioURL
        self.rawTranscription = rawTranscription
        self.enhancedTranscription = enhancedTranscription
        self.createdAt = createdAt
    }
}

