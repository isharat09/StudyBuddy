import SwiftUI
import SwiftData

@main
struct StudyBuddyApp: App {
    // Create the container once at the app level and share it everywhere,
    // including sheets — this is the correct fix for SwiftData + .sheet
    let container: ModelContainer

    init() {
        do {
            container = try ModelContainer(for:
                Subject.self,
                Task.self,
                StudySession.self,
                Grade.self,
                Note.self,
                ScheduleItem.self
            )
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(container)
    }
}
