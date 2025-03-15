//
//  ModelStatusView.swift
//  Bee Tate AI Assistant
//

import SwiftUI

struct ModelStatusView: View {
    @ObservedObject var whisperService: WhisperService

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            switch whisperService.modelStatus {
            case .downloading:
                VStack(alignment: .leading) {
                    Text("Downloading Whisper model...")
                        .font(.headline)

                    HStack {
                        ProgressView(value: whisperService.downloadProgress)
                            .progressViewStyle(LinearProgressViewStyle())

                        Text(String(format: "%.1f%%", whisperService.downloadProgress * 100))
                            .font(.caption)
                            .padding(.leading, 5)
                    }

                    Button("Cancel") {
                        whisperService.cancelDownload()
                    }
                    .padding(.top, 5)
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(10)

            case .notFound:
                VStack(alignment: .leading, spacing: 8) {
                    Text("Whisper Model Required")
                        .font(.headline)

                    Text("The Whisper large-v3 model is needed for transcription.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    HStack {
                        Button("Download Model") {
                            // Using Task to create an async context
                            Task {
                                do {
                                    try await whisperService.acquireModel()
                                } catch {
                                    print("Failed to download model: \(error)")
                                }
                            }
                        }
                        .buttonStyle(.borderedProminent)

                        Button("Browse Files") {
                            whisperService.browseForModel { _ in }
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding(.top, 5)
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(10)

            case .error(let message):
                VStack(alignment: .leading, spacing: 8) {
                    Text("Error")
                        .font(.headline)
                        .foregroundColor(.red)

                    Text(message)
                        .font(.subheadline)

                    Button("Try Again") {
                        // Using Task to create an async context
                        Task {
                            do {
                                try await whisperService.acquireModel()
                            } catch {
                                print("Failed to download model: \(error)")
                            }
                        }
                    }
                    .padding(.top, 5)
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(10)

            case .ready, .unknown:
                EmptyView()
            }
        }
        .padding(.horizontal)
    }
}

struct ModelStatusView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            let service = WhisperService()

            ModelStatusView(whisperService: service)
                .previewDisplayName("Model Not Found")
                .onAppear {
                    service.modelStatus = .notFound
                }

            ModelStatusView(whisperService: service)
                .previewDisplayName("Downloading")
                .onAppear {
                    service.modelStatus = .downloading
                    service.downloadProgress = 0.45
                }

            ModelStatusView(whisperService: service)
                .previewDisplayName("Error")
                .onAppear {
                    service.modelStatus = .error("Failed to download the model. Check your internet connection.")
                }
        }
    }
}

