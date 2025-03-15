import SwiftUI

struct DebugLauncherView: View {
    @State private var showDiagnostic = false
    @State private var showMainApp = false
    @State private var isRecording = false
    @State private var transcriptionResult = ""
    @State private var isTranscribing = false

    // Create instances of our services
    private let audioRecorder = AudioRecordHelper()
    private let whisperService = WhisperService()

    var body: some View {
        VStack(spacing: 30) {
            Text("Bee-Tate AI Assistant")
                .font(.largeTitle)
                .fontWeight(.bold)

            Image(systemName: "ladybug.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 100)
                .foregroundColor(.red)

            Text("Debug Launcher")
                .font(.headline)

            VStack(spacing: 20) {
                Button("Launch Diagnostic View") {
                    showDiagnostic = true
                }
                .buttonStyle(.borderedProminent)

                Button("Launch Main Application") {
                    showMainApp = true
                }
                .buttonStyle(.bordered)

                Button(isRecording ? "Stop Recording" : "Test Simple Recording") {
                    if isRecording {
                        stopRecordingAndTranscribe()
                    } else {
                        startRecording()
                    }
                }
                .buttonStyle(isRecording ? .borderedProminent : .bordered)
                .foregroundColor(isRecording ? .red : nil)
                .disabled(isTranscribing)
            }

            if isTranscribing {
                ProgressView("Transcribing...")
                    .padding()
            }

            if !transcriptionResult.isEmpty {
                VStack(alignment: .leading) {
                    Text("Transcription Result:")
                        .font(.headline)

                    Text(transcriptionResult)
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding()
            }

            Text("If you can see this screen, SwiftUI rendering is working.")
                .font(.footnote)
                .padding()
                .background(Color.green.opacity(0.3))
                .cornerRadius(8)
        }
        .padding()
        .sheet(isPresented: $showDiagnostic) {
            DiagnosticView()
        }
        // Replace MainAppView with your actual main view
        .fullScreenCover(isPresented: $showMainApp) {
            Text("Main App Would Launch Here")
                .font(.largeTitle)
                .padding()
                .onTapGesture {
                    showMainApp = false
                }
        }
    }

    private func startRecording() {
        isRecording = true

        audioRecorder.startRecording { result in
            switch result {
            case .failure(let error):
                transcriptionResult = "Recording Error: \(error.localizedDescription)"
                isRecording = false
            case .success:
                // Recording started successfully
                break
            }
        }
    }

    private func stopRecordingAndTranscribe() {
        isRecording = false
        isTranscribing = true

        audioRecorder.stopRecording()

        // In a real implementation, you would:
        // 1. Get the recording URL from the audio recorder
        // 2. Pass it to the whisper service for transcription

        // For now, simulate getting the URL and transcribing
        DispatchQueue.global().async {
            // Simulate getting a recording URL
            let tempDir = FileManager.default.temporaryDirectory
            let recentRecordings = try? FileManager.default.contentsOfDirectory(at: tempDir, includingPropertiesForKeys: nil)
                .filter { $0.lastPathComponent.starts(with: "recording_") }
                .sorted(by: { $0.lastPathComponent > $1.lastPathComponent })

            if let recordingURL = recentRecordings?.first {
                // Transcribe the audio
                whisperService.transcribeAudio(from: recordingURL) { result in
                    DispatchQueue.main.async {
                        isTranscribing = false

                        switch result {
                        case .success(let text):
                            transcriptionResult = text
                        case .failure(let error):
                            transcriptionResult = "Transcription Error: \(error.localizedDescription)"
                        }
                    }
                }
            } else {
                DispatchQueue.main.async {
                    isTranscribing = false
                    transcriptionResult = "Error: No recording found"
                }
            }
        }
    }
}

struct DebugLauncherView_Previews: PreviewProvider {
    static var previews: some View {
        DebugLauncherView()
    }
}

