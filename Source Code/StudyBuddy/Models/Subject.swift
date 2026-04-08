import SwiftUI
import SwiftData

@Model
class Subject {
    var name: String
    var colorHex: String
    var icon: String
    var scheduleType: ScheduleType
    var createdAt: Date

    @Relationship(deleteRule: .cascade) var tasks: [Task] = []
    @Relationship(deleteRule: .cascade) var sessions: [StudySession] = []
    @Relationship(deleteRule: .cascade) var grades: [Grade] = []
    @Relationship(deleteRule: .cascade) var notes: [Note] = []
    @Relationship(deleteRule: .cascade) var scheduleItems: [ScheduleItem] = []

    init(name: String, colorHex: String = "#534AB7", icon: String = "book.closed", scheduleType: ScheduleType = .weekly) {
        self.name = name
        self.colorHex = colorHex
        self.icon = icon
        self.scheduleType = scheduleType
        self.createdAt = Date()
    }

    var color: Color {
        Color(hex: colorHex) ?? AppColors.primary
    }

    var averageGrade: Double? {
        guard !grades.isEmpty else { return nil }
        let total = grades.reduce(0.0) { $0 + $1.percentage }
        return total / Double(grades.count)
    }

    var totalStudyTime: TimeInterval {
        sessions.compactMap { $0.durationSeconds }.reduce(0, +)
    }

    var totalStudyTimeFormatted: String {
        let hours = Int(totalStudyTime) / 3600
        let minutes = (Int(totalStudyTime) % 3600) / 60
        if hours > 0 { return "\(hours)h \(minutes)m" }
        return "\(minutes)m"
    }
}

enum ScheduleType: String, Codable, CaseIterable {
    case weekly = "Weekly"
    case aWeek = "A Week"
    case bWeek = "B Week"
    case both = "Both Weeks"
}
