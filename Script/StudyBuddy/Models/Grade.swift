import SwiftData
import Foundation

@Model
class Grade {
    var title: String
    var score: Double
    var maxScore: Double
    var date: Date
    var gradeType: GradeType
    var notes: String

    var subject: Subject?

    init(title: String, score: Double, maxScore: Double, date: Date = Date(), gradeType: GradeType = .assignment, subject: Subject? = nil) {
        self.title = title
        self.score = score
        self.maxScore = maxScore
        self.date = date
        self.gradeType = gradeType
        self.notes = ""
        self.subject = subject
    }

    var percentage: Double {
        guard maxScore > 0 else { return 0 }
        return (score / maxScore) * 100
    }

    var letterGrade: String {
        switch percentage {
        case 90...100: return "A"
        case 80..<90: return "B"
        case 70..<80: return "C"
        case 60..<70: return "D"
        default: return "F"
        }
    }

    var gradeColor: String {
        switch percentage {
        case 90...100: return "#1D9E75"
        case 80..<90: return "#534AB7"
        case 70..<80: return "#BA7517"
        case 60..<70: return "#D85A30"
        default: return "#E24B4A"
        }
    }
}

enum GradeType: String, Codable, CaseIterable {
    case exam = "Exam"
    case quiz = "Quiz"
    case assignment = "Assignment"
    case project = "Project"
    case lab = "Lab"
    case participation = "Participation"
    case other = "Other"
}
