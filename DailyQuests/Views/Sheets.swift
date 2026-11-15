import SwiftUI
import UIKit

// MARK: - Настройки

struct SettingsSheet: View {
    @EnvironmentObject private var game: GameState
    @Environment(\.dismiss) private var dismiss

    @State private var deniedNotifications = false
    @State private var confirmReset = false

    private var reminderBinding: Binding<Bool> {
        Binding(
            get: { game.reminderEnabled },
            set: { enabled in
                guard enabled else {
                    game.reminderEnabled = false
                    return
                }
                Reminder.requestPermission { granted in
                    if granted {
                        game.reminderEnabled = true
                        game.updateReminder()
                    } else {
                        game.reminderEnabled = false
                        deniedNotifications = true
                    }
                }
            }
        )
    }

    private var timeBinding: Binding<Date> {
        Binding(
            get: {
                var components = DateComponents()
                components.hour = game.reminderHour
                components.minute = game.reminderMinute
                return Calendar.current.date(from: components) ?? Date()
            },
            set: { value in
                let components = Calendar.current.dateComponents([.hour, .minute], from: value)
                game.reminderHour = components.hour ?? 20
                game.reminderMinute = components.minute ?? 0
            }
        )
    }

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    header
                    difficultyPanel
                    reminderPanel
                    stepPanel
                    resetPanel
                    footer
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 28)
            }
            .scrollIndicators(.hidden)
        }
        .presentationDragIndicator(.visible)
        .alert("Уведомления запрещены", isPresented: $deniedNotifications) {
            Button("Понятно", role: .cancel) {}
            Button("Открыть настройки") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
        } message: {
            Text("Разреши уведомления для «Квестов» в настройках iPhone, чтобы получать напоминания.")
        }
        .alert("Начать заново?", isPresented: $confirmReset) {
            Button("Удалить всё", role: .destructive) {
                game.resetAll()
                dismiss()
            }
            Button("Отмена", role: .cancel) {}
        } message: {
            Text("Весь прогресс, XP, стрик и достижения будут удалены.")
        }
    }

    private var header: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 5) {
                Text("НАСТРОЙКИ")
                    .font(.system(size: 9.5, weight: .semibold))
                    .tracking(2.4)
                    .foregroundStyle(Theme.goldDeep)

                Text("Путь героя")
                    .font(.display(23))
                    .foregroundStyle(Theme.goldLight)
            }

            Spacer()

            Button {
                Haptics.tap()
                dismiss()
            } label: {
                Text("Готово")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Theme.goldLight)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(Theme.gold.opacity(0.12))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .strokeBorder(Theme.gold.opacity(0.32), lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)
        }
        .padding(.top, 22)
        .padding(.bottom, 16)
    }

    // MARK: Сложность

    private var difficultyPanel: some View {
        panel(title: "СЛОЖНОСТЬ", icon: "⚔️") {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 6) {
                    ForEach(Preset.allCases) { preset in
                        Button {
                            Haptics.tap()
                            game.preset = preset
                        } label: {
                            VStack(spacing: 3) {
                                Text(preset.title)
                                    .font(.system(size: 12.5, weight: .semibold))
                                Text(presetHint(preset))
                                    .font(.system(size: 9))
                                    .opacity(0.75)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 9)
                            .background(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .fill(game.preset == preset ? Theme.gold.opacity(0.14) : Color.white.opacity(0.03))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .strokeBorder(
                                        game.preset == preset ? Theme.gold.opacity(0.42) : Color.white.opacity(0.07),
                                        lineWidth: 1
                                    )
                            )
                            .foregroundStyle(game.preset == preset ? Theme.goldLight : Theme.muted)
                        }
                        .buttonStyle(.plain)
                    }
                }

                Text("Сложность меняет цели квестов с сегодняшнего дня. Уже выполненные квесты не затрагиваются.")
                    .font(.system(size: 10.5))
                    .foregroundStyle(Theme.muted.opacity(0.75))
                    .lineSpacing(2)
            }
        }
    }

    private func presetHint(_ preset: Preset) -> String {
        switch preset {
        case .easy: return "×0.7"
        case .normal: return "×1.0"
        case .hard: return "×1.3"
        }
    }

    // MARK: Напоминания

    private var reminderPanel: some View {
        panel(title: "НАПОМИНАНИЕ", icon: "🔔") {
            VStack(spacing: 0) {
                HStack(spacing: 10) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Ежедневное напоминание")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(Theme.text)
                        Text("Локальное уведомление на этом iPhone")
                            .font(.system(size: 10.5))
                            .foregroundStyle(Theme.muted.opacity(0.8))
                    }

                    Spacer()

                    Toggle("", isOn: reminderBinding)
                        .labelsHidden()
                        .tint(Theme.goldDeep)
                }

                if game.reminderEnabled {
                    Rectangle()
                        .fill(Theme.line)
                        .frame(height: 1)
                        .padding(.vertical, 10)

                    HStack {
                        Text("Время")
                            .font(.system(size: 12.5))
                            .foregroundStyle(Theme.text)

                        Spacer()

                        DatePicker(
                            "",
                            selection: timeBinding,
                            displayedComponents: .hourAndMinute
                        )
                        .labelsHidden()
                        .datePickerStyle(.compact)
                        .tint(Theme.gold)
                    }
                }
            }
        }
    }

    // MARK: Шаги

    private var stepPanel: some View {
        panel(title: "ШАГИ", icon: "👟") {
            HStack(spacing: 10) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Синхронизация шагов")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Theme.text)
                    Text("Считать шаги датчиком движения iPhone")
                        .font(.system(size: 10.5))
                        .foregroundStyle(Theme.muted.opacity(0.8))
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()

                Toggle("", isOn: $game.stepSync)
                    .labelsHidden()
                    .tint(Theme.goldDeep)
            }
        }
    }

    // MARK: Сброс

    private var resetPanel: some View {
        Button {
            Haptics.tap()
            confirmReset = true
        } label: {
            HStack(spacing: 12) {
                Text("☠️")
                    .font(.system(size: 15))
                    .frame(width: 34, height: 34)
                    .background(RoundedRectangle(cornerRadius: 10).fill(Theme.red.opacity(0.08)))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .strokeBorder(Theme.red.opacity(0.22), lineWidth: 1)
                    )

                VStack(alignment: .leading, spacing: 2) {
                    Text("Начать заново")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Theme.red)
                    Text("Удалит весь прогресс")
                        .font(.system(size: 10.5))
                        .foregroundStyle(Theme.muted.opacity(0.8))
                }

                Spacer()

                Text("›")
                    .font(.system(size: 18))
                    .foregroundStyle(Theme.muted.opacity(0.5))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 13)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Theme.panel.opacity(0.7)))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(Theme.line, lineWidth: 1)
        )
        .padding(.top, 14)
    }

    private var footer: some View {
        VStack(spacing: 3) {
            Text("Квесты дня · версия 1.0")
                .font(.system(size: 10))
                .foregroundStyle(Theme.muted.opacity(0.55))
            Text("Без аккаунтов и серверов. Все данные — на этом iPhone.")
                .font(.system(size: 9.5))
                .foregroundStyle(Theme.muted.opacity(0.45))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 22)
    }

    // MARK: Панель

    private func panel<Content: View>(
        title: String,
        icon: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Text(icon)
                    .font(.system(size: 11))
                Text(title)
                    .font(.system(size: 9, weight: .semibold))
                    .tracking(1.6)
                    .foregroundStyle(Theme.goldDeep)
            }

            content()
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Theme.panel.opacity(0.7)))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(Theme.line, lineWidth: 1)
        )
        .padding(.bottom, 10)
    }
}

// MARK: - Знакомство

struct OnboardingSheet: View {
    @EnvironmentObject private var game: GameState
    @Environment(\.dismiss) private var dismiss

    private let lines: [(String, String)] = [
        ("⚔️", "Каждый день — 5 новых квестов. Главный всегда один: пройти 10 000 шагов (цель меняется от сложности)."),
        ("👟", "Шаги считаются автоматически датчиком движения iPhone. Остальные квесты отмечаешь сам."),
        ("🔥", "День идёт в стрик, если закрыто 3 из 5 квестов. Все пять — идеальный день и бонус +50 XP."),
        ("🛡️", "За квесты дают XP, за XP — уровни и титулы. В журнале видно историю и график недели.")
    ]

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()

            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: 0) {
                        Text("🛡️")
                            .font(.system(size: 52))
                            .padding(.top, 34)
                            .padding(.bottom, 12)

                        Text("ЕЖЕДНЕВНЫЕ КВЕСТЫ")
                            .font(.system(size: 9.5, weight: .semibold))
                            .tracking(2.4)
                            .foregroundStyle(Theme.goldDeep)

                        Text("Твой путь героя")
                            .font(.display(27))
                            .foregroundStyle(Theme.goldLight)
                            .padding(.top, 5)

                        Text("Маленькие квесты каждый день — большие перемены за месяц.")
                            .font(.system(size: 12))
                            .foregroundStyle(Theme.muted)
                            .multilineTextAlignment(.center)
                            .lineSpacing(3)
                            .padding(.horizontal, 22)
                            .padding(.top, 8)

                        VStack(spacing: 10) {
                            ForEach(lines.indices, id: \.self) { index in
                                let line = lines[index]
                                HStack(alignment: .top, spacing: 12) {
                                    Text(line.0)
                                        .font(.system(size: 17))
                                        .frame(width: 34, height: 34)
                                        .background(
                                            RoundedRectangle(cornerRadius: 10)
                                                .fill(Theme.gold.opacity(0.09))
                                        )
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 10)
                                                .strokeBorder(Theme.gold.opacity(0.22), lineWidth: 1)
                                        )

                                    Text(line.1)
                                        .font(.system(size: 12))
                                        .foregroundStyle(Theme.text.opacity(0.9))
                                        .lineSpacing(3)
                                        .fixedSize(horizontal: false, vertical: true)

                                    Spacer(minLength: 0)
                                }
                            }
                        }
                        .padding(.horizontal, 18)
                        .padding(.top, 22)
                        .padding(.bottom, 24)
                    }
                }
                .scrollIndicators(.hidden)

                Button {
                    Haptics.success()
                    game.onboarded = true
                    dismiss()
                } label: {
                    Text("Начать путь")
                        .font(.display(17, weight: .bold))
                        .foregroundStyle(Color(hex: 0x1A1206))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                        .background(
                            RoundedRectangle(cornerRadius: 13, style: .continuous)
                                .fill(
                                    LinearGradient(
                                        colors: [Theme.goldLight, Theme.gold, Theme.goldDeep],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                        )
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 18)
                .padding(.top, 8)
                .padding(.bottom, 18)
            }
        }
        .interactiveDismissDisabled()
        .presentationDragIndicator(.hidden)
        .presentationDetents([.large])
    }
}

// MARK: - Ввод числа

struct NumberEditorSheet: View {
    @EnvironmentObject private var game: GameState
    @Environment(\.dismiss) private var dismiss

    let item: QuestItem

    @State private var value: Int = 0
    @FocusState private var focused: Bool

    private var current: Int {
        let record = game.record(for: item)
        return record.done ? item.target : record.progress
    }

    var body: some View {
        ZStack {
            Theme.sheet.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top, spacing: 10) {
                    Text(item.def.icon)
                        .font(.system(size: 20))
                        .frame(width: 38, height: 38)
                        .background(RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.05)))

                    VStack(alignment: .leading, spacing: 2) {
                        Text(item.def.title)
                            .font(.display(16))
                            .foregroundStyle(Theme.text)
                        Text("Цель: \(item.progressText(item.target))")
                            .font(.system(size: 11))
                            .foregroundStyle(Theme.muted)
                    }

                    Spacer()

                    Button {
                        Haptics.tap()
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(Theme.muted)
                            .frame(width: 30, height: 30)
                            .background(Circle().fill(Color.white.opacity(0.05)))
                    }
                    .buttonStyle(.plain)
                }

                HStack(spacing: 10) {
                    Button {
                        Haptics.tap()
                        value = max(0, value - item.step)
                    } label: {
                        Text("−")
                            .font(.display(22, weight: .bold))
                            .foregroundStyle(Theme.muted)
                            .frame(width: 50, height: 50)
                            .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.05)))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)

                    TextField("0", value: $value, format: .number)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.center)
                        .font(.display(24, weight: .bold))
                        .foregroundStyle(Theme.goldLight)
                        .focused($focused)
                        .frame(height: 50)
                        .frame(maxWidth: .infinity)
                        .background(RoundedRectangle(cornerRadius: 12).fill(Color(hex: 0x0B0812)))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .strokeBorder(Theme.gold.opacity(0.28), lineWidth: 1)
                        )

                    Button {
                        Haptics.tap()
                        value = min(item.target, value + item.step)
                    } label: {
                        Text("+")
                            .font(.display(22, weight: .bold))
                            .foregroundStyle(Theme.gold)
                            .frame(width: 50, height: 50)
                            .background(RoundedRectangle(cornerRadius: 12).fill(Theme.gold.opacity(0.10)))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .strokeBorder(Theme.gold.opacity(0.28), lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                }

                HStack(spacing: 8) {
                    Text("шаг: \(fmt(item.step)) \(item.def.unit)")
                        .font(.system(size: 10.5))
                        .foregroundStyle(Theme.muted.opacity(0.7))

                    Spacer()

                    Button {
                        Haptics.tap()
                        value = item.target
                    } label: {
                        Text("Цель")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(Theme.gold)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(RoundedRectangle(cornerRadius: 8).fill(Theme.gold.opacity(0.08)))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .strokeBorder(Theme.gold.opacity(0.22), lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)

                    Button {
                        Haptics.tap()
                        value = 0
                    } label: {
                        Text("Сброс")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(Theme.muted)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(RoundedRectangle(cornerRadius: 8).fill(Color.white.opacity(0.04)))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                }

                Button {
                    Haptics.success()
                    game.setProgress(item, to: value)
                    dismiss()
                } label: {
                    Text("Сохранить")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(Color(hex: 0x1A1206))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 13)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(
                                    LinearGradient(
                                        colors: [Theme.goldLight, Theme.gold, Theme.goldDeep],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                        )
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 14)
        }
        .presentationDetents([.height(330)])
        .presentationDragIndicator(.visible)
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Готово") { focused = false }
            }
        }
        .onAppear {
            value = current
        }
    }
}
