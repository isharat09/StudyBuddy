import SwiftUI
import SwiftData

@Observable
class StatsViewModel {

    // MARK: - Streak
    func currentStreak(sessions: [StudySession]) -> Int {
        let calendar = Calendar.current
        let studiedDays = Set(sessions.map { calendar.startOfDay(for: $0.startTime) })
        var streak = 0
        var date = calendar.startOfDay(for: Date())

        while studiedDays.contains(date) {
            streak += 1
            guard let prev = calendar.date(byAdding: .day, value: -1, to: date) else { break }
            date = prev
        }
        return streak
    }

    func longestStreak(sessions: [StudySession]) -> Int {
        let calendar = Calendar.current
        let days = Set(sessions.map { calendar.startOfDay(for: $0.startTime) })
            .sorted()
        guard !days.isEmpty else { return 0 }

        var longest = 1
        var current = 1
        for i in 1..<days.count {
            let diff = calendar.dateComponents([.day], from: days[i-1], to: days[i]).day ?? 0
            if diff == 1 {
                current += 1
                longest = max(longest, current)
            } else {
                current = 1
            }
        }
        return longest
    }

    // MARK: - Weekly data
    func weeklyHours(sessions: [StudySession]) -> Double {
        let start = Calendar.current.startOfWeek(for: Date())
        let total = sessions
            .filter { $0.startTime >= start }
            .reduce(0.0) { $0 + $1.durationSeconds }
        return total / 3600
    }

    func dailyStudyData(sessions: [StudySession]) -> [DayStudyData] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return (0..<7).reversed().map { offset -> DayStudyData in
            guard let day = calendar.date(byAdding: .day, value: -offset, to: today) else {
                return DayStudyData(date: today, hours: 0)
            }
            let hours = sessions
                .filter { calendar.isDate($0.startTime, inSameDayAs: day) }
                .reduce(0.0) { $0 + $1.durationSeconds } / 3600
            return DayStudyData(date: day, hours: hours)
        }
    }

    func subjectBreakdown(sessions: [StudySession]) -> [SubjectStudyData] {
        let start = Calendar.current.startOfWeek(for: Date())
        let weekly = sessions.filter { $0.startTime >= start }
        var dict: [String: (Subject?, Double)] = [:]

        for s in weekly {
            let key = s.subject?.name ?? "Untagged"
            let existing = dict[key]?.1 ?? 0
            dict[key] = (s.subject, existing + s.durationSeconds / 3600)
        }

        let total = dict.values.reduce(0.0) { $0 + $1.1 }
        return dict.map { key, val in
            SubjectStudyData(name: key, subject: val.0, hours: val.1, percentage: total > 0 ? val.1 / total : 0)
        }.sorted { $0.hours > $1.hours }
    }

    // MARK: - Productivity
    func peakHour(sessions: [StudySession]) -> String? {
        guard !sessions.isEmpty else { return nil }
        var hourCounts = [Int: Double]()
        for s in sessions {
            let h = Calendar.current.component(.hour, from: s.startTime)
            hourCounts[h, default: 0] += s.durationSeconds
        }
        guard let peak = hourCounts.max(by: { $0.value < $1.value })?.key else { return nil }
        let fmt = DateFormatter()
        fmt.dateFormat = "h a"
        let d = Calendar.current.date(bySettingHour: peak, minute: 0, second: 0, of: Date())!
        return fmt.string(from: d)
    }

    func tasksCompletedThisWeek(tasks: [Task]) -> Int {
        let start = Calendar.current.startOfWeek(for: Date())
        return tasks.filter { $0.isCompleted && ($0.completedAt ?? Date()) >= start }.count
    }

    func totalStudyHoursFormatted(sessions: [StudySession]) -> String {
        let total = sessions.reduce(0.0) { $0 + $1.durationSeconds }
        let h = Int(total) / 3600
        let m = (Int(total) % 3600) / 60
        if h > 0 { return "\(h)h \(m)m" }
        return "\(m)m"
    }
}

struct DayStudyData: Identifiable {
    let id = UUID()
    let date: Date
    let hours: Double

    var dayLabel: String {
        let fmt = DateFormatter()
        fmt.dateFormat = "EEE"
        return String(fmt.string(from: date).prefix(1))
    }

    var isToday: Bool {
        Calendar.current.isDateInToday(date)
    }
}

struct SubjectStudyData: Identifiable {
    let id = UUID()
    let name: String
    let subject: Subject?
    let hours: Double
    let percentage: Double

    var hoursFormatted: String {
        let h = Int(hours)
        let m = Int((hours - Double(h)) * 60)
        if h > 0 { return "\(h)h \(m)m" }
        return "\(m)m"
    }

    var color: Color {
        subject?.color ?? AppColors.primary
    }
}
