import SwiftUI
import SwiftData

struct SubjectDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var subject: Subject

    @State private var selectedTab = 0
    @State private var showAddGrade = false
    @State private var showAddNote = false
    @State private var showAddScheduleItem = false

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
            .animation(.easeInOut(duration: 0.2), value: selectedTab)

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    switch selectedTab {
                    case 0: gradesTab
                    case 1: notesTab
                    case 2: scheduleTab
                    default: EmptyView()
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 24)
            }
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
        .sheet(isPresented: $showAddNote) {
            AddNoteSheet(subject: subject)
        }
        .sheet(isPresented: $showAddScheduleItem) {
            AddScheduleItemSheet(subject: subject)
        }
    }

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
                Label("\(subject.tasks.filter { !$0.isCompleted }.count) open tasks", systemImage: "checklist")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(subject.color.opacity(0.07))
    }

    // MARK: - Grades Tab

    private var gradesTab: some View {
        VStack(alignment: .leading, spacing: 10) {
            if subject.grades.isEmpty {
                emptySection(message: "No grades yet. Tap + to add one.", icon: "doc.text")
            } else {
                VStack(spacing: 0) {
                    let sorted = subject.grades.sorted { $0.date > $1.date }
                    ForEach(Array(sorted.enumerated()), id: \.element.persistentModelID) { index, grade in
                        gradeRow(grade)
                        if index < sorted.count - 1 {
                            Divider().padding(.leading, 16)
                        }
                    }
                }
                .sectionCard()
                .transition(.opacity.combined(with: .move(edge: .top)))
                .animation(.easeInOut, value: subject.grades.count)
            }
        }
    }

    private func gradeRow(_ grade: Grade) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(grade.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text("\(grade.gradeType.rawValue) · \(grade.date.shortDate)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(String(format: "%.0f / %.0f", grade.score, grade.maxScore))
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color(hex: grade.gradeColor) ?? .primary)
                Text(grade.letterGrade)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 14)
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) {
                modelContext.delete(grade)
                try? modelContext.save()
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }

    // MARK: - Notes Tab

    private var notesTab: some View {
        VStack(alignment: .leading, spacing: 10) {
            if subject.notes.isEmpty {
                emptySection(message: "No notes yet. Tap + to add one.", icon: "note.text")
            } else {
                ForEach(subject.notes.sorted { $0.updatedAt > $1.updatedAt }) { note in
                    NavigationLink {
                        NoteEditorView(note: note)
                    } label: {
                        noteCard(note)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .animation(.easeInOut, value: subject.notes.count)
    }

    private func noteCard(_ note: Note) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            if !note.title.isEmpty {
                Text(note.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
            }
            if !note.content.isEmpty {
                Text(note.content)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
            }
            Text(note.updatedAt.shortDate)
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .sectionCard()
    }

    // MARK: - Schedule Tab

    private var scheduleTab: some View {
        VStack(alignment: .leading, spacing: 10) {
            if subject.scheduleItems.isEmpty {
                emptySection(message: "No schedule items yet. Tap + to add a class or study block.", icon: "calendar")
            } else {
                VStack(spacing: 0) {
                    let sorted = subject.scheduleItems.sorted { $0.weekday < $1.weekday }
                    ForEach(Array(sorted.enumerated()), id: \.element.persistentModelID) { index, item in
                        scheduleRow(item)
                        if index < sorted.count - 1 {
                            Divider().padding(.leading, 16)
                        }
                    }
                }
                .sectionCard()
                .animation(.easeInOut, value: subject.scheduleItems.count)
            }
        }
    }

    private func scheduleRow(_ item: ScheduleItem) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(item.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(weekdayName(item.weekday) + " · " + item.timeRangeFormatted)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if !item.location.isEmpty {
                    Text(item.location)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }

            Spacer()

            Text(item.itemType.rawValue)
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(subject.color.opacity(0.12))
                .foregroundStyle(subject.color)
                .clipShape(Capsule())
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 14)
        .swipeActions {
            Button(role: .destructive) {
                modelContext.delete(item)
                try? modelContext.save()
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }

    private func weekdayName(_ weekday: Int) -> String {
        let days = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
        guard weekday >= 1 && weekday <= 7 else { return "" }
        return days[weekday - 1]
    }

    private func emptySection(message: String, icon: String) -> some View {
        VStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 32))
                .foregroundStyle(subject.color.opacity(0.4))
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(.separator).opacity(0.3), lineWidth: 0.5))
    }
}
