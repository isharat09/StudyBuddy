📚 StudyBuddy – iOS Study Planner App

StudyBuddy is a modern iOS study management application built using SwiftUI and SwiftData. It helps students organize their academic life by combining tasks, schedules, study sessions, notes, and performance tracking into a single intuitive platform.


🚀 Features
📅 Smart Dashboard (Today View)
* View today's schedule and tasks in one place
* Highlights overdue tasks in red
* Displays active study streak
* Quick task completion with checkboxes


✅ Task Management
* Create, edit, and delete tasks
* Assign tasks to subjects
* Set priorities (Low / Medium / High)
* Add due dates and reminders
* Swipe actions for quick interactions
* Filter by subject and search tasks


⏱️ Focus Timer (Pomodoro)
* 25-min focus + 5-min break cycles
* Automatic phase switching
* Real-time circular countdown animation
* Tracks and saves study sessions
* Supports pause, skip, and stop


📊 Statistics & Analytics
* Weekly study hours
* Daily study bar chart (last 7 days)
* Subject-wise study breakdown
* Study streak tracking
* Peak productivity hour detection


📘 Subjects, Notes & Grades
* Create subjects with custom colors & icons
* Add notes per subject (auto-save)
* Track grades and calculate percentages
* View academic performance per subject


🗓️ Timetable System
* Add recurring schedule items
* Supports Weekly + A/B rotation system
* Displays schedule dynamically on Today screen


🔔 Notifications
* Task reminders
* Pomodoro session completion alerts
* Daily study reminder (streak protection)

🏗️ Architecture

The app follows the MVVM (Model-View-ViewModel) architecture.

Structure:
* View (SwiftUI) → UI Layer
* ViewModel → Business logic & state
* Model (SwiftData) → Data layer
* ModelContainer → Persistence

🗄️ Database Design (SwiftData)
StudyBuddy uses SwiftData, Apple’s modern ORM.

Models:
* Subject
* Task
* StudySession
* Grade
* Note
* ScheduleItem


Relationships:
* One Subject → Many Tasks
* One Subject → Many StudySessions
* One Subject → Many Grades
* One Subject → Many Notes
* One Subject → Many ScheduleItems
* Key Features:
* Uses @Model for persistence
* Uses @Relationship(deleteRule: .cascade)
* Auto UI updates using @Query


⚙️ Tech Stack
* Language: Swift 5.9
* UI Framework: SwiftUI
* Database: SwiftData
* Architecture: MVVM
* IDE: Xcode 15+
* Platform: iOS 17+


📂 Project Structure
StudyBuddy/
* │
* ├── Models/
│   * ├── Subject.swift
│   * ├── Task.swift
│   * ├── StudySession.swift
│   * ├── Grade.swift
│   * ├── Note.swift
│  *  └── ScheduleItem.swift
│
* ├── ViewModels/
│   * ├── TimerViewModel.swift
│   * └── StatsViewModel.swift
│
* ├── Views/
│   * ├── Today/
│   * ├── Tasks/
│   * ├── Timer/
│   * ├── Stats/
│   * └── Subjects/
│
* ├── Services/
│   * └── NotificationManager.swift
│
* ├── Utilities/
│   * └── Extensions.swift
│
* └── StudyBuddyApp.swift

Flow:
* Start session
* Create StudySession object
* Run timer every second
* Update duration live
* Save session on completion or stop


🧠 Key Concepts Implemented
* State management using @State, @Binding, @Observable
* Reactive UI updates using SwiftData
* MVVM separation of concerns
* Timer-based state machine
* Local notifications system
* Data persistence and relationships


▶️ How to Run
* Open project in Xcode 15+
* Select your development team
* Choose simulator (iOS 17+)
* Press ⌘R to run


📦 Deliverables
* Full iOS application
* GitHub repository
* Documentation
* Screenshots
* Final presentation


🔐 Data & Privacy
* No personal data collected
* All data stored locally
* No external APIs required


🙌 Future Improvements
* Cloud sync (iCloud / Firebase)
* Collaborative study groups
* AI-based study recommendations
* Widgets for quick access


👨‍💻 Author
* Isharat Jahan
* Bachleors of Computer Information System 
* iOS Developer


⭐ Acknowledgements
* Apple SwiftUI & SwiftData Documentation
* Course materials and tutorials

