import SwiftUI
import SwiftData

// MARK: - Add Subject Sheet

struct AddSubjectSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    var editSubject: Subject? = nil

    @State private var name = ""
    @State private var selectedColorHex = "#534AB7"
    @State private var selectedIcon = "book.closed"
    @State private var scheduleType: ScheduleType = .weekly
    @State private var didAppear = false

    let icons = ["book.closed", "function", "flask", "globe", "music.note",
                 "paintbrush", "cpu", "heart", "chart.bar", "atom", "pencil", "folder"]

    var body: some View {
        NavigationStack {
            Form {
                Section("Subject Name") {
                    TextField("e.g. Calculus, Physics", text: $name)
                }

                Section("Color") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 9), spacing: 10) {
                        ForEach(AppColors.subjectColors, id: \.hex) { c in
                            ColorSwatch(hex: c.hex, isSelected: selectedColorHex == c.hex)
                                .onTapGesture {
                                    withAnimation(.easeInOut(duration: 0.15)) {
                                        selectedColorHex = c.hex
                                    }
                                }
                        }
                    }
                    .padding(.vertical, 4)
                }

                Section("Icon") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 12) {
                        ForEach(icons, id: \.self) { icon in
                            Image(systemName: icon)
                                .font(.system(size: 20))
                                .foregroundStyle(selectedIcon == icon
                                    ? Color(hex: selectedColorHex)!
                                    : .secondary)
                                .frame(width: 36, height: 36)
                                .background(selectedIcon == icon
                                    ? Color(hex: selectedColorHex)!.opacity(0.15)
                                    : Color(.systemGray6))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                .scaleEffect(selectedIcon == icon ? 1.1 : 1.0)
                                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: selectedIcon)
                                .onTapGesture { selectedIcon = icon }
                        }
                    }
                    .padding(.vertical, 4)
                }

                Section("Schedule Type") {
                    Picker("Rotation", selection: $scheduleType) {
                        ForEach(ScheduleType.allCases, id: \.self) { t in
                            Text(t.rawValue).tag(t)
                        }
                    }
                    .pickerStyle(.segmented)
                }
            }
            .navigationTitle(editSubject == nil ? "New Subject" : "Edit Subject")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(editSubject == nil ? "Add" : "Save") { save() }
                        .fontWeight(.semibold)
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear {
                guard !didAppear else { return }
                didAppear = true
                if let s = editSubject {
                    name = s.name
                    selectedColorHex = s.colorHex
                    selectedIcon = s.icon
                    scheduleType = s.scheduleType
                }
            }
        }
    }

    private func save() {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }

        if let s = editSubject {
            s.name = trimmed
            s.colorHex = selectedColorHex
            s.icon = selectedIcon
            s.scheduleType = scheduleType
        } else {
            let s = Subject(
                name: trimmed,
                colorHex: selectedColorHex,
                icon: selectedIcon,
                scheduleType: scheduleType
            )
            modelContext.insert(s)
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

// MARK: - Add Grade Sheet

struct AddGradeSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    let subject: Subject

    @State private var title = ""
    @State private var score = ""
    @State private var maxScore = "100"
    @State private var date = Date()
    @State private var gradeType: GradeType = .assignment
    @State private var notes = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Grade Info") {
                    TextField("Title (e.g. Midterm Exam)", text: $title)
                    Picker("Type", selection: $gradeType) {
                        ForEach(GradeType.allCases, id: \.self) { t in
                            Text(t.rawValue).tag(t)
                        }
                    }
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                }

                Section("Score") {
                    HStack {
                        TextField("Your Score", text: $score)
                            .keyboardType(.decimalPad)
                        Text("/")
                            .foregroundStyle(.secondary)
                        TextField("Max Score", text: $maxScore)
                            .keyboardType(.decimalPad)
                    }

                    if let s = Double(score), let m = Double(maxScore), m > 0 {
                        let pct = (s / m) * 100
                        HStack {
                            Text("Percentage")
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text(String(format: "%.1f%%", pct))
                                .fontWeight(.semibold)
                                .foregroundStyle(subject.color)
                        }
                    }
                }

                Section("Notes") {
                    TextField("Optional notes", text: $notes, axis: .vertical)
                        .lineLimit(3)
                }
            }
            .navigationTitle("Add Grade")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") { save() }
                        .fontWeight(.semibold)
                        .disabled(title.isEmpty || score.isEmpty || Double(score) == nil)
                }
            }
        }
    }

    private func save() {
        guard let s = Double(score), let m = Double(maxScore) else { return }
        let grade = Grade(title: title, score: s, maxScore: m,
                         date: date, gradeType: gradeType, subject: subject)
        grade.notes = notes
        modelContext.insert(grade)
        do {
            try modelContext.save()
            HapticManager.notification(.success)
            dismiss()
        } catch {
            print("Save error: \(error)")
        }
    }
}

// MARK: - Add Note Sheet

struct AddNoteSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    let subject: Subject

    @State private var title = ""
    @State private var content = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Title") {
                    TextField("Optional title", text: $title)
                }
                Section("Content") {
                    TextEditor(text: $content)
                        .frame(minHeight: 120)
                }
            }
            .navigationTitle("New Note")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        let note = Note(title: title, content: content, subject: subject)
                        modelContext.insert(note)
                        do {
                            try modelContext.save()
                            dismiss()
                        } catch {
                            print("Save error: \(error)")
                        }
                    }
                    .fontWeight(.semibold)
                    .disabled(content.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}

// MARK: - Note Editor

struct NoteEditorView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var note: Note

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            TextField("Title", text: $note.title)
                .font(.headline)
                .padding(.horizontal, 16)
                .padding(.top, 12)

            Divider().padding(.top, 8)

            TextEditor(text: $note.content)
                .padding(.horizontal, 12)
        }
        .navigationTitle("Note")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: note.content) { _, _ in
            note.updatedAt = Date()
            try? modelContext.save()
        }
        .onChange(of: note.title) { _, _ in
            note.updatedAt = Date()
            try? modelContext.save()
        }
    }
}

// MARK: - Add Schedule Item Sheet

struct AddScheduleItemSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    let subject: Subject

    @State private var title = ""
    @State private var location = ""
    @State private var startTime = Date()
    @State private var endTime = Date().addingTimeInterval(3600)
    @State private var itemType: ScheduleItemType = .class_
    @State private var weekday: Int = 2
    @State private var scheduleWeek: ScheduleType = .weekly
    @State private var isRecurring = true

    let weekdays = ["Sunday","Monday","Tuesday","Wednesday","Thursday","Friday","Saturday"]

    var body: some View {
        NavigationStack {
            Form {
                Section("Details") {
                    TextField("Title", text: $title)
                    TextField("Location (optional)", text: $location)
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
                    Toggle("Recurring", isOn: $isRecurring)
                    if isRecurring {
                        Picker("Week", selection: $scheduleWeek) {
                            ForEach(ScheduleType.allCases, id: \.self) { t in
                                Text(t.rawValue).tag(t)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                }
            }
            .navigationTitle("Add Schedule Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        let displayTitle = title.isEmpty ? subject.name : title
                        let item = ScheduleItem(
                            title: displayTitle,
                            location: location,
                            startTime: startTime,
                            endTime: endTime,
                            itemType: itemType,
                            weekday: weekday,
                            scheduleWeek: scheduleWeek,
                            isRecurring: isRecurring,
                            subject: subject
                        )
                        modelContext.insert(item)
                        do {
                            try modelContext.save()
                            dismiss()
                        } catch {
                            print("Save error: \(error)")
                        }
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}
