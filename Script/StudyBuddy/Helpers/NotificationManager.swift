import UserNotifications
import Foundation

class NotificationManager {
    static let shared = NotificationManager()
    private init() {}

    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
    }

    func scheduleTaskReminder(for task: Task) {
        guard let reminder = task.reminderDate else { return }
        let content = UNMutableNotificationContent()
        content.title = task.type == .exam ? "Exam coming up!" : "Task due soon"
        content.body = "\(task.title)\(task.subject != nil ? " – \(task.subject!.name)" : "")"
        content.sound = .default

        let comps = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: reminder)
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
        let request = UNNotificationRequest(identifier: "task-\(task.persistentModelID)", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    func cancelTaskReminder(for task: Task) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["task-\(task.persistentModelID)"])
    }

    func sendPhaseCompleteNotification(phase: PomodoroPhase) {
        let content = UNMutableNotificationContent()
        switch phase {
        case .focus:
            content.title = "Focus session complete!"
            content.body = "Time for a break. Great work!"
        case .shortBreak:
            content.title = "Break over"
            content.body = "Ready to focus again?"
        case .longBreak:
            content.title = "Long break over"
            content.body = "You've completed a full Pomodoro cycle!"
        }
        content.sound = .default
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.5, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    func scheduleStreakReminder() {
        let content = UNMutableNotificationContent()
        content.title = "Keep your streak alive!"
        content.body = "You haven't studied yet today. Open StudyBuddy to log a session."
        content.sound = .default

        var comps = DateComponents()
        comps.hour = 20
        comps.minute = 0
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: true)
        let request = UNNotificationRequest(identifier: "daily-streak-reminder", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }
}
