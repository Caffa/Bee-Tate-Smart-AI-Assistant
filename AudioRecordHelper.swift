import Foundation
import AVFoundation

class AudioRecordHelper: NSObject, AVAudioRecorderDelegate {
    private var audioRecorder: AVAudioRecorder?
    private var recordingURL: URL?
    private var completion: ((Result<URL, Error>) -> Void)?

    enum AudioRecordError: Error {
        case recordingInProgress
        case recordingFailed
        case noRecording
        case permissionDenied
    }

    func startRecording(completion: @escaping (Result<URL, Error>) -> Void) {
        self.completion = completion

        // Check if already recording
        if audioRecorder?.isRecording == true {
            completion(.failure(AudioRecordError.recordingInProgress))
            return
        }

        // Request permission
        AVAudioSession.sharedInstance().requestRecordPermission { [weak self] granted in
            guard let self = self else { return }

            if granted {
                self.setupRecorder()
            } else {
                DispatchQueue.main.async {
                    completion(.failure(AudioRecordError.permissionDenied))
                }
            }
        }
    }

    private func setupRecorder() {
        let audioSession = AVAudioSession.sharedInstance()

        do {
            try audioSession.setCategory(.record, mode: .default)
            try audioSession.setActive(true)

            // Create a temporary URL for the recording
            let tempDir = FileManager.default.temporaryDirectory
            let fileName = "recording_\(Date().timeIntervalSince1970).wav"
            let fileURL = tempDir.appendingPathComponent(fileName)

            // Recording settings for 16kHz mono WAV
            let settings: [String: Any] = [
                AVFormatIDKey: Int(kAudioFormatLinearPCM),
                AVSampleRateKey: 16000.0,
                AVNumberOfChannelsKey: 1,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue,
                AVLinearPCMBitDepthKey: 16,
                AVLinearPCMIsBigEndianKey: false,
                AVLinearPCMIsFloatKey: false
            ]

            audioRecorder = try AVAudioRecorder(url: fileURL, settings: settings)
            audioRecorder?.delegate = self

            if audioRecorder?.record() == true {
                recordingURL = fileURL
            } else {
                DispatchQueue.main.async {
                    self.completion?(.failure(AudioRecordError.recordingFailed))
                    self.completion = nil
                }
            }
        } catch {
            DispatchQueue.main.async {
                self.completion?(.failure(error))
                self.completion = nil
            }
        }
    }

    func stopRecording() {
        guard let recorder = audioRecorder, recorder.isRecording else {
            completion?(.failure(AudioRecordError.noRecording))
            completion = nil
            return
        }

        recorder.stop()

        // The audioRecorderDidFinishRecording delegate method will be called
    }

    // MARK: - AVAudioRecorderDelegate

    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if flag, let url = recordingURL {
            DispatchQueue.main.async {
                self.completion?(.success(url))
            }
        } else {
            DispatchQueue.main.async {
                self.completion?(.failure(AudioRecordError.recordingFailed))
            }
        }

        completion = nil
    }

    func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) {
        DispatchQueue.main.async {
            self.completion?(.failure(error ?? AudioRecordError.recordingFailed))
            self.completion = nil
        }
    }
}

