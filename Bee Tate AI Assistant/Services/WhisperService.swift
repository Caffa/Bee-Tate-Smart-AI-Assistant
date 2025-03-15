//
//  WhisperService.swift
//  Bee Tate AI Assistant
//

import Foundation
import AVFoundation
import Accelerate
import SwiftUI
import UniformTypeIdentifiers

class WhisperService: NSObject, ObservableObject {
    enum WhisperError: Error {
        case transcriptionFailed
        case invalidAudioFile
        case modelNotFound
        case conversionFailed
        case whisperProcessError(String)
        case downloadError(String)
        case userCancelled
    }

    // Published properties to allow UI to react to service state
    @Published var isModelDownloading = false
    @Published var downloadProgress: Float = 0
    @Published var modelStatus: ModelStatus = .unknown

    // Model states
    enum ModelStatus {
        case unknown
        case notFound
        case downloading
        case ready
        case error(String)
    }

    private let modelName = "large-v3"
    private var modelURL: URL
    private let userDefaultsKey = "WhisperModelPath"

    // Reusable download task to allow cancellation
    private var downloadTask: URLSessionDownloadTask?

    override init() {
        // Check if we have a saved model path in UserDefaults
        if let savedPath = UserDefaults.standard.string(forKey: userDefaultsKey) {
            modelURL = URL(fileURLWithPath: savedPath)
        } else {
            // Define the default model directory in the app's documents folder
            let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            let whisperDirectory = documentsDirectory.appendingPathComponent("whisper")

            // Create directory if it doesn't exist
            if !FileManager.default.fileExists(atPath: whisperDirectory.path) {
                try? FileManager.default.createDirectory(at: whisperDirectory, withIntermediateDirectories: true)
            }

            modelURL = whisperDirectory.appendingPathComponent("\(modelName).bin")
        }

        // Must call super.init() before accessing self
        super.init()

        // Check if model exists
        checkModelStatus()
    }

    // Check if the model exists and update status accordingly
    func checkModelStatus() {
        if FileManager.default.fileExists(atPath: modelURL.path) {
            modelStatus = .ready
        } else {
            modelStatus = .notFound
        }
    }

    // Method to handle model acquisition when it doesn't exist
    func acquireModel() async throws {
        // If we're already downloading, don't start again
        guard !isModelDownloading else { return }

        if FileManager.default.fileExists(atPath: modelURL.path) {
            modelStatus = .ready
            return
        }

        // Create alert to ask user preference
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.main.async {
                let alert = UIAlertController(
                    title: "Whisper Model Required",
                    message: "The Whisper \(self.modelName) model is required for transcription. Would you like to download it (approx. 4GB) or locate it on your device?",
                    preferredStyle: .alert
                )

                alert.addAction(UIAlertAction(title: "Download", style: .default) { _ in
                    self.downloadModel { result in
                        switch result {
                        case .success:
                            continuation.resume()
                        case .failure(let error):
                            continuation.resume(throwing: error)
                        }
                    }
                })

                alert.addAction(UIAlertAction(title: "Browse", style: .default) { _ in
                    self.browseForModel { result in
                        switch result {
                        case .success:
                            continuation.resume()
                        case .failure(let error):
                            continuation.resume(throwing: error)
                        }
                    }
                })

                alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in
                    continuation.resume(throwing: WhisperError.userCancelled)
                })

                // Find the top-most view controller to present the alert
                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                   let rootViewController = windowScene.windows.first?.rootViewController {
                    var topController = rootViewController
                    while let presentedController = topController.presentedViewController {
                        topController = presentedController
                    }
                    topController.present(alert, animated: true)
                }
            }
        }
    }

    // Download model from HuggingFace
    func downloadModel(completion: @escaping (Result<Void, Error>) -> Void) {
        guard let downloadURL = URL(string: "https://huggingface.co/ggerganov/whisper.cpp/resolve/main/\(modelName).bin") else {
            DispatchQueue.main.async {
                self.modelStatus = .error("Invalid download URL")
                completion(.failure(WhisperError.downloadError("Invalid download URL")))
            }
            return
        }

        // Create parent directory if it doesn't exist
        let parentDir = modelURL.deletingLastPathComponent()
        if !FileManager.default.fileExists(atPath: parentDir.path) {
            do {
                try FileManager.default.createDirectory(at: parentDir, withIntermediateDirectories: true)
            } catch {
                DispatchQueue.main.async {
                    self.modelStatus = .error("Failed to create directory: \(error.localizedDescription)")
                    completion(.failure(error))
                }
                return
            }
        }

        // Set up download task with progress tracking
        let session = URLSession(configuration: .default, delegate: self, delegateQueue: nil)

        DispatchQueue.main.async {
            self.isModelDownloading = true
            self.downloadProgress = 0
            self.modelStatus = .downloading
        }

        downloadTask = session.downloadTask(with: downloadURL) { tempURL, response, error in
            DispatchQueue.main.async {
                self.isModelDownloading = false

                if let error = error {
                    self.modelStatus = .error("Download failed: \(error.localizedDescription)")
                    completion(.failure(error))
                    return
                }

                guard let tempURL = tempURL else {
                    self.modelStatus = .error("Download failed: No file received")
                    completion(.failure(WhisperError.downloadError("No file received")))
                    return
                }

                do {
                    // If file exists at destination, remove it first
                    if FileManager.default.fileExists(atPath: self.modelURL.path) {
                        try FileManager.default.removeItem(at: self.modelURL)
                    }

                    try FileManager.default.moveItem(at: tempURL, to: self.modelURL)

                    // Save the path to UserDefaults
                    UserDefaults.standard.set(self.modelURL.path, forKey: self.userDefaultsKey)

                    self.modelStatus = .ready
                    completion(.success(()))
                } catch {
                    self.modelStatus = .error("Failed to save model: \(error.localizedDescription)")
                    completion(.failure(error))
                }
            }
        }

        downloadTask?.resume()
    }

    // Browse for model file
    func browseForModel(completion: @escaping (Result<Void, Error>) -> Void) {
        DispatchQueue.main.async {
            let documentPicker = UIDocumentPickerViewController(forOpeningContentTypes: [UTType.data])
            documentPicker.allowsMultipleSelection = false

            // Fixed bug: Changed from trailing closure syntax to proper property assignment
            documentPicker.delegate = DocumentPickerDelegate { urls in
                guard let selectedURL = urls.first else {
                    completion(.failure(WhisperError.userCancelled))
                    return
                }

                // Start accessing the selected URL
                let shouldStopAccessing = selectedURL.startAccessingSecurityScopedResource()

                defer {
                    if shouldStopAccessing {
                        selectedURL.stopAccessingSecurityScopedResource()
                    }
                }

                do {
                    // Save the selected path to UserDefaults
                    UserDefaults.standard.set(selectedURL.path, forKey: self.userDefaultsKey)

                    // Update our model URL to the selected file
                    self.modelURL = selectedURL

                    self.modelStatus = .ready
                    completion(.success(()))
                } catch {
                    self.modelStatus = .error("Failed to use selected model: \(error.localizedDescription)")
                    completion(.failure(error))
                }
            }

            // Find the top-most view controller to present the document picker
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let rootViewController = windowScene.windows.first?.rootViewController {
                var topController = rootViewController
                while let presentedController = topController.presentedViewController {
                    topController = presentedController
                }
                topController.present(documentPicker, animated: true)
            }
        }
    }

    // Helper class for document picker delegate
    private class DocumentPickerDelegate: NSObject, UIDocumentPickerDelegate {
        private let completion: ([URL]) -> Void

        init(completion: @escaping ([URL]) -> Void) {
            self.completion = completion
            super.init()
        }

        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            completion(urls)
        }

        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            completion([])
        }
    }

    // Cancel any ongoing download
    func cancelDownload() {
        downloadTask?.cancel()
        downloadTask = nil

        DispatchQueue.main.async {
            self.isModelDownloading = false
            self.downloadProgress = 0
            self.modelStatus = .notFound
        }
    }

    // New async version that checks for model and handles download if needed
    func transcribeAudio(from url: URL) async throws -> String {
        // Check if model is available, if not, acquire it
        if !FileManager.default.fileExists(atPath: modelURL.path) {
            try await acquireModel()
        }

        // Now proceed with transcription using the model
        return try await withCheckedThrowingContinuation { continuation in
            transcribeAudio(from: url) { result in
                switch result {
                case .success(let transcript):
                    continuation.resume(returning: transcript)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    // Original transcription method (used by the async version above)
    func transcribeAudio(from url: URL, completion: @escaping (Result<String, Error>) -> Void) {
        DispatchQueue.global().async {
            do {
                // Check if the file exists and is an audio file
                let fileManager = FileManager.default
                if !fileManager.fileExists(atPath: url.path) {
                    throw WhisperError.invalidAudioFile
                }

                // Check if model exists
                if !fileManager.fileExists(atPath: self.modelURL.path) {
                    throw WhisperError.modelNotFound
                }

                // Convert audio to 16kHz WAV (float array)
                let audioData = try self.convertAudioToFloatArray(from: url)

                // Process with whisper.cpp
                let transcription = try self.transcribeWithWhisper(audioData: audioData)

                DispatchQueue.main.async {
                    completion(.success(transcription))
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
    }

    // Convert audio file to float array for whisper.cpp
    private func convertAudioToFloatArray(from url: URL) throws -> [Float] {
        // Set up AVAsset for the audio file
        let asset = AVAsset(url: url)

        // Use synchronous alternative to avoid async call
        let audioTracks = asset.tracks(withMediaType: .audio)
        let audioTrack = audioTracks.first

        guard let audioTrack = audioTrack else {
            throw WhisperError.invalidAudioFile
        }

        // Create a temporary URL for the converted file
        let temporaryDirectory = FileManager.default.temporaryDirectory
        let convertedURL = temporaryDirectory.appendingPathComponent(UUID().uuidString).appendingPathExtension("wav")

        // Set up AVAssetExportSession with the appropriate presets
        let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetAppleM4A)!

        // Configure the export session
        exportSession.outputURL = convertedURL
        exportSession.outputFileType = .wav
        exportSession.audioMix = AVAudioMix()
        exportSession.audioTimePitchAlgorithm = .spectral

        // Create an audio settings dictionary for conversion to 16kHz mono PCM
        let audioSettings: [String: Any] = [
            AVFormatIDKey: kAudioFormatLinearPCM,
            AVSampleRateKey: 16000.0,
            AVNumberOfChannelsKey: 1,
            AVLinearPCMBitDepthKey: 16,
            AVLinearPCMIsFloatKey: false,
            AVLinearPCMIsBigEndianKey: false,
            AVLinearPCMIsNonInterleaved: false
        ]

        // Export to temporary file synchronously
        let semaphore = DispatchSemaphore(value: 0)
        var exportError: Error?

        exportSession.exportAsynchronously {
            exportError = exportSession.error
            semaphore.signal()
        }

        _ = semaphore.wait(timeout: .distantFuture)

        if let error = exportError {
            throw error
        }

        // Read the WAV file into a float array
        guard let audioFile = try? AVAudioFile(forReading: convertedURL) else {
            throw WhisperError.conversionFailed
        }

        let format = audioFile.processingFormat
        let frameCount = AVAudioFrameCount(audioFile.length)

        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else {
            throw WhisperError.conversionFailed
        }

        try audioFile.read(into: buffer)

        var floatArray: [Float] = []

        // If we have float data, use it directly
        if let floatData = buffer.floatChannelData {
            let channelData = floatData[0]
            floatArray = Array(UnsafeBufferPointer(start: channelData, count: Int(buffer.frameLength)))
        }
        // If we have integer data, convert it to float
        else if let int16Data = buffer.int16ChannelData {
            let channelData = int16Data[0]
            let int16Buffer = UnsafeBufferPointer(start: channelData, count: Int(buffer.frameLength))

            floatArray = int16Buffer.map { Float($0) / Float(Int16.max) }
        }

        // Clean up temporary file
        try? FileManager.default.removeItem(at: convertedURL)

        return floatArray
    }

    // Process audio with whisper.cpp
    private func transcribeWithWhisper(audioData: [Float]) throws -> String {
        // Initialize whisper context with the model
        guard let ctx = whisper_init_from_file(modelURL.path) else {
            throw WhisperError.whisperProcessError("Failed to initialize whisper context")
        }

        // Ensure proper cleanup
        defer {
            whisper_free(ctx)
        }

        // Set up whisper parameters
        var wparams = whisper_full_default_params(WHISPER_SAMPLING_GREEDY)

        // Configure parameters
        wparams.print_realtime   = false
        wparams.print_progress   = false
        wparams.print_timestamps = false
        wparams.print_special    = false
        wparams.translate        = false
        wparams.language         = nil // auto-detect
        wparams.n_threads        = Int32(max(1, min(8, ProcessInfo.processInfo.processorCount - 1)))
        wparams.offset_ms        = 0
        wparams.no_context       = false
        wparams.single_segment   = false
        wparams.max_len          = 0 // default max segment length

        // Disable OpenCL
        wparams.use_gpu          = true // Keep true for Metal acceleration

        // Explicitly prefer Accelerate framework and disable OpenCL
        #if GGML_USE_ACCELERATE
            // Using Apple's Accelerate framework
            print("Using Accelerate framework for optimization")
        #endif

        #if !GGML_USE_OPENCL
            print("OpenCL disabled for this build")
        #endif

        // Process audio with whisper
        let result = whisper_full(ctx, wparams, audioData, Int32(audioData.count))

        if result != 0 {
            throw WhisperError.whisperProcessError("Failed to process audio")
        }

        // Combine all segments to get the full transcript
        var transcript = ""
        let n_segments = whisper_full_n_segments(ctx)

        for i in 0..<n_segments {
            if let segment_text = whisper_full_get_segment_text(ctx, i) {
                let text = String(cString: segment_text)
                transcript += text + " "
            }
        }

        return transcript.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

// MARK: - URLSessionDownloadDelegate
extension WhisperService: URLSessionDownloadDelegate {
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        // The final handling is done in the completion handler of downloadTask
    }

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        let progress = Float(totalBytesWritten) / Float(totalBytesExpectedToWrite)

        DispatchQueue.main.async {
            self.downloadProgress = progress
        }
    }
}

