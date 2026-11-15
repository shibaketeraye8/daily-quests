import SwiftUI

struct HeroScreen: View {
    @EnvironmentObject private var game: GameState
    var onSettings: () -> Void

    @State private var confirmReset = false

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                emblemPanel
                statsGrid.padding(.top, 12)
                sectionHead("Достижения", value: "\(game.achievements.count) / \(allAchievements.count)")
                achievementsGrid
                quickPanel.padding(.top, 22)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
        }
        .scrollIndicators(.hidden)
        .alert("Начать заново?", isPresented: $confirmReset) {
            Button("Удалить всё", role: .destructive) {
                game.resetAll()
            }
            Button("Отмена", role: .cancel) {}
        } message: {
            Text("Весь прогресс, XP, стрик и достижения будут удалены.")
        }
    }

    // MARK: Герой

    private var emblemPanel: some View {
        VStack(spacing: 0) {
            Text("🛡️")
                .font(.system(size: 46))
                .padding(.bottom, 8)

            Text("ТВОЙ ГЕРОЙ")
                .font(.system(size: 9.5, weight: .semibold))
                .tracking(2.4)
                .foregroundStyle(Theme.goldDeep)
                .padding(.bottom, 5)

            Text(game.title)
                .font(.display(26))
                .foregroundStyle(Theme.goldLight)

            Text("Уровень \(game.level.level) · \(fmt(game.xp)) XP")
                .font(.system(size: 12))
                .foregroundStyle(Theme.muted)
                .padding(.top, 4)

            ProgressTrack(value: game.level.progress, height: 9)
                .padding(.horizontal, 6)
                .padding(.top, 14)

            Text("До \(game.level.level + 1) уровня — \(fmt(game.level.need - game.level.cur)) XP")
                .font(.system(size: 10.5))
                .foregroundStyle(Theme.muted.opacity(0.8))
                .padding(.top, 9)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 22)
        .padding(.horizontal, 18)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color(hex: 0x191327), Color(hex: 0x12101C)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(Theme.line, lineWidth: 1)
        )
        .padding(.top, 20)
    }

    // MARK: Статы

    private var statsGrid: some View {
        let stats = game.stats
        let items: [(String, String)] = [
            (fmt(stats.totalQuests), "квестов выполнено"),
            ("\(stats.currentStreak)", "текущий стрик"),
            ("\(stats.bestStreak)", "лучший стрик"),
            ("\(stats.perfectDays)", "идеальных дней"),
            ("\(stats.daysInGame)", "день в игре"),
            (fmt(game.xp), "всего XP")
        ]

        return LazyVGrid(
            columns: [GridItem(.flexible(), spacing: 8), GridItem(.flexible(), spacing: 8)],
            spacing: 8
        ) {
            ForEach(items.indices, id: \.self) { index in
                let item = items[index]
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.0)
                        .font(.display(22))
                        .foregroundStyle(Theme.goldLight)
                    Text(item.1.uppercased())
                        .font(.system(size: 9, weight: .medium))
                        .tracking(1.2)
                        .foregroundStyle(Theme.muted)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(RoundedRectangle(cornerRadius: 13).fill(Theme.panel))
                .overlay(
                    RoundedRectangle(cornerRadius: 13)
                        .strokeBorder(Theme.line, lineWidth: 1)
                )
            }
        }
    }

    // MARK: Достижения

    private func sectionHead(_ title: String, value: String?) -> some View {
        HStack {
            Text(title)
                .font(.display(17))
                .foregroundStyle(Theme.goldLight)
            Spacer()
            if let value = value {
                Text(value)
                    .font(.system(size: 10.5, weight: .medium))
                    .tracking(0.6)
                    .foregroundStyle(Theme.muted)
            }
        }
        .padding(.top, 22)
        .padding(.bottom, 10)
    }

    private var achievementsGrid: some View {
        LazyVGrid(
            columns: [GridItem(.flexible(), spacing: 8), GridItem(.flexible(), spacing: 8)],
            spacing: 8
        ) {
            ForEach(allAchievements) { achievement in
                AchievementCell(
                    achievement: achievement,
                    isUnlocked: game.achievements[achievement.id] != nil
                )
            }
        }
    }

    // MARK: Кнопки

    private var quickPanel: some View {
        VStack(spacing: 0) {
            row(icon: "⚙️",
                title: "Настройки и напоминания",
                subtitle: "Сложность, уведомления, синхронизация шагов") {
                onSettings()
            }

            Divider().overlay(Theme.line)

            row(icon: "☠️",
                title: "Начать заново",
                subtitle: "Удалит весь прогресс",
                danger: true) {
                confirmReset = true
            }
        }
        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Theme.panel))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(Theme.line, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func row(
        icon: String,
        title: String,
        subtitle: String,
        danger: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Text(icon)
                    .font(.system(size: 15))
                    .frame(width: 34, height: 34)
                    .background(RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.045)))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .strokeBorder(Color.white.opacity(0.07), lineWidth: 1)
                    )

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(danger ? Theme.red : Theme.text)
                    Text(subtitle)
                        .font(.system(size: 10.5))
                        .foregroundStyle(Theme.muted.opacity(0.8))
                        .lineLimit(1)
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
    }
}

struct AchievementCell: View {
    let achievement: Achievement
    let isUnlocked: Bool

    var body: some View {
        HStack(spacing: 10) {
            Text(isUnlocked ? achievement.icon : "🔒")
                .font(.system(size: 17))
                .frame(width: 34, height: 34)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(isUnlocked ? Theme.gold.opacity(0.14) : Color.white.opacity(0.04))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .strokeBorder(
                            isUnlocked ? Theme.gold.opacity(0.3) : Color.white.opacity(0.06),
                            lineWidth: 1
                        )
                )

            VStack(alignment: .leading, spacing: 2) {
                Text(achievement.name)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(isUnlocked ? Theme.goldLight : Theme.muted)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                Text(achievement.detail)
                    .font(.system(size: 9.5))
                    .foregroundStyle(isUnlocked ? Theme.gold.opacity(0.7) : Theme.muted.opacity(0.6))
                    .lineLimit(2)
            }

            Spacer(minLength: 0)
        }
        .padding(10)
        .frame(maxWidth: .infinity, minHeight: 62, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 13)
                .fill(isUnlocked ? Theme.gold.opacity(0.07) : Color.white.opacity(0.02))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 13)
                .strokeBorder(
                    isUnlocked ? Theme.gold.opacity(0.28) : Color.white.opacity(0.05),
                    lineWidth: 1
                )
        )
    }
}
