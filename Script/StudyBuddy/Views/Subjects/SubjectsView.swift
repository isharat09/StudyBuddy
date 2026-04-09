import SwiftUI
import SwiftData

struct SubjectsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Subject.name) private var subjects: [Subject]

    @State private var showAddSubject = false
    @State private var subjectToEdit: Subject?

    var body: some View {
        NavigationStack {
            Group {
                if subjects.isEmpty {
                    emptyState
                } else {
                    List {
                        ForEach(subjects) { subject in
                            NavigationLink {
                                SubjectDetailView(subject: subject)
                            } label: {
                                SubjectRowView(subject: subject)
                            }
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    withAnimation {
                                        modelContext.delete(subject)
                                        try? modelContext.save()
                                    }
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                                Button {
                                    subjectToEdit = subject
                                } label: {
                                    Label("Edit", systemImage: "pencil")
                                }
                                .tint(AppColors.primary)
                            }
                        }
                    }
                    .animation(.easeInOut, value: subjects.count)
                }
            }
            .navigationTitle("Subjects")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showAddSubject = true
                    } label: {
                        Image(systemName: "plus").fontWeight(.medium)
                    }
                }
            }
            .sheet(isPresented: $showAddSubject) {
                AddSubjectSheet()
            }
            .sheet(item: $subjectToEdit) { subject in
                AddSubjectSheet(editSubject: subject)
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "book.closed")
                .font(.system(size: 56))
                .foregroundStyle(AppColors.primary.opacity(0.4))
            Text("No Subjects Yet")
                .font(.title3)
                .fontWeight(.semibold)
            Text("Add your courses to get started tracking tasks, grades, and study time.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            Button("Add Subject") {
                showAddSubject = true
            }
            .buttonStyle(.borderedProminent)
            .tint(AppColors.primary)
        }
    }
}

struct SubjectRowView: View {
    let subject: Subject

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(subject.color.opacity(0.15))
                    .frame(width: 42, height: 42)
                Image(systemName: subject.icon)
                    .foregroundStyle(subject.color)
                    .font(.system(size: 18))
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(subject.name)
                    .font(.subheadline)
                    .fontWeight(.semibold)

                HStack(spacing: 10) {
                    Label("\(subject.tasks.filter { !$0.isCompleted }.count) tasks", systemImage: "checklist")
                    Label(subject.totalStudyTimeFormatted, systemImage: "clock")
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            Spacer()

            if let avg = subject.averageGrade {
                VStack(alignment: .trailing, spacing: 1) {
                    Text(String(format: "%.0f%%", avg))
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(subject.color)
                    Text("avg")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
}
