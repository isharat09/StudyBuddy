import SwiftUI
import SwiftData

@Model
class Task {
    var title: String
    var notes: String
    var dueDate: Date
    var priority: TaskPriority
    var type: TaskType
    var isCompleted: Bool
    var completedAt: Date?
    var createdAt: Date
    var reminderDate: Date?

    var subject: Subject?

    init(title: String, notes: String = "", dueDate: Date, priority: TaskPriority = .medium, type: TaskType = .homework, subject: Subject? = nil) {
        self.title = title
        self.notes = notes
        self.dueDate = dueDate
        self.priority = priority
        self.type = type
        self.isCompleted = false
        self.createdAt = Date()
        self.subject = subject
    }

    var isOverdue: Bool {
        !isCompleted && dueDate < Date()
    }

    var isDueToday: Bool {
        Calendar.current.isDateInToday(dueDate)
    }

    var isDueThisWeek: Bool {
        guard let endOfWeek = Calendar.current.date(byAdding: .day, value: 7, to: Date()) else { return false }
        return dueDate > Date() && dueDate <= endOfWeek
    }
}

enum TaskPriority: String, Codable, CaseIterable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"

    var color: Color {
        switch self {
        case .low: return .green
        case .medium: return .orange
        case .high: return .red
        }
    }

    var icon: String {
        switch self {
        case .low: return "arrow.down"
        case .medium: return "minus"
        case .high: return "arrow.up"
        }
    }
}

enum TaskType: String, Codable, CaseIterable {
    case homework = "Homework"
    case exam = "Exam"
    case project = "Project"
    case reading = "Reading"
    case assignment = "Assignment"
    case other = "Other"

    var icon: String {
        switch self {
        case .homework: return "pencil"
        case .exam: return "doc.text"
        case .project: return "folder"
        case .reading: return "book"
        case .assignment: return "paperclip"
        case .other: return "square.and.pencil"
        }
    }
}
