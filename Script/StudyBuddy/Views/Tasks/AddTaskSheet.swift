import SwiftUI
import SwiftData

struct AddTaskSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Subject.name) private var subjects: [Subject]

    var editTask: Task? = nil

    @State private var title = ""
    @State private var notes = ""
    @State private var dueDate = Date()
    @State private var priority: TaskPriority = .medium
    @State private var type: TaskType = .homework
    @State private var selectedSubject: Subject?
    @State private var setReminder = false
    @State private var reminderDate = Date()
    @State private var didAppear = false

    var isEditing: Bool { editTask != nil }

    var body: some View {
        NavigationStack {
            Form {
                Section("Task Details") {
                    TextField("Title", text: $title)
                    TextField("Notes", text: $notes, axis: .vertical)
                        .lineLimit(3)
                }

                Section("Subject & Type") {
                    Picker("Subject", selection: $selectedSubject) {
                        Text("None").tag(Optional<Subject>.none)
                        ForEach(subjects) { s in
                            HStack {
                                Circle().fill(s.color).frame(width: 10, height: 10)
                                Text(s.name)
                            }.tag(Optional(s))
                        }
                    }

                    Picker("Type", selection: $type) {
                        ForEach(TaskType.allCases, id: \.self) { t in
                            Label(t.rawValue, systemImage: t.icon).tag(t)
                        }
                    }
                }

                Section("Due Date & Priority") {
                    DatePicker("Due Date", selection: $dueDate,
                               displayedComponents: [.date, .hourAndMinute])

                    // Custom 3-button priority selector — fixes segmented picker clipping bug
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Priority")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        HStack(spacing: 10) {
                            ForEach(TaskPriority.allCases, id: \.self) { p in
                                Button {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        priority = p
                                    }
                                } label: {
                                    HStack(spacing: 6) {
                                        Image(systemName: p.icon)
                                            .font(.system(size: 13, weight: .semibold))
                                        Text(p.rawValue)
                                            .font(.system(size: 14, weight: .semibold))
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                    .background(priority == p ? p.color : Color(.systemGray5))
                                    .foregroundStyle(priority == p ? .white : .primary)
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }

                Section("Reminder") {
                    Toggle("Set Reminder", isOn: $setReminder)
                    if setReminder {
                        DatePicker("Remind Me", selection: $reminderDate,
                                   displayedComponents: [.date, .hourAndMinute])
                    }
                }
            }
            .navigationTitle(isEditing ? "Edit Task" : "New Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isEditing ? "Save" : "Add") { saveTask() }
                        .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                        .fontWeight(.semibold)
                }
            }
            .onAppear {
                guard !didAppear else { return }
                didAppear = true
                if let t = editTask {
                    title = t.title
                    notes = t.notes
                    dueDate = t.dueDate
                    priority = t.priority
                    type = t.type
                    selectedSubject = t.subject
                    if let r = t.reminderDate {
                        setReminder = true
                        reminderDate = r
                    }
                }
            }
        }
    }

    private func saveTask() {
        let trimmed = title.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }

        if let task = editTask {
            task.title = trimmed
            task.notes = notes
            task.dueDate = dueDate
            task.priority = priority
            task.type = type
            task.subject = selectedSubject
            task.reminderDate = setReminder ? reminderDate : nil
            if setReminder { NotificationManager.shared.scheduleTaskReminder(for: task) }
        } else {
            let task = Task(
                title: trimmed,
                notes: notes,
                dueDate: dueDate,
                priority: priority,
                type: type,
                subject: selectedSubject
            )
            task.reminderDate = setReminder ? reminderDate : nil
            modelContext.insert(task)
            if setReminder { NotificationManager.shared.scheduleTaskReminder(for: task) }
        }

        do {
            try modelContext.save()
            HapticManager.notification(.success)
            dismiss()
        } catch {
            print("Save error: \(error)")
        }
    }
}
