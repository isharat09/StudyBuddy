import SwiftUI
import SwiftData

struct StatsView: View {
    @Query(sort: \StudySession.startTime, order: .reverse) private var sessions: [StudySession]
    @Query(sort: \Task.dueDate) private var tasks: [Task]
    @Query(sort: \Subject.name) private var subjects: [Subject]

    @State private var statsVM = StatsViewModel()
    @State private var selectedPeriod: StatsPeriod = .week

    private var streak: Int { statsVM.currentStreak(sessions: sessions) }
    private var longestStreak: Int { statsVM.longestStreak(sessions: sessions) }
    private var weeklyHrs: Double { statsVM.weeklyHours(sessions: sessions) }
    private var dayData: [DayStudyData] { statsVM.dailyStudyData(sessions: sessions) }
    private var subjectData: [SubjectStudyData] { statsVM.subjectBreakdown(sessions: sessions) }
    private var peakHour: String { statsVM.peakHour(sessions: sessions) ?? "—" }
    private var tasksThisWeek: Int { statsVM.tasksCompletedThisWeek(tasks: tasks) }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    metricGrid.slideIn(delay: 0.05)
                    dailyBarChart.slideIn(delay: 0.15)
                    subjectBreakdownSection.slideIn(delay: 0.25)
                    gradesSection.slideIn(delay: 0.35)
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 24)
            }
            .navigationTitle("Stats")
        }
    }

    // MARK: - Metric Grid

    private var metricGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
            metricCard(value: "\(streak)", unit: streak == 1 ? "day" : "days", label: "Current streak", icon: "flame.fill", iconColor: .orange)
            metricCard(value: String(format: "%.1f", weeklyHrs), unit: "hours", label: "This week", icon: "clock.fill", iconColor: AppColors.primary)
            metricCard(value: "\(tasksThisWeek)", unit: "", label: "Tasks done this week", icon: "checkmark.circle.fill", iconColor: .green)
            metricCard(value: peakHour, unit: "", label: "Peak focus time", icon: "brain.head.profile", iconColor: Color(hex: "#1D9E75")!)
        }
    }

    private func metricCard(value: String, unit: String, label: String, icon: String, iconColor: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(iconColor)
                    .font(.subheadline)
                Spacer()
            }
            HStack(alignment: .lastTextBaseline, spacing: 3) {
                Text(value)
                    .font(.title2)
                    .fontWeight(.semibold)
                if !unit.isEmpty {
                    Text(unit)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2)
        }
        .padding(12)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(.separator).opacity(0.3), lineWidth: 0.5))
    }

    // MARK: - Daily Bar Chart

    private var dailyBarChart: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Daily Study — Last 7 Days")
                .font(.headline)

            let maxHours = max(dayData.map(\.hours).max() ?? 1, 0.01)

            VStack(spacing: 6) {
                HStack(alignment: .bottom, spacing: 6) {
                    ForEach(dayData) { day in
                        VStack(spacing: 4) {
                            if day.hours > 0 {
                                Text(String(format: "%.0fh", day.hours))
                                    .font(.system(size: 8))
                                    .foregroundStyle(.secondary)
                            }
                            GeometryReader { geo in
                                VStack {
                                    Spacer()
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(day.isToday ? AppColors.primary : AppColors.primaryMid.opacity(0.5))
                                        .frame(height: max(geo.size.height * CGFloat(day.hours / maxHours), 4))
                                }
                            }
                            Text(day.dayLabel)
                                .font(.caption2)
                                .foregroundStyle(day.isToday ? AppColors.primary : .secondary)
                                .fontWeight(day.isToday ? .semibold : .regular)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .frame(height: 80)
            }
            .padding(14)
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(.separator).opacity(0.3), lineWidth: 0.5))
        }
    }

    // MARK: - Subject Breakdown

    private var subjectBreakdownSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("By Subject — This Week")
                .font(.headline)

            if subjectData.isEmpty {
                emptyChart(message: "No study sessions this week")
            } else {
                VStack(spacing: 10) {
                    ForEach(subjectData) { data in
                        HStack(spacing: 10) {
                            Circle()
                                .fill(data.color)
                                .frame(width: 10, height: 10)

                            Text(data.name)
                                .font(.subheadline)
                                .frame(width: 80, alignment: .leading)

                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(Color(.systemGray5))
                                        .frame(height: 8)
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(data.color)
                                        .frame(width: geo.size.width * CGFloat(data.percentage), height: 8)
                                }
                            }
                            .frame(height: 8)

                            Text(data.hoursFormatted)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .frame(width: 38, alignment: .trailing)
                        }
                    }
                }
                .padding(14)
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(.separator).opacity(0.3), lineWidth: 0.5))
            }
        }
    }

    // MARK: - Grades

    private var gradesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Grades")
                .font(.headline)

            let subjectsWithGrades = subjects.filter { !$0.grades.isEmpty }

            if subjectsWithGrades.isEmpty {
                emptyChart(message: "Add grades in the Subjects tab")
            } else {
                VStack(spacing: 10) {
                    ForEach(subjectsWithGrades) { subject in
                        if let avg = subject.averageGrade {
                            HStack(spacing: 10) {
                                Circle()
                                    .fill(subject.color)
                                    .frame(width: 10, height: 10)

                                Text(subject.name)
                                    .font(.subheadline)
                                    .frame(width: 80, alignment: .leading)

                                GeometryReader { geo in
                                    ZStack(alignment: .leading) {
                                        RoundedRectangle(cornerRadius: 4)
                                            .fill(Color(.systemGray5))
                                            .frame(height: 8)
                                        RoundedRectangle(cornerRadius: 4)
                                            .fill(subject.color)
                                            .frame(width: geo.size.width * CGFloat(avg / 100), height: 8)
                                    }
                                }
                                .frame(height: 8)

                                Text(String(format: "%.0f%%", avg))
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(Color(hex: subject.grades.last?.gradeColor ?? "#534AB7") ?? AppColors.primary)
                                    .frame(width: 38, alignment: .trailing)
                            }
                        }
                    }
                }
                .padding(14)
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(.separator).opacity(0.3), lineWidth: 0.5))
            }
        }
    }

    private func emptyChart(message: String) -> some View {
        Text(message)
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.vertical, 24)
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(.separator).opacity(0.3), lineWidth: 0.5))
    }
}

enum StatsPeriod: String, CaseIterable {
    case week = "Week"
    case month = "Month"
    case all = "All Time"
}
