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
        if audioEngine.isRunning {
            audioEngine.stop()
        }
        if audioEngine.inputNode.numberOfInputs > 0 {
            audioEngine.inputNode.removeTap(onBus: 0)
        }
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        recognitionTask = nil
        recognitionRequest = nil
        let captured = liveText.trimmingCharacters(in: .whitespacesAndNewlines)
        isListening = false
        if commit, !captured.isEmpty {
            onText(captured)
        }
        liveText = ""
    }

    private func start() async {
        do {
            authorizationDenied = false
            let granted = await requestPermissions()
            guard granted else {
                authorizationDenied = true
                return
            }
            guard let recognizer, recognizer.isAvailable else {
                // Temporary recognizer availability issues should not show permission-denied UX.
                authorizationDenied = false
                return
            }

            stop(commit: false, onText: { _ in })

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

            recognitionTask = recognizer.recognitionTask(with: request) { [weak self] result, error in
                guard let self else { return }
                if let result {
                    self.liveText = result.bestTranscription.formattedString
                }
                if error != nil {
                    self.stop(commit: false, onText: { _ in })
                }
            }
        } catch {
            let status = SFSpeechRecognizer.authorizationStatus()
            authorizationDenied = (status == .denied || status == .restricted)
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
            AVAudioApplication.requestRecordPermission { ok in
                continuation.resume(returning: ok)
            }
        }
        return speech && mic
    }
}
