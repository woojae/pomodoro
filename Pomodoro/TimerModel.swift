import Foundation

enum TimerPhase: String {
    case idle = "Ready"
    case working = "Work"
    case onBreak = "Break"
}

@Observable
@MainActor
final class TimerModel {
    private(set) var phase: TimerPhase = .idle
    private(set) var remainingSeconds: Int = 25 * 60
    private(set) var isPaused: Bool = false
    var currentTask: String = ""
    var awaitingReflection: Bool = false

    private var timer: Timer?

    private static let workDuration = 25 * 60
    private static let breakDuration = 5 * 60

    var displayTime: String {
        let m = remainingSeconds / 60
        let s = remainingSeconds % 60
        return String(format: "%02d:%02d", m, s)
    }

    var menuBarTitle: String {
        switch phase {
        case .idle:
            return "🍅"
        case .working, .onBreak:
            return "🍅 \(displayTime)"
        }
    }

    var onPhaseComplete: ((TimerPhase) -> Void)?

    func start() {
        phase = .working
        remainingSeconds = Self.workDuration
        isPaused = false
        startTimer()
    }

    func pause() {
        isPaused = true
        stopTimer()
    }

    func resume() {
        isPaused = false
        startTimer()
    }

    func startBreak() {
        awaitingReflection = false
        phase = .onBreak
        remainingSeconds = Self.breakDuration
        startTimer()
    }

    func reset() {
        stopTimer()
        phase = .idle
        remainingSeconds = Self.workDuration
        isPaused = false
        currentTask = ""
        awaitingReflection = false
    }

    private func startTimer() {
        stopTimer()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.tick()
            }
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    private func tick() {
        guard remainingSeconds > 0 else { return }
        remainingSeconds -= 1

        if remainingSeconds == 0 {
            let completedPhase = phase
            stopTimer()

            switch completedPhase {
            case .working:
                onPhaseComplete?(.working)
                awaitingReflection = true
            case .onBreak:
                onPhaseComplete?(.onBreak)
                phase = .idle
                remainingSeconds = Self.workDuration
            case .idle:
                break
            }
        }
    }
}
