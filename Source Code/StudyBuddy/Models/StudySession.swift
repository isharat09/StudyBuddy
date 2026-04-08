import SwiftData
import Foundation

@Model
class StudySession {
    var startTime: Date
    var endTime: Date?
    var durationSeconds: TimeInterval
    var isPomodoro: Bool
    var pomodoroPhase: PomodoroPhase
    var notes: String

    var subject: Subject?

    init(startTime: Date = Date(), subject: Subject? = nil, isPomodoro: Bool = false, pomodoroPhase: PomodoroPhase = .focus) {
        self.startTime = startTime
        self.durationSeconds = 0
        self.isPomodoro = isPomodoro
        self.pomodoroPhase = pomodoroPhase
        self.notes = ""
        self.subject = subject
    }

    var durationFormatted: String {
        let h = Int(durationSeconds) / 3600
        let m = (Int(durationSeconds) % 3600) / 60
        let s = Int(durationSeconds) % 60
        if h > 0 { return String(format: "%d:%02d:%02d", h, m, s) }
        return String(format: "%02d:%02d", m, s)
    }

    var durationShort: String {
        let h = Int(durationSeconds) / 3600
        let m = (Int(durationSeconds) % 3600) / 60
        if h > 0 { return "\(h)h \(m)m" }
        return "\(m) min"
    }
}

enum PomodoroPhase: String, Codable {
    case focus = "Focus"
    case shortBreak = "Short Break"
    case longBreak = "Long Break"
}
