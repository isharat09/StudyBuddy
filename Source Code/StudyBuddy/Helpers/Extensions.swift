import SwiftUI

// MARK: - App Colors
enum AppColors {
    static let primary = Color(hex: "#534AB7")!
    static let primaryLight = Color(hex: "#EEEDFE")!
    static let primaryMid = Color(hex: "#7F77DD")!

    static let subjectColors: [(hex: String, name: String)] = [
        ("#534AB7", "Purple"),
        ("#D85A30", "Coral"),
        ("#1D9E75", "Teal"),
        ("#BA7517", "Amber"),
        ("#185FA5", "Blue"),
        ("#A32D2D", "Red"),
        ("#3B6D11", "Green"),
        ("#993556", "Pink"),
        ("#5F5E5A", "Gray")
    ]
}

// MARK: - Color Extension
extension Color {
    init?(hex: String) {
        var h = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if h.hasPrefix("#") { h = String(h.dropFirst()) }
        guard h.count == 6, let val = UInt64(h, radix: 16) else { return nil }
        let r = Double((val >> 16) & 0xFF) / 255
        let g = Double((val >> 8) & 0xFF) / 255
        let b = Double(val & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}

// MARK: - Date Extensions
extension Date {
    var startOfDay: Date { Calendar.current.startOfDay(for: self) }

    var isToday: Bool { Calendar.current.isDateInToday(self) }
    var isTomorrow: Bool { Calendar.current.isDateInTomorrow(self) }
    var isYesterday: Bool { Calendar.current.isDateInYesterday(self) }

    var friendlyDueDate: String {
        if isToday { return "Today" }
        if isTomorrow { return "Tomorrow" }
        if isYesterday { return "Yesterday" }
        let fmt = DateFormatter()
        let days = Calendar.current.dateComponents([.day], from: Date().startOfDay, to: startOfDay).day ?? 0
        if days > 0 && days < 7 {
            fmt.dateFormat = "EEEE"
            return fmt.string(from: self)
        }
        fmt.dateFormat = "MMM d"
        return fmt.string(from: self)
    }

    var timeFormatted: String {
        let fmt = DateFormatter()
        fmt.dateFormat = "h:mm a"
        return fmt.string(from: self)
    }

    var shortDate: String {
        let fmt = DateFormatter()
        fmt.dateFormat = "MMM d"
        return fmt.string(from: self)
    }
}

extension Calendar {
    func startOfWeek(for date: Date) -> Date {
        let components = dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        return self.date(from: components) ?? date
    }

    var currentWeekParity: WeekParity {
        let week = component(.weekOfYear, from: Date())
        return week % 2 == 0 ? .aWeek : .bWeek
    }
}

enum WeekParity { case aWeek, bWeek }

// MARK: - View Extensions
extension View {
    func cardStyle() -> some View {
        self
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(.separator).opacity(0.4), lineWidth: 0.5))
    }

    func sectionCard() -> some View {
        self
            .padding(12)
            .cardStyle()
    }
}

// MARK: - Haptics
import UIKit
enum HapticManager {
    static func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }

    static func notification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        UINotificationFeedbackGenerator().notificationOccurred(type)
    }
}

// MARK: - Subject Color Swatch
struct ColorSwatch: View {
    let hex: String
    let isSelected: Bool
    var body: some View {
        Circle()
            .fill(Color(hex: hex) ?? .purple)
            .frame(width: 28, height: 28)
            .overlay(
                Circle().stroke(Color.white, lineWidth: isSelected ? 3 : 0)
            )
            .shadow(color: .black.opacity(isSelected ? 0.2 : 0), radius: 2)
    }
}

// MARK: - Animated Number
struct AnimatedNumber: View {
    let value: Int
    let font: Font

    @State private var displayValue: Int = 0

    var body: some View {
        Text("\(displayValue)")
            .font(font)
            .contentTransition(.numericText())
            .onAppear {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    displayValue = value
                }
            }
            .onChange(of: value) { _, newVal in
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                    displayValue = newVal
                }
            }
    }
}

// MARK: - Bounce Button Style
struct BounceButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.93 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

// MARK: - Slide-in modifier
struct SlideInModifier: ViewModifier {
    let delay: Double
    @State private var appeared = false

    func body(content: Content) -> some View {
        content
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 20)
            .onAppear {
                withAnimation(.easeOut(duration: 0.35).delay(delay)) {
                    appeared = true
                }
            }
    }
}

extension View {
    func slideIn(delay: Double = 0) -> some View {
        modifier(SlideInModifier(delay: delay))
    }
}
