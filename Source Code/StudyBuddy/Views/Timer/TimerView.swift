import SwiftUI
import SwiftData

struct TimerView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Subject.name) private var subjects: [Subject]
    @Query(sort: \StudySession.startTime, order: .reverse) private var sessions: [StudySession]

    @State private var vm = TimerViewModel()
    @State private var showSettings = false
    @State private var showSubjectPicker = false

    private var todaySessions: [StudySession] {
        sessions.filter { Calendar.current.isDateInToday($0.startTime) }
    }

    private var todayTotal: String {
        let total = todaySessions.reduce(0.0) { $0 + $1.durationSeconds }
        let h = Int(total) / 3600
        let m = (Int(total) % 3600) / 60
        if h > 0 { return "\(h)h \(m)m" }
        return "\(m)m"
    }

    private var weekTotal: String {
        let start = Calendar.current.startOfWeek(for: Date())
        let total = sessions.filter { $0.startTime >= start }.reduce(0.0) { $0 + $1.durationSeconds }
        let h = Int(total) / 3600
        let m = (Int(total) % 3600) / 60
        if h > 0 { return "\(h)h \(m)m" }
        return "\(m)m"
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    modeToggle
                    timerRing
                    subjectCard
                    controlButtons
                    statsStrip
                    todaySessionsList
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 24)
            }
            .navigationTitle("Focus Timer")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                    }
                }
            }
            .sheet(isPresented: $showSettings) {
                TimerSettingsSheet(vm: vm)
            }
            .sheet(isPresented: $showSubjectPicker) {
                SubjectPickerSheet(subjects: subjects, selected: $vm.selectedSubject)
            }
            .onAppear {
                vm.setContext(modelContext)
            }
        }
    }

    // MARK: - Subviews

    private var modeToggle: some View {
        HStack(spacing: 8) {
            Button {
                vm.usePomodoro = true
                vm.applySettings()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "timer")
                    Text("Pomodoro")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(vm.usePomodoro ? AppColors.primary : Color(.systemBackground))
                .foregroundStyle(vm.usePomodoro ? .white : .primary)
                .clipShape(Capsule())
                .overlay(Capsule().stroke(Color(.separator).opacity(0.4), lineWidth: vm.usePomodoro ? 0 : 0.5))
            }
            .buttonStyle(.plain)

            Button {
                vm.usePomodoro = false
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "stopwatch")
                    Text("Free Study")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(!vm.usePomodoro ? AppColors.primary : Color(.systemBackground))
                .foregroundStyle(!vm.usePomodoro ? .white : .primary)
                .clipShape(Capsule())
                .overlay(Capsule().stroke(Color(.separator).opacity(0.4), lineWidth: !vm.usePomodoro ? 0 : 0.5))
            }
            .buttonStyle(.plain)
        }
    }

    private var timerRing: some View {
        ZStack {
            Circle()
                .stroke(AppColors.primaryLight, lineWidth: 14)
                .frame(width: 220, height: 220)

            Circle()
                .trim(from: 0, to: vm.usePomodoro ? vm.progress : 1)
                .stroke(phaseColor, style: StrokeStyle(lineWidth: 14, lineCap: .round))
                .frame(width: 220, height: 220)
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 1), value: vm.progress)

            VStack(spacing: 6) {
                if vm.usePomodoro {
                    Text(vm.timeString)
                        .font(.system(size: 52, weight: .semibold, design: .rounded))
                        .monospacedDigit()
                } else {
                    Text(vm.elapsedString)
                        .font(.system(size: 52, weight: .semibold, design: .rounded))
                        .monospacedDigit()
                }

                Text(vm.phaseName)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                if vm.usePomodoro && vm.isRunning {
                    Text(vm.sessionLabel)
                        .font(.caption)
                        .foregroundStyle(AppColors.primary)
                }
            }
        }
        .padding(.vertical, 8)
    }

    private var phaseColor: Color {
        switch vm.currentPhase {
        case .focus: return AppColors.primary
        case .shortBreak: return Color(hex: "#1D9E75")!
        case .longBreak: return Color(hex: "#BA7517")!
        }
    }

    private var subjectCard: some View {
        Button {
            showSubjectPicker = true
        } label: {
            HStack(spacing: 12) {
                Circle()
                    .fill(vm.selectedSubject?.color ?? Color(.systemGray4))
                    .frame(width: 12, height: 12)

                VStack(alignment: .leading, spacing: 2) {
                    Text(vm.selectedSubject?.name ?? "No Subject")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.primary)
                    Text("Tap to change")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(12)
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(.separator).opacity(0.4), lineWidth: 0.5))
        }
        .buttonStyle(.plain)
    }

    private var controlButtons: some View {
        HStack(spacing: 16) {
            if vm.isRunning || vm.isPaused {
                // Skip (Pomodoro only)
                if vm.usePomodoro {
                    Button {
                        vm.skip()
                        HapticManager.impact(.medium)
                    } label: {
                        Label("Skip", systemImage: "forward.end")
                            .font(.subheadline)
                    }
                    .buttonStyle(.bordered)
                    .tint(.secondary)
                }

                // Pause / Resume
                Button {
                    if vm.isRunning { vm.pause() } else { vm.resume() }
                    HapticManager.impact(.medium)
                } label: {
                    Label(vm.isRunning ? "Pause" : "Resume",
                          systemImage: vm.isRunning ? "pause.fill" : "play.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(AppColors.primary)

                // Stop
                Button {
                    vm.stop()
                    HapticManager.impact(.medium)
                } label: {
                    Label("Stop", systemImage: "stop.fill")
                        .font(.subheadline)
                }
                .buttonStyle(.bordered)
                .tint(.red)

            } else {
                // Start
                Button {
                    vm.start()
                    HapticManager.notification(.success)
                } label: {
                    Label("Start Session", systemImage: "play.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(AppColors.primary)
                .controlSize(.large)
            }
        }
    }

    private var statsStrip: some View {
        HStack {
            statCell(value: todayTotal, label: "Today")
            Divider().frame(height: 30)
            statCell(value: weekTotal, label: "This week")
            Divider().frame(height: 30)
            statCell(value: "\(StatsViewModel().currentStreak(sessions: sessions))", label: "Day streak")
        }
        .padding(14)
        .background(AppColors.primaryLight)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func statCell(value: String, label: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundStyle(AppColors.primary)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    private var todaySessionsList: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Today's Sessions")
                    .font(.headline)
                Spacer()
                Text("\(todaySessions.count) session\(todaySessions.count == 1 ? "" : "s")")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if todaySessions.isEmpty {
                Text("No sessions yet today. Start one above!")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(todaySessions.prefix(5).enumerated()), id: \.element.persistentModelID) { index, session in
                        sessionRow(session)
                        if index < min(todaySessions.count, 5) - 1 {
                            Divider().padding(.leading, 44)
                        }
                    }
                }
                .sectionCard()
            }
        }
    }

    private func sessionRow(_ session: StudySession) -> some View {
        HStack(spacing: 12) {
            Circle()
                .fill(session.subject?.color ?? Color(.systemGray4))
                .frame(width: 10, height: 10)
                .padding(.leading, 4)

            VStack(alignment: .leading, spacing: 2) {
                Text(session.subject?.name ?? "Untagged")
                    .font(.subheadline)
                    .fontWeight(.medium)
                if session.isPomodoro {
                    Text(session.pomodoroPhase.rawValue)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(session.durationShort)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(session.startTime.timeFormatted)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
    }
}

// MARK: - Subject Picker Sheet
struct SubjectPickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    let subjects: [Subject]
    @Binding var selected: Subject?

    var body: some View {
        NavigationStack {
            List {
                Button {
                    selected = nil
                    dismiss()
                } label: {
                    HStack {
                        Circle().fill(Color(.systemGray4)).frame(width: 12, height: 12)
                        Text("No Subject")
                        Spacer()
                        if selected == nil {
                            Image(systemName: "checkmark").foregroundStyle(AppColors.primary)
                        }
                    }
                }
                .tint(.primary)

                ForEach(subjects) { s in
                    Button {
                        selected = s
                        dismiss()
                    } label: {
                        HStack {
                            Circle().fill(s.color).frame(width: 12, height: 12)
                            Text(s.name)
                            Spacer()
                            if selected?.persistentModelID == s.persistentModelID {
                                Image(systemName: "checkmark").foregroundStyle(AppColors.primary)
                            }
                        }
                    }
                    .tint(.primary)
                }
            }
            .navigationTitle("Select Subject")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Timer Settings Sheet
struct TimerSettingsSheet: View {
    @Environment(\.dismiss) private var dismiss
    let vm: TimerViewModel

    @State private var focus: Int = 25
    @State private var shortBreak: Int = 5
    @State private var longBreak: Int = 15
    @State private var sessionsUntilLong: Int = 4

    var body: some View {
        NavigationStack {
            Form {
                Section("Focus Duration") {
                    Stepper("\(focus) minutes", value: $focus, in: 1...90)
                }
                Section("Break Durations") {
                    Stepper("Short break: \(shortBreak) min", value: $shortBreak, in: 1...30)
                    Stepper("Long break: \(longBreak) min", value: $longBreak, in: 5...60)
                }
                Section("Long Break Interval") {
                    Stepper("Every \(sessionsUntilLong) sessions", value: $sessionsUntilLong, in: 2...8)
                }
            }
            .navigationTitle("Timer Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        vm.focusMinutes = focus
                        vm.shortBreakMinutes = shortBreak
                        vm.longBreakMinutes = longBreak
                        vm.sessionsUntilLongBreak = sessionsUntilLong
                        vm.applySettings()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
            .onAppear {
                focus = vm.focusMinutes
                shortBreak = vm.shortBreakMinutes
                longBreak = vm.longBreakMinutes
                sessionsUntilLong = vm.sessionsUntilLongBreak
            }
        }
    }
}
