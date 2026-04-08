import SwiftUI
import SwiftData
import Combine

@Observable
class TimerViewModel {
    // MARK: - State
    var isRunning = false
    var isPaused = false
    var currentPhase: PomodoroPhase = .focus
    var secondsRemaining: Int = 25 * 60
    var secondsElapsed: Int = 0
    var sessionCount: Int = 0
    var selectedSubject: Subject?
    var usePomodoro: Bool = true
    var sessionNotes: String = ""

    // Settings
    var focusMinutes: Int = 25
    var shortBreakMinutes: Int = 5
    var longBreakMinutes: Int = 15
    var sessionsUntilLongBreak: Int = 4

    // Current live session (not yet saved)
    var currentSession: StudySession?

    private var timer: Timer?
    private var modelContext: ModelContext?

    var progress: Double {
        let total: Double
        switch currentPhase {
        case .focus: total = Double(focusMinutes * 60)
        case .shortBreak: total = Double(shortBreakMinutes * 60)
        case .longBreak: total = Double(longBreakMinutes * 60)
        }
        guard total > 0 else { return 0 }
        return 1.0 - (Double(secondsRemaining) / total)
    }

    var timeString: String {
        let m = secondsRemaining / 60
        let s = secondsRemaining % 60
        return String(format: "%02d:%02d", m, s)
    }

    var elapsedString: String {
        let h = secondsElapsed / 3600
        let m = (secondsElapsed % 3600) / 60
        let s = secondsElapsed % 60
        if h > 0 { return String(format: "%d:%02d:%02d", h, m, s) }
        return String(format: "%02d:%02d", m, s)
    }

    var phaseName: String {
        if usePomodoro {
            return currentPhase.rawValue
        }
        return "Free Study"
    }

    var sessionLabel: String {
        "Session \(sessionCount + 1) of \(sessionsUntilLongBreak)"
    }

    func setContext(_ context: ModelContext) {
        self.modelContext = context
    }

    // MARK: - Controls

    func start() {
        guard !isRunning else { return }
        isRunning = true
        isPaused = false

        if currentSession == nil {
            let session = StudySession(startTime: Date(), subject: selectedSubject, isPomodoro: usePomodoro, pomodoroPhase: currentPhase)
            currentSession = session
            modelContext?.insert(session)
        }

        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.tick()
        }
    }

    func pause() {
        isRunning = false
        isPaused = true
        timer?.invalidate()
        timer = nil
        saveCurrentSession()
    }

    func resume() {
        start()
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        isRunning = false
        isPaused = false
        saveCurrentSession()
        currentSession = nil
        reset()
    }

    func skip() {
        timer?.invalidate()
        timer = nil
        isRunning = false
        saveCurrentSession()
        currentSession = nil
        advancePhase()
    }

    // MARK: - Internal

    private func tick() {
        secondsElapsed += 1
        currentSession?.durationSeconds = Double(secondsElapsed)

        if usePomodoro {
            if secondsRemaining > 0 {
                secondsRemaining -= 1
            } else {
                phaseCompleted()
            }
        }
    }

    private func phaseCompleted() {
        timer?.invalidate()
        timer = nil
        isRunning = false

        HapticManager.notification(.success)
        NotificationManager.shared.sendPhaseCompleteNotification(phase: currentPhase)

        saveCurrentSession()
        currentSession = nil
        advancePhase()
    }

    private func advancePhase() {
        switch currentPhase {
        case .focus:
            sessionCount += 1
            if sessionCount % sessionsUntilLongBreak == 0 {
                currentPhase = .longBreak
                secondsRemaining = longBreakMinutes * 60
            } else {
                currentPhase = .shortBreak
                secondsRemaining = shortBreakMinutes * 60
            }
        case .shortBreak, .longBreak:
            currentPhase = .focus
            secondsRemaining = focusMinutes * 60
        }
        secondsElapsed = 0
    }

    private func reset() {
        secondsRemaining = focusMinutes * 60
        secondsElapsed = 0
        currentPhase = .focus
        sessionCount = 0
    }

    private func saveCurrentSession() {
        guard let session = currentSession, session.durationSeconds > 5 else { return }
        session.endTime = Date()
        try? modelContext?.save()
    }

    func applySettings() {
        if !isRunning {
            secondsRemaining = focusMinutes * 60
        }
    }
}
