import SwiftUI
import UIKit

// MARK: - Цвета

extension Color {
    init(hex: UInt32) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255.0,
            green: Double((hex >> 8) & 0xFF) / 255.0,
            blue: Double(hex & 0xFF) / 255.0,
            opacity: 1.0
        )
    }
}

enum Theme {
    static let bg = Color(hex: 0x0A0810)
    static let bgSoft = Color(hex: 0x120E1C)
    static let panel = Color(hex: 0x171223)
    static let panelTop = Color(hex: 0x191325)
    static let panelDeep = Color(hex: 0x130F1F)
    static let sheet = Color(hex: 0x141020)

    static let gold = Color(hex: 0xE8C987)
    static let goldLight = Color(hex: 0xFBF0CF)
    static let goldDeep = Color(hex: 0xA9853F)

    static let text = Color(hex: 0xEFE9F7)
    static let muted = Color(hex: 0x9C93B3)

    static let green = Color(hex: 0x7FD8A6)
    static let violet = Color(hex: 0x9A7BF0)
    static let red = Color(hex: 0xE8786E)

    static let line = Color(hex: 0xE8C987).opacity(0.16)
    static let lineStrong = Color(hex: 0xE8C987).opacity(0.42)

    @ViewBuilder
    static var background: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: 0x171128), bg],
                startPoint: .top,
                endPoint: .bottom
            )

            Circle()
                .fill(
                    RadialGradient(
                        colors: [Theme.violet.opacity(0.32), Theme.violet.opacity(0)],
                        center: .center,
                        startRadius: 2,
                        endRadius: 230
                    )
                )
                .frame(width: 460, height: 460)
                .offset(y: -330)
                .blur(radius: 30)
                .frame(width: 0, height: 0)

            Circle()
                .fill(
                    RadialGradient(
                        colors: [Theme.gold.opacity(0.10), Theme.gold.opacity(0)],
                        center: .center,
                        startRadius: 2,
                        endRadius: 240
                    )
                )
                .frame(width: 460, height: 460)
                .offset(x: 160, y: 420)
                .blur(radius: 40)
                .frame(width: 0, height: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ignoresSafeArea()
    }
}

// MARK: - Шрифты

extension Font {
    static func display(_ size: CGFloat, weight: Font.Weight = .semibold) -> Font {
        .system(size: size, weight: weight, design: .serif)
    }
}

// MARK: - Форматирование

private let numberFormatter: NumberFormatter = {
    let f = NumberFormatter()
    f.numberStyle = .decimal
    f.groupingSeparator = " "
    f.maximumFractionDigits = 0
    return f
}()

func fmt(_ value: Int) -> String {
    numberFormatter.string(from: NSNumber(value: value)) ?? "\(value)"
}

// MARK: - Тактильная отдача

enum Haptics {
    static func tap() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.prepare()
        generator.impactOccurred()
    }

    static func success() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
}

// MARK: - Стиль карточки

struct CardStyle: ViewModifier {
    var isMain: Bool = false
    var isDone: Bool = false

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: isDone
                                ? [Color(hex: 0x16201D), Color(hex: 0x11161A)]
                                : [Theme.panelTop, Theme.panelDeep],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(
                        isDone ? Theme.green.opacity(0.32)
                            : (isMain ? Theme.gold.opacity(0.34) : Theme.line),
                        lineWidth: 1
                    )
            )
            .shadow(color: Color.black.opacity(0.35), radius: 12, x: 0, y: 10)
    }
}

extension View {
    func cardStyle(isMain: Bool = false, isDone: Bool = false) -> some View {
        modifier(CardStyle(isMain: isMain, isDone: isDone))
    }

    func goldText(_ size: CGFloat) -> some View {
        self.font(.display(size)).foregroundStyle(Theme.goldLight)
    }
}

// MARK: - Полоска прогресса

struct ProgressTrack: View {
    var value: Double
    var height: CGFloat = 6
    var isDone: Bool = false

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color(hex: 0x0B0812))
                    .overlay(Capsule().strokeBorder(Color.white.opacity(0.04), lineWidth: 1))

                Capsule()
                    .fill(
                        LinearGradient(
                            colors: isDone
                                ? [Color(hex: 0x3F9C74), Theme.green]
                                : [Color(hex: 0x6F4FD8), Color(hex: 0xB48CF5), Theme.gold],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: CGFloat(max(0, min(1, value))) * max(0, geo.size.width - 2))
                    .padding(1)
                    .animation(.spring(response: 0.45, dampingFraction: 0.85), value: value)
            }
        }
        .frame(height: height)
    }
}

// MARK: - Чипы-кнопки

enum ChipStyle {
    case gold, ghost, violet
}

struct Chip: View {
    let title: String
    var style: ChipStyle = .gold
    var minWidth: CGFloat = 34
    let action: () -> Void

    private var background: Color {
        switch style {
        case .gold: return Theme.gold.opacity(0.10)
        case .ghost: return Color.white.opacity(0.035)
        case .violet: return Theme.violet.opacity(0.16)
        }
    }

    private var border: Color {
        switch style {
        case .gold: return Theme.gold.opacity(0.30)
        case .ghost: return Color.white.opacity(0.11)
        case .violet: return Theme.violet.opacity(0.42)
        }
    }

    private var foreground: Color {
        switch style {
        case .gold: return Theme.gold
        case .ghost: return Theme.muted
        case .violet: return Theme.goldLight
        }
    }

    var body: some View {
        Button {
            Haptics.tap()
            action()
        } label: {
            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(foreground)
                .lineLimit(1)
                .frame(minWidth: minWidth, minHeight: 32)
                .padding(.horizontal, 10)
                .background(RoundedRectangle(cornerRadius: 9, style: .continuous).fill(background))
                .overlay(
                    RoundedRectangle(cornerRadius: 9, style: .continuous)
                        .strokeBorder(border, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}
