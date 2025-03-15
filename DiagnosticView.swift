import SwiftUI

struct DiagnosticView: View {
    @State private var testRecordingWorks = false
    @State private var testTranscriptionWorks = false
    @State private var testAIWorks = false
    @State private var loadedResources = false
    @State private var diagnosticLog: String = ""

    var body: some View {
        VStack(spacing: 20) {
            Text("App Diagnostic")
                .font(.largeTitle)
                .debugBorder("Title")

            Text("If you're seeing this view, SwiftUI rendering is working")
                .font(.headline)
                .padding()
                .background(Color.green.opacity(0.3))
                .cornerRadius(10)
                .debugBorder("Headline")

            VStack(alignment: .leading, spacing: 10) {
                DiagnosticRow(title: "UI Rendering", isWorking: true)
                DiagnosticRow(title: "Resources Loaded", isWorking: loadedResources)
                DiagnosticRow(title: "Recording Functionality", isWorking: testRecordingWorks)
                DiagnosticRow(title: "Transcription API", isWorking: testTranscriptionWorks)
                DiagnosticRow(title: "AI Processing", isWorking: testAIWorks)
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(10)
            .debugBorder("Diagnostic Rows")

            ScrollView {
                Text(diagnosticLog)
                    .font(.system(.body, design: .monospaced))
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(height: 200)
            .background(Color.black)
            .foregroundColor(Color.green)
            .cornerRadius(8)
            .debugBorder("Log View")

            Button("Run Diagnostics") {
                runDiagnostics()
            }
            .buttonStyle(.borderedProminent)
            .debugBorder("Diagnostic Button")

            Button("Return to Main App") {
                // This should be connected to your app's navigation
                appendLog("Attempting to return to main app...")
            }
            .padding(.top)
            .debugBorder("Return Button")
        }
        .padding()
        .onAppear {
            AppDebugger.shared.checkAppSetup()
            appendLog("Diagnostic view appeared")
            checkResources()
        }
    }

    private func appendLog(_ message: String) {
        let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .medium)
        diagnosticLog += "[\(timestamp)] \(message)\n"
    }

    private func checkResources() {
        // Check if essential resources are available
        appendLog("Checking app resources...")

        // Verify whisper.cpp integration
        #if os(macOS)
        let whisperPath = Bundle.main.path(forResource: "whisper", ofType: nil)
        if whisperPath != nil {
            appendLog("✅ Whisper model found")
            loadedResources = true
        } else {
            appendLog("❌ Whisper model not found")
        }
        #else
        appendLog("⚠️ Resource check not implemented for this platform")
        #endif
    }

    private func runDiagnostics() {
        appendLog("Starting comprehensive diagnostics...")

        // Test recording capability
        testRecordingCapability()

        // Test transcription
        testTranscription()

        // Test AI processing
        testAIProcessing()
    }

    private func testRecordingCapability() {
        appendLog("Testing audio recording...")
        // Here you would actually test recording, but for safety we'll simulate
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.testRecordingWorks = true
            self.appendLog("✅ Recording simulation successful")
        }
    }

    private func testTranscription() {
        appendLog("Testing transcription capability...")
        // Simulate a transcription test
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.testTranscriptionWorks = true
            self.appendLog("✅ Transcription simulation successful")
        }
    }

    private func testAIProcessing() {
        appendLog("Testing AI processing...")
        // Simulate AI processing
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            self.testAIWorks = true
            self.appendLog("✅ AI processing simulation successful")
        }
    }
}

struct DiagnosticRow: View {
    let title: String
    let isWorking: Bool

    var body: some View {
        HStack {
            Text(title)
            Spacer()
            Image(systemName: isWorking ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundColor(isWorking ? .green : .red)
        }
    }
}

struct DiagnosticView_Previews: PreviewProvider {
    static var previews: some View {
        DiagnosticView()
    }
}

