//
//  AudioRecordingService.swift
//  Bee Tate AI Assistant
//

import Foundation
import AVFoundation
import Combine

class AudioRecordingService: NSObject, ObservableObject {
    enum RecordingState {
        case idle
        case recording
        case playing
    }

    @Published var recordingState: RecordingState = .idle
    @Published var audioLevels: Float = 0.0
    @Published var recordingDuration: TimeInterval = 0.0

    private var audioRecorder: AVAudioRecorder?
    private var audioPlayer: AVAudioPlayer?
    private var recordingURL: URL?
    private var timer: Timer?

    private let audioSession = AVAudioSession.sharedInstance()

    override init() {
        super.init()
        setupAudioSession()
    }

    private func setupAudioSession() {
        do {
            try audioSession.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetooth])
            try audioSession.setActive(true)
        } catch {
            print("Failed to set up audio session: \(error)")
        }
    }

    func startRecording() {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let audioFilename = documentsPath.appendingPathComponent("\(UUID().uuidString).m4a")
        recordingURL = audioFilename

        let settings = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]

        do {
            audioRecorder = try AVAudioRecorder(url: audioFilename, settings: settings)
            audioRecorder?.delegate = self
            audioRecorder?.isMeteringEnabled = true
            audioRecorder?.record()

            recordingState = .recording
            recordingDuration = 0.0

            // Start a timer to update audio levels and duration
            timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
                guard let self = self, let recorder = self.audioRecorder else { return }

                recorder.updateMeters()
                self.audioLevels = recorder.averagePower(forChannel: 0)
                self.recordingDuration = recorder.currentTime
            }
        } catch {
            print("Could not start recording: \(error)")
        }
    }

    func stopRecording() -> URL? {
        timer?.invalidate()
        timer = nil

        audioRecorder?.stop()
        recordingState = .idle

        return recordingURL
    }

    func playRecording(from url: URL) {
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.delegate = self
            audioPlayer?.play()
            recordingState = .playing
        } catch {
            print("Could not play recording: \(error)")
        }
    }

    func stopPlayback() {
        audioPlayer?.stop()
        recordingState = .idle
    }

    deinit {
        timer?.invalidate()
        try? audioSession.setActive(false)
    }
}

extension AudioRecordingService: AVAudioRecorderDelegate {
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if !flag {
            print("Recording finished unsuccessfully")
        }
        recordingState = .idle
    }
}

extension AudioRecordingService: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        recordingState = .idle
    }
}