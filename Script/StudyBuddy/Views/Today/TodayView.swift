import SwiftUI
import SwiftData

struct TodayView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \StudySession.startTime, order: .reverse) private var sessions: [StudySession]
    @Query(sort: \Task.dueDate) private var allTasks: [Task]
    @Query(sort: \ScheduleItem.startTime) private var allScheduleItems: [ScheduleItem]
    @Query(sort: \Subject.name) private var subjects: [Subject]

    @State private var showAddTask = false
    @State private var showAddScheduleItem = false
    @State private var selectedSubjectForSchedule: Subject?

    private var todayTasks: [Task] {
        allTasks.filter { $0.isDueToday && !$0.isCompleted }
    }

    private var overdueTasks: [Task] {
        allTasks.filter { $0.isOverdue }
    }

    private var todaySchedule: [ScheduleItem] {
        let weekday = Calendar.current.component(.weekday, from: Date())
        let parity = Calendar.current.currentWeekParity
        return allScheduleItems.filter { item in
            guard item.weekday == weekday else { return false }
            switch item.scheduleWeek {
            case .weekly, .both: return true
            case .aWeek: return parity == .aWeek
            case .bWeek: return parity == .bWeek
            }
        }.sorted { $0.startTime < $1.startTime }
    }

    private var streakCount: Int {
        StatsViewModel().currentStreak(sessions: sessions)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    headerSection

                    VStack(alignment: .leading, spacing: 16) {
                        if streakCount > 0 {
                            streakBanner.slideIn(delay: 0.05)
                        }

                        scheduleSection.slideIn(delay: 0.1)

                        if !overdueTasks.isEmpty {
                            taskSection(title: "Overdue", tasks: overdueTasks, color: .red)
                                .slideIn(delay: 0.15)
                        }

                        taskSection(title: "Due Today", tasks: todayTasks, color: AppColors.primary)
                            .slideIn(delay: 0.2)

                        Spacer(minLength: 20)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    // Add schedule item button
                    Button {
                        showAddScheduleItem = true
                    } label: {
                        Image(systemName: "calendar.badge.plus")
                            .fontWeight(.medium)
                    }
                    // Add task button
                    Button {
                        showAddTask = true
                    } label: {
                        Image(systemName: "plus")
                            .fontWeight(.medium)
                    }
                }
            }
            .sheet(isPresented: $showAddTask) {
                AddTaskSheet()
            }
            .sheet(isPresented: $showAddScheduleItem) {
                AddScheduleItemFromTodaySheet(subjects: subjects)
            }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(Date().formatted(date: .complete, time: .omitted))
                .font(.caption)
                .foregroundStyle(.secondary)
            Text("Good \(timeOfDayGreeting)")
                .font(.largeTitle)
                .fontWeight(.bold)
        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
        .padding(.bottom, 4)
    }

    private var timeOfDayGreeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 0..<12: return "Morning"
        case 12..<17: return "Afternoon"
        default: return "Evening"
        }
    }

    // MARK: - Streak Banner

    private var streakBanner: some View {
        HStack(spacing: 12) {
            Image(systemName: "flame.fill")
                .foregroundStyle(.orange)
                .font(.title2)
            VStack(alignment: .leading, spacing: 2) {
                Text("\(streakCount)-day streak!")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(AppColors.primary)
                Text("Keep it going — study something today")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(12)
        .background(AppColors.primaryLight)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Schedule Section

    private var scheduleSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label("Today's Schedule", systemImage: "calendar")
                    .font(.headline)
                Spacer()
                // Quick-add schedule button inline
                Button {
                    showAddScheduleItem = true
                } label: {
                    Image(systemName: "plus.circle")
                        .foregroundStyle(AppColors.primary)
                        .font(.subheadline)
                }
            }

            if todaySchedule.isEmpty {
                HStack(spacing: 10) {
                    Image(systemName: "calendar")
                        .foregroundStyle(.secondary)
                        .font(.title3)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("No classes today")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(.secondary)
                        Text("Tap + to add a class or study block")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                    Spacer()
                }
                .padding(12)
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(.separator).opacity(0.3), lineWidth: 0.5))
            } else {
                ForEach(todaySchedule) { item in
                    ScheduleItemRow(item: item)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }
                .animation(.easeInOut, value: todaySchedule.count)
            }
        }
    }

    // MARK: - Task Section

    private func taskSection(title: String, tasks: [Task], color: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.headline)
                if title == "Overdue" {
                    Text("\(tasks.count)")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.red)
                        .clipShape(Capsule())
                }
            }

            if tasks.isEmpty {
                HStack(spacing: 10) {
                    Image(systemName: "checkmark.circle")
                        .foregroundStyle(.secondary)
                    Text("Nothing due today")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                .padding(12)
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(.separator).opacity(0.3), lineWidth: 0.5))
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(tasks.enumerated()), id: \.element.persistentModelID) { index, task in
                        TaskRowView(task: task)
                        if index < tasks.count - 1 {
                            Divider().padding(.leading, 44)
                        }
                    }
                }
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(.separator).opacity(0.3), lineWidth: 0.5))
                .animation(.easeInOut, value: tasks.count)
            }
        }
    }
}

// MARK: - Schedule Item Row

// MARK: - Schedule Item Row

struct ScheduleItemRow: View {
    let item: ScheduleItem

    var body: some View {
        HStack(spacing: 10) {
            // Time badge — single line, no splitting
            VStack(spacing: 1) {
                Text(item.startTime.timeFormatted)
                    .font(.system(size: 10, weight: .bold))
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)
                Text("→ " + item.endTime.timeFormatted)
                    .font(.system(size: 9, weight: .regular))
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)
                    .foregroundStyle(.white.opacity(0.85))
            }
            .foregroundStyle(.white)
            .frame(width: 62, height: 38)
            .background(Color(hex: item.colorHex) ?? AppColors.primary)
            .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 2) {
                Text(item.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                HStack(spacing: 4) {
                    if !item.location.isEmpty {
                        Text(item.location)
                    }
                    Text("· \(item.durationMinutes) min")
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            Spacer()

            Text(item.itemType.rawValue)
                .font(.caption2)
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(Color(hex: item.colorHex)?.opacity(0.15) ?? AppColors.primaryLight)
                .foregroundStyle(Color(hex: item.colorHex) ?? AppColors.primary)
                .clipShape(Capsule())
        }
        .padding(10)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12)
            .stroke(Color(.separator).opacity(0.3), lineWidth: 0.5))
    }
}
// MARK: - Task Row View

struct TaskRowView: View {
    @Environment(\.modelContext) private var modelContext
    let task: Task

    var body: some View {
        HStack(spacing: 12) {
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    task.isCompleted.toggle()
                    task.completedAt = task.isCompleted ? Date() : nil
                    HapticManager.impact(.light)
                    if task.isCompleted {
                        NotificationManager.shared.cancelTaskReminder(for: task)
                    }
                    try? modelContext.save()
                }
            } label: {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(task.isCompleted ? .green : (task.subject?.color ?? AppColors.primary))
                    .scaleEffect(task.isCompleted ? 1.1 : 1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.5), value: task.isCompleted)
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 3) {
                Text(task.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .strikethrough(task.isCompleted)
                    .foregroundStyle(task.isCompleted ? .secondary : .primary)
                    .animation(.easeInOut(duration: 0.2), value: task.isCompleted)

                HStack(spacing: 6) {
                    if let subject = task.subject {
                        HStack(spacing: 3) {
                            Circle()
                                .fill(subject.color)
                                .frame(width: 6, height: 6)
                            Text(subject.name)
                                .foregroundStyle(.secondary)
                        }
                    }
                    Text(task.dueDate.friendlyDueDate)
                        .foregroundStyle(task.isOverdue ? .red : .secondary)
                }
                .font(.caption)
            }

            Spacer()

            priorityBadge
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
    }

    private var priorityBadge: some View {
        Text(task.priority.rawValue)
            .font(.caption2)
            .fontWeight(.semibold)
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background(badgeBg)
            .foregroundStyle(badgeFg)
            .clipShape(Capsule())
    }

    private var badgeBg: Color {
        switch task.priority {
        case .high:   return Color.red.opacity(0.12)
        case .medium: return Color.orange.opacity(0.12)
        case .low:    return Color.green.opacity(0.12)
        }
    }

    private var badgeFg: Color {
        switch task.priority {
        case .high:   return .red
        case .medium: return .orange
        case .low:    return .green
        }
    }
}

// MARK: - Add Schedule Item directly from Today screen

struct AddScheduleItemFromTodaySheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let subjects: [Subject]

    @State private var title = ""
    @State private var location = ""
    @State private var selectedSubject: Subject?
    @State private var startTime = Date()
    @State private var endTime = Date().addingTimeInterval(3600)
    @State private var itemType: ScheduleItemType = .class_
    @State private var weekday: Int = Calendar.current.component(.weekday, from: Date())
    @State private var scheduleWeek: ScheduleType = .weekly
    @State private var isRecurring = true

    let weekdays = ["Sunday","Monday","Tuesday","Wednesday","Thursday","Friday","Saturday"]

    var body: some View {
        NavigationStack {
            Form {
                Section("Details") {
                    TextField("Title (e.g. Calculus Lecture)", text: $title)
                    TextField("Location (optional)", text: $location)

                    Picker("Subject", selection: $selectedSubject) {
                        Text("None").tag(Optional<Subject>.none)
                        ForEach(subjects) { s in
                            HStack {
                                Circle().fill(s.color).frame(width: 10, height: 10)
                                Text(s.name)
                            }.tag(Optional(s))
                        }
                    }

                    Picker("Type", selection: $itemType) {
                        ForEach(ScheduleItemType.allCases, id: \.self) { t in
                            Label(t.rawValue, systemImage: t.icon).tag(t)
                        }
                    }
                }

                Section("Time") {
                    Picker("Day", selection: $weekday) {
                        ForEach(1...7, id: \.self) { d in
                            Text(weekdays[d - 1]).tag(d)
                        }
                    }
                    DatePicker("Start", selection: $startTime, displayedComponents: .hourAndMinute)
                    DatePicker("End", selection: $endTime, displayedComponents: .hourAndMinute)
                }

                Section("Recurrence") {
                    Toggle("Recurring weekly", isOn: $isRecurring)
                    if isRecurring {
                        Picker("Week type", selection: $scheduleWeek) {
                            ForEach(ScheduleType.allCases, id: \.self) { t in
                                Text(t.rawValue).tag(t)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                }
            }
            .navigationTitle("Add to Schedule")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") { save() }
                        .fontWeight(.semibold)
                        .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }

    private func save() {
        let colorHex = selectedSubject?.colorHex ?? "#534AB7"
        let item = ScheduleItem(
            title: title.trimmingCharacters(in: .whitespaces),
            location: location,
            startTime: startTime,
            endTime: endTime,
            itemType: itemType,
            weekday: weekday,
            scheduleWeek: scheduleWeek,
            isRecurring: isRecurring,
            subject: selectedSubject
        )
        _ = colorHex
        modelContext.insert(item)
        do {
            try modelContext.save()
            HapticManager.notification(.success)
            dismiss()
        } catch {
            print("Save error: \(error)")
        }
    }
}
