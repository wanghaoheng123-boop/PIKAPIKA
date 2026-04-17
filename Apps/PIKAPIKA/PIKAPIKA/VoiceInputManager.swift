import AVFoundation
import Foundation
import Speech

@MainActor
final class VoiceInputManager: ObservableObject {
    @Published var isListening = false
    @Published var liveText = ""
    @Published var authorizationDenied = false

    private let audioEngine = AVAudioEngine()
    private let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private var recognitionTask: SFSpeechRecognitionTask?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?

    func toggle(onText: @escaping (String) -> Void) {
        if isListening {
            stop(commit: true, onText: onText)
        } else {
            Task { await start() }
        }
    }

    func stop(commit: Bool, onText: @escaping (String) -> Void) {
        guard isListening else { return }
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        isListening = false
        if commit, !liveText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            onText(liveText)
        }
        liveText = ""
    }

    private func start() async {
        do {
            let granted = await requestPermissions()
            guard granted else {
                authorizationDenied = true
                return
            }

            recognitionTask?.cancel()
            recognitionTask = nil

            let request = SFSpeechAudioBufferRecognitionRequest()
            request.shouldReportPartialResults = true
            recognitionRequest = request

            let node = audioEngine.inputNode
            let format = node.outputFormat(forBus: 0)
            node.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self] buffer, _ in
                self?.recognitionRequest?.append(buffer)
            }

            audioEngine.prepare()
            try audioEngine.start()

            isListening = true
            liveText = ""

            recognitionTask = recognizer?.recognitionTask(with: request) { [weak self] result, error in
                guard let self else { return }
                if let result {
                    self.liveText = result.bestTranscription.formattedString
                }
                if error != nil {
                    self.stop(commit: false, onText: { _ in })
                }
            }
        } catch {
            authorizationDenied = true
            stop(commit: false, onText: { _ in })
        }
    }

    private func requestPermissions() async -> Bool {
        let speech = await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status == .authorized)
            }
        }
        let mic = await withCheckedContinuation { continuation in
            AVAudioSession.sharedInstance().requestRecordPermission { ok in
                continuation.resume(returning: ok)
            }
        }
        return speech && mic
    }
}
