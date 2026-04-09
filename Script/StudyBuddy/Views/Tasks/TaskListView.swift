import SwiftUI
import SwiftData

struct TaskListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Task.dueDate) private var allTasks: [Task]
    @Query(sort: \Subject.name) private var subjects: [Subject]

    @State private var selectedSubject: Subject?
    @State private var showAddTask = false
    @State private var taskToEdit: Task?
    @State private var showCompleted = false
    @State private var searchText = ""

    private var filteredTasks: [Task] {
        allTasks.filter { task in
            let subjectMatch = selectedSubject == nil ||
                task.subject?.persistentModelID == selectedSubject?.persistentModelID
            let completedMatch = showCompleted ? task.isCompleted : !task.isCompleted
            let searchMatch = searchText.isEmpty ||
                task.title.localizedCaseInsensitiveContains(searchText)
            return subjectMatch && completedMatch && searchMatch
        }
    }

    private var overdue: [Task]   { filteredTasks.filter { $0.isOverdue } }
    private var dueToday: [Task]  { filteredTasks.filter { $0.isDueToday && !$0.isCompleted } }
    private var thisWeek: [Task]  { filteredTasks.filter { $0.isDueThisWeek && !$0.isDueToday && !$0.isOverdue } }
    private var later: [Task]     { filteredTasks.filter { !$0.isDueToday && !$0.isDueThisWeek && !$0.isOverdue && !$0.isCompleted } }
    private var completed: [Task] { filteredTasks.filter { $0.isCompleted } }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                subjectFilterBar

                List {
                    if !overdue.isEmpty {
                        taskSection(title: "Overdue", tasks: overdue,
                                    icon: "exclamationmark.circle.fill", color: .red)
                    }
                    if !dueToday.isEmpty {
                        taskSection(title: "Today", tasks: dueToday,
                                    icon: "sun.max.fill", color: .orange)
                    }
                    if !thisWeek.isEmpty {
                        taskSection(title: "This Week", tasks: thisWeek,
                                    icon: "calendar", color: AppColors.primary)
                    }
                    if !later.isEmpty {
                        taskSection(title: "Later", tasks: later,
                                    icon: "clock", color: .secondary)
                    }
                    if showCompleted && !completed.isEmpty {
                        taskSection(title: "Completed", tasks: completed,
                                    icon: "checkmark.circle.fill", color: .green)
                    }
                    if filteredTasks.filter({ !$0.isCompleted }).isEmpty {
                        emptyState
                    }
                }
                .listStyle(.insetGrouped)
                .searchable(text: $searchText, prompt: "Search tasks")
                .animation(.easeInOut, value: allTasks.count)
            }
            .navigationTitle("Tasks")
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Button {
                        withAnimation { showCompleted.toggle() }
                    } label: {
                        Image(systemName: showCompleted ? "eye.slash" : "eye")
                    }
                    Button {
                        showAddTask = true
                    } label: {
                        Image(systemName: "plus").fontWeight(.medium)
                    }
                }
            }
            .sheet(isPresented: $showAddTask) {
                AddTaskSheet()
            }
            .sheet(item: $taskToEdit) { task in
                AddTaskSheet(editTask: task)
            }
        }
    }

    private var subjectFilterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                filterChip(label: "All", subject: nil)
                ForEach(subjects) { s in filterChip(label: s.name, subject: s) }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
        .background(Color(.systemGroupedBackground))
    }

    private func filterChip(label: String, subject: Subject?) -> some View {
        let isSelected = selectedSubject?.persistentModelID == subject?.persistentModelID
                         && (subject != nil || selectedSubject == nil)
        return Button {
            withAnimation(.easeInOut(duration: 0.2)) { selectedSubject = subject }
        } label: {
            HStack(spacing: 5) {
                if let s = subject {
                    Circle().fill(s.color).frame(width: 7, height: 7)
                }
                Text(label)
                    .font(.subheadline)
                    .fontWeight(isSelected ? .semibold : .regular)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(isSelected ? AppColors.primary : Color(.systemBackground))
            .foregroundStyle(isSelected ? .white : .primary)
            .clipShape(Capsule())
            .overlay(Capsule().stroke(Color(.separator).opacity(0.4),
                                      lineWidth: isSelected ? 0 : 0.5))
        }
        .buttonStyle(.plain)
    }

    private func taskSection(title: String, tasks: [Task], icon: String, color: Color) -> some View {
        Section {
            ForEach(tasks) { task in
                TaskRowView(task: task)
                    .listRowInsets(EdgeInsets())
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            withAnimation {
                                modelContext.delete(task)
                                try? modelContext.save()
                            }
                        } label: { Label("Delete", systemImage: "trash") }

                        Button { taskToEdit = task } label: {
                            Label("Edit", systemImage: "pencil")
                        }
                        .tint(AppColors.primary)
                    }
                    .swipeActions(edge: .leading) {
                        Button {
                            withAnimation {
                                task.isCompleted.toggle()
                                task.completedAt = task.isCompleted ? Date() : nil
                                try? modelContext.save()
                            }
                        } label: {
                            Label(task.isCompleted ? "Undo" : "Done",
                                  systemImage: task.isCompleted ? "arrow.uturn.backward" : "checkmark")
                        }
                        .tint(.green)
                    }
            }
        } header: {
            Label(title, systemImage: icon)
                .foregroundStyle(color)
                .font(.subheadline)
                .fontWeight(.semibold)
        }
    }

    private var emptyState: some View {
        Section {
            VStack(spacing: 12) {
                Image(systemName: "checkmark.circle")
                    .font(.system(size: 44))
                    .foregroundStyle(AppColors.primary.opacity(0.4))
                Text("All caught up!")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                Text("Tap + to add a new task")
                    .font(.subheadline)
                    .foregroundStyle(.tertiary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 32)
        }
        .listRowBackground(Color.clear)
    }
}
