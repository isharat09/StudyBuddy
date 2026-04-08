import SwiftData
import Foundation

@Model
class Note {
    var content: String
    var title: String
    var createdAt: Date
    var updatedAt: Date

    var subject: Subject?

    init(title: String = "", content: String = "", subject: Subject? = nil) {
        self.title = title
        self.content = content
        self.createdAt = Date()
        self.updatedAt = Date()
        self.subject = subject
    }
}

@Model
class ScheduleItem {
    var title: String
    var location: String
    var startTime: Date
    var endTime: Date
    var itemType: ScheduleItemType
    var weekday: Int            // 1 = Sunday … 7 = Saturday
    var scheduleWeek: ScheduleType
    var isRecurring: Bool
    var colorHex: String

    var subject: Subject?

    init(title: String, location: String = "", startTime: Date, endTime: Date, itemType: ScheduleItemType = .class_, weekday: Int = 2, scheduleWeek: ScheduleType = .weekly, isRecurring: Bool = true, subject: Subject? = nil) {
        self.title = title
        self.location = location
        self.startTime = startTime
        self.endTime = endTime
        self.itemType = itemType
        self.weekday = weekday
        self.scheduleWeek = scheduleWeek
        self.isRecurring = isRecurring
        self.colorHex = subject?.colorHex ?? "#534AB7"
        self.subject = subject
    }

    var durationMinutes: Int {
        Int(endTime.timeIntervalSince(startTime) / 60)
    }

    var timeRangeFormatted: String {
        let fmt = DateFormatter()
        fmt.dateFormat = "h:mm a"
        return "\(fmt.string(from: startTime)) – \(fmt.string(from: endTime))"
    }
}

enum ScheduleItemType: String, Codable, CaseIterable {
    case class_ = "Class"
    case exam = "Exam"
    case studyBlock = "Study Block"
    case lab = "Lab"
    case tutorial = "Tutorial"
    case other = "Other"

    var icon: String {
        switch self {
        case .class_: return "building.columns"
        case .exam: return "doc.text"
        case .studyBlock: return "timer"
        case .lab: return "flask"
        case .tutorial: return "person.2"
        case .other: return "calendar"
        }
    }
}
