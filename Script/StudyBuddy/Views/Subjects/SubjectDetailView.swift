import SwiftUI
import SwiftData

struct SubjectDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var subject: Subject

    @State private var selectedTab = 0
    @State private var showAddGrade = false
    @State private var showAddNote = false
    @State private var showAddScheduleItem = false
    @State private var scheduleItemToEdit: ScheduleItem?
    @State private var gradeToEdit: Grade?

    var body: some View {
        VStack(spacing: 0) {
            subjectHeader

            Picker("", selection: $selectedTab) {
                Text("Grades").tag(0)
                Text("Notes").tag(1)
                Text("Schedule").tag(2)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)

            // Use a List so swipe actions always work on real devices
            Group {
                switch selectedTab {
                case 0: gradesTab
                case 1: notesTab
                case 2: scheduleTab
                default: EmptyView()
                }
            }
            .animation(.easeInOut(duration: 0.2), value: selectedTab)
        }
        .navigationTitle(subject.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    switch selectedTab {
                    case 0: showAddGrade = true
                    case 1: showAddNote = true
                    case 2: showAddScheduleItem = true
                    default: break
                    }
                } label: {
                    Image(systemName: "plus").fontWeight(.medium)
                }
            }
        }
        .sheet(isPresented: $showAddGrade) {
            AddGradeSheet(subject: subject)
        }
        .sheet(item: $gradeToEdit) { grade in
            EditGradeSheet(grade: grade, subject: subject)
        }
        .sheet(isPresented: $showAddNote) {
            AddNoteSheet(subject: subject)
        }
        .sheet(isPresented: $showAddScheduleItem) {
            AddScheduleItemSheet(subject: subject)
        }
        .sheet(item: $scheduleItemToEdit) { item in
            EditScheduleItemSheet(item: item)
        }
    }

    // MARK: - Header

    private var subjectHeader: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(subject.color.opacity(0.2))
                    .frame(width: 56, height: 56)
                Image(systemName: subject.icon)
                    .foregroundStyle(subject.color)
                    .font(.system(size: 24))
            }

            VStack(alignment: .leading, spacing: 4) {
                if let avg = subject.averageGrade {
                    Text("Average: \(String(format: "%.1f%%", avg))")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(subject.color)
                }
                Label(subject.totalStudyTimeFormatted + " studied", systemImage: "clock")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Label("\(subject.tasks.filter { !$0.isCompleted }.count) open tasks",
                      systemImage: "checklist")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(subject.color.opacity(0.07))
    }

    // MARK: - Grades Tab (List for reliable swipe actions)

    private var gradesTab: some View {
        List {
            if subject.grades.isEmpty {
                emptyRow(message: "No grades yet. Tap + to add one.", icon: "doc.text")
            } else {
                ForEach(subject.grades.sorted { $0.date > $1.date }) { grade in
                    gradeRow(grade)
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                withAnimation {
                                    modelContext.delete(grade)
                                    try? modelContext.save()
                                }
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                        .swipeActions(edge: .leading, allowsFullSwipe: false) {
                            Button {
                                gradeToEdit = grade
                            } label: {
                                Label("Edit", systemImage: "pencil")
                            }
                            .tint(subject.color)
                        }
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    private func gradeRow(_ grade: Grade) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text(grade.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text("\(grade.gradeType.rawValue) · \(grade.date.shortDate)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 3) {
                Text(String(format: "%.0f / %.0f", grade.score, grade.maxScore))
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color(hex: grade.gradeColor) ?? .primary)
                Text("\(grade.letterGrade)  ·  \(String(format: "%.0f%%", grade.percentage))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }

    // MARK: - Notes Tab

    private var notesTab: some View {
        List {
            if subject.notes.isEmpty {
                emptyRow(message: "No notes yet. Tap + to add one.", icon: "note.text")
            } else {
                ForEach(subject.notes.sorted { $0.updatedAt > $1.updatedAt }) { note in
                    NavigationLink {
                        NoteEditorView(note: note)
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            if !note.title.isEmpty {
                                Text(note.title)
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                            }
                            if !note.content.isEmpty {
                                Text(note.content)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(2)
                            }
                            Text(note.updatedAt.shortDate)
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }
                        .padding(.vertical, 2)
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            withAnimation {
                                modelContext.delete(note)
                                try? modelContext.save()
                            }
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    // MARK: - Schedule Tab (List for reliable swipe + edit)

    private var scheduleTab: some View {
        List {
            if subject.scheduleItems.isEmpty {
                emptyRow(
                    message: "No classes yet. Tap + to add a class or study block.",
                    icon: "calendar"
                )
            } else {
                let sorted = subject.scheduleItems.sorted { $0.weekday < $1.weekday }
                ForEach(sorted) { item in
                    scheduleRow(item)
                        // Swipe LEFT → Edit (blue)
                        .swipeActions(edge: .leading, allowsFullSwipe: false) {
                            Button {
                                scheduleItemToEdit = item
                            } label: {
                                Label("Edit", systemImage: "pencil")
                            }
                            .tint(.blue)
                        }
                        // Swipe RIGHT → Delete (red)
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                withAnimation {
                                    modelContext.delete(item)
                                    try? modelContext.save()
                                }
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    private func scheduleRow(_ item: ScheduleItem) -> some View {
        HStack(spacing: 12) {
            // Coloured day + time badge
            VStack(spacing: 2) {
                Text(weekdayName(item.weekday))
                    .font(.caption2)
                    .fontWeight(.bold)
                Text(item.startTime.timeFormatted)
                    .font(.caption2)
            }
            .foregroundStyle(.white)
            .frame(width: 52, height: 40)
            .background(subject.color)
            .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 3) {
                Text(item.title)
                    .font(.subheadline)
                    .fontWeight(.medium)

                HStack(spacing: 6) {
                    if !item.location.isEmpty {
                        Label(item.location, systemImage: "mappin")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Label("\(item.durationMinutes) min", systemImage: "clock")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                // Show which weeks this class appears
                Text(weekLabel(item))
                    .font(.caption2)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(subject.color.opacity(0.12))
                    .foregroundStyle(subject.color)
                    .clipShape(Capsule())
            }

            Spacer()

            Text(item.itemType.rawValue)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 6)
    }

    // MARK: - Helpers

    private func weekdayName(_ weekday: Int) -> String {
        ["Sun","Mon","Tue","Wed","Thu","Fri","Sat"][max(0, min(6, weekday - 1))]
    }

    private func weekLabel(_ item: ScheduleItem) -> String {
        switch item.scheduleWeek {
        case .weekly:   return "Every week"
        case .aWeek:    return "A weeks only"
        case .bWeek:    return "B weeks only"
        case .both:     return "Both weeks"
        }
    }

    private func emptyRow(message: String, icon: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(subject.color.opacity(0.5))
                .font(.title3)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 8)
        .listRowBackground(Color.clear)
    }
}
