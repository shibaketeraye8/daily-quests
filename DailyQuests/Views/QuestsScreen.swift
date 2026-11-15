import SwiftUI
import Foundation

struct QuestsScreen: View {
    @EnvironmentObject private var game: GameState
    @EnvironmentObject private var pedometer: PedometerService
    @State private var editingItem: QuestItem?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                header
                if pedometer.permissionDenied {
                    motionWarning
                        .padding(.bottom, 10)
                }
                dayBar
                    .padding(.bottom, 16)

                ForEach(game.todayItems()) { item in
                    QuestCard(item: item, record: game.record(for: item)) {
                        editingItem = item
                    }
                    .padding(.bottom, 10)
                }

                Text("День идёт в стрик, если выполнено 3 из 5 квестов.\nВсе пять — идеальный день с бонусом.")
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.muted.opacity(0.75))
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 12)
                    .padding(.top, 8)
                    .padding(.bottom, 24)
            }
            .padding(.horizontal, 16)
        }
        .scrollIndicators(.hidden)
        .sheet(item: $editingItem) { item in
            NumberEditorSheet(item: item)
                .environmentObject(game)
        }
    }

    // MARK: Заголовок

    private var header: some View {
        HStack(alignment: .bottom, spacing: 12) {
            VStack(alignment: .leading, spacing: 5) {
                Text("ЕЖЕДНЕВНЫЕ КВЕСТЫ")
                    .font(.system(size: 9.5, weight: .semibold))
                    .tracking(2.4)
                    .foregroundStyle(Theme.goldDeep)

                Text(game.dayTitle)
                    .font(.display(25))
                    .foregroundStyle(Theme.goldLight)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }

            Spacer(minLength: 4)

            VStack(alignment: .trailing, spacing: 3) {
                Text("НОВЫЕ ЧЕРЕЗ")
                    .font(.system(size: 8.5, weight: .medium))
                    .tracking(1.4)
                    .foregroundStyle(Theme.muted.opacity(0.7))

                TimelineView(.periodic(from: .now, by: 1)) { context in
                    Text(countdown(to: context.date))
                        .font(.display(14, weight: .semibold))
                        .monospacedDigit()
                        .foregroundStyle(Theme.gold)
                }
            }
        }
        .padding(.top, 20)
        .padding(.bottom, 14)
    }

    private func countdown(to date: Date) -> String {
        let calendar = Calendar.current
        let next = calendar.startOfDay(for: calendar.date(byAdding: .day, value: 1, to: date) ?? date)
        let seconds = max(0, Int(next.timeIntervalSince(date)))
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        let secs = seconds % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, secs)
    }

    // MARK: Нет доступа к шагам

    private var motionWarning: some View {
        HStack(alignment: .top, spacing: 9) {
            Text("👟")
                .font(.system(size: 14))

            VStack(alignment: .leading, spacing: 2) {
                Text("Шаги не считаются")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Theme.goldLight)
                Text("Разреши доступ к движению: Настройки iPhone → Конфиденциальность → Движение и фитнес → Квесты.")
                    .font(.system(size: 10.5))
                    .foregroundStyle(Theme.muted)
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 12).fill(Theme.gold.opacity(0.07)))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(Theme.gold.opacity(0.28), lineWidth: 1)
        )
    }

    // MARK: Полоса дня

    private var dayBar: some View {
        let items = game.todayItems()
        let done = game.doneCount(in: game.days[game.todayKey])
        let fraction = items.isEmpty ? 0 : Double(done) / Double(items.count)
        let reached = done >= GameState.dailyGoal
        let left = max(0, GameState.dailyGoal - done)

        return VStack(spacing: 8) {
            HStack {
                Text("\(done) / \(items.count)")
                    .font(.display(15))
                    .foregroundStyle(Theme.goldLight)

                Spacer()

                Text(reached ? "день засчитан ✓" : "ещё \(left) до стрика")
                    .font(.system(size: 10, weight: .medium))
                    .tracking(0.8)
                    .foregroundStyle(reached ? Theme.green : Theme.muted)
            }

            ProgressTrack(value: fraction, height: 6)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Theme.panel.opacity(0.55))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(Theme.line, lineWidth: 1)
        )
    }
}

// MARK: - Карточка квеста

struct QuestCard: View {
    @EnvironmentObject private var game: GameState

    let item: QuestItem
    let record: QuestRecord
    var onEdit: () -> Void

    private var progress: Int {
        record.done ? item.target : min(record.progress, item.target)
    }

    private var fraction: Double {
        guard item.target > 0 else { return record.done ? 1 : 0 }
        return min(1, Double(progress) / Double(item.target))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top, spacing: 11) {
                iconView

                VStack(alignment: .leading, spacing: 3) {
                    if item.def.isMain {
                        Text("ГЛАВНЫЙ КВЕСТ")
                            .font(.system(size: 8, weight: .semibold))
                            .tracking(1.6)
                            .foregroundStyle(Theme.gold)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(RoundedRectangle(cornerRadius: 5).fill(Theme.gold.opacity(0.08)))
                            .overlay(
                                RoundedRectangle(cornerRadius: 5)
                                    .strokeBorder(Theme.gold.opacity(0.35), lineWidth: 1)
                            )
                            .padding(.bottom, 2)
                    }

                    Text(item.def.title)
                        .font(.display(16))
                        .foregroundStyle(record.done ? Theme.text.opacity(0.62) : Theme.text)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(item.detailText)
                        .font(.system(size: 12))
                        .foregroundStyle(Theme.muted)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 4)
                badge
            }

            ProgressTrack(value: fraction, isDone: record.done)
                .padding(.top, 11)

            HStack(spacing: 6) {
                progressLabel
                Spacer(minLength: 6)
                actionRow
            }
            .padding(.top, 9)
        }
        .padding(14)
        .cardStyle(isMain: item.def.isMain, isDone: record.done)
        .animation(.easeInOut(duration: 0.25), value: record.done)
    }

    private var iconView: some View {
        ZStack(alignment: .bottomTrailing) {
            Text(item.def.icon)
                .font(.system(size: 21))
                .frame(width: 44, height: 44)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.white.opacity(0.055))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
                )
                .opacity(record.done ? 0.75 : 1)

            if record.done {
                Text("✓")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(Color(hex: 0x07130D))
                    .frame(width: 18, height: 18)
                    .background(Circle().fill(Theme.green))
                    .overlay(Circle().strokeBorder(Theme.panelDeep, lineWidth: 2))
                    .offset(x: 4, y: 4)
            }
        }
    }

    private var badge: some View {
        HStack(alignment: .firstTextBaseline, spacing: 2) {
            if record.done {
                Text("✓")
                    .font(.system(size: 13, weight: .bold))
            } else {
                Text("+\(item.xp)")
                    .font(.display(14, weight: .bold))
                Text("XP")
                    .font(.system(size: 8, weight: .semibold))
                    .tracking(0.8)
            }
        }
        .foregroundStyle(record.done ? Theme.green : Theme.gold)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill((record.done ? Theme.green : Theme.gold).opacity(0.08))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder((record.done ? Theme.green : Theme.gold).opacity(0.2), lineWidth: 1)
        )
    }

    @ViewBuilder
    private var progressLabel: some View {
        if item.kind == .count {
            Button(action: onEdit) {
                Text(item.progressText(progress))
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Theme.muted)
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .buttonStyle(.plain)
        } else {
            Text(record.done ? "выполнено" : "отметь, когда сделаешь")
                .font(.system(size: 11))
                .foregroundStyle(Theme.muted)
                .lineLimit(1)
        }
    }

    @ViewBuilder
    private var actionRow: some View {
        HStack(spacing: 6) {
            if record.done {
                Chip(title: "↺ отменить", style: .ghost) {
                    game.undo(item)
                }
            } else if item.kind == .count {
                Chip(title: "−", style: .ghost, minWidth: 32) {
                    game.addProgress(item, by: -item.step)
                }
                Chip(title: "+\(fmt(item.step))", style: .gold) {
                    game.addProgress(item, by: item.step)
                }
                Chip(title: "✓", style: .violet, minWidth: 32) {
                    game.complete(item)
                }
            } else {
                Chip(title: "Выполнить", style: .violet) {
                    game.complete(item)
                }
            }
        }
    }
}
