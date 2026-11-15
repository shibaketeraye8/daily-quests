import SwiftUI
import Foundation

struct JournalScreen: View {
    @EnvironmentObject private var game: GameState

    private struct Row: Identifiable {
        let key: String
        let date: Date
        let xp: Int
        let done: Int
        var id: String { key }
    }

    private static let weekdayShort: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ru_RU")
        formatter.dateFormat = "EE"
        return formatter
    }()

    private static let dayMonthShort: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ru_RU")
        formatter.dateFormat = "d MMM"
        return formatter
    }()

    // MARK: Неделя

    private var weekRows: [Row] {
        let calendar = Calendar.current
        let today = Date()
        return (0..<7).reversed().compactMap { offset in
            guard let date = calendar.date(byAdding: .day, value: -offset, to: today) else { return nil }
            let key = GameState.key(for: date)
            let day = game.days[key]
            return Row(
                key: key,
                date: date,
                xp: game.xp(for: key),
                done: game.doneCount(in: day)
            )
        }
    }

    // MARK: История

    private var historyRows: [Row] {
        let calendar = Calendar.current
        return game.days.keys
            .filter { key in
                let day = game.days[key]
                return game.doneCount(in: day) > 0 || game.xp(for: key) > 0
            }
            .sorted()
            .reversed()
            .prefix(14)
            .compactMap { key in
                guard let date = GameState.date(from: key) else { return nil }
                return Row(
                    key: key,
                    date: calendar.startOfDay(for: date),
                    xp: game.xp(for: key),
                    done: game.doneCount(in: game.days[key])
                )
            }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                header

                sectionHead("Последние 7 дней", value: "\(fmt(weekTotal)) XP")
                weekChart

                sectionHead("История", value: nil)
                historyPanel
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
        }
        .scrollIndicators(.hidden)
    }

    private var weekTotal: Int {
        weekRows.reduce(0) { $0 + $1.xp }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text("ЖУРНАЛ ПУТИ")
                .font(.system(size: 9.5, weight: .semibold))
                .tracking(2.4)
                .foregroundStyle(Theme.goldDeep)

            Text("Хроника героя")
                .font(.display(25))
                .foregroundStyle(Theme.goldLight)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .padding(.top, 20)
        .padding(.bottom, 6)
    }

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
                    .monospacedDigit()
            }
        }
        .padding(.top, 18)
        .padding(.bottom, 10)
    }

    // MARK: График

    private var weekChart: some View {
        let rows = weekRows
        let maxXp = max(50, rows.map { $0.xp }.max() ?? 0)
        let total = rows.reduce(0) { $0 + $1.xp }

        return Group {
            if total == 0 {
                VStack(spacing: 6) {
                    Text("Пока пусто.")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Theme.muted)
                    Text("Выполни первый квест — и здесь появится график.")
                        .font(.system(size: 11))
                        .foregroundStyle(Theme.muted.opacity(0.7))
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 34)
                .background(RoundedRectangle(cornerRadius: 14).fill(Theme.panel.opacity(0.6)))
                .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Theme.line, lineWidth: 1))
            } else {
                HStack(alignment: .bottom, spacing: 6) {
                    ForEach(rows) { row in
                        chartColumn(row, maxXp: maxXp, isToday: row.key == game.todayKey)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 10)
                .padding(.top, 12)
                .padding(.bottom, 10)
                .background(RoundedRectangle(cornerRadius: 14).fill(Theme.panel.opacity(0.6)))
                .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Theme.line, lineWidth: 1))
            }
        }
    }

    private func chartColumn(_ row: Row, maxXp: Int, isToday: Bool) -> some View {
        let fraction = row.xp > 0 ? max(0.08, CGFloat(row.xp) / CGFloat(maxXp)) : 0
        let fullHeight: CGFloat = 96
        let height = row.xp > 0 ? max(6, fullHeight * fraction) : 4

        return VStack(spacing: 5) {
            Text(row.xp > 0 ? fmt(row.xp) : " ")
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(isToday ? Theme.gold : Theme.muted)
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            ZStack(alignment: .bottom) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.white.opacity(0.03))
                    .frame(height: fullHeight)

                RoundedRectangle(cornerRadius: 4)
                    .fill(
                        LinearGradient(
                            colors: row.xp > 0
                                ? [Color(hex: 0x6F4FD8), Theme.violet, Theme.gold]
                                : [Color.white.opacity(0.08), Color.white.opacity(0.04)],
                            startPoint: .bottom,
                            endPoint: .top
                        )
                    )
                    .frame(height: height)
                    .animation(.spring(response: 0.5, dampingFraction: 0.85), value: height)
            }
            .frame(maxWidth: .infinity)
            .frame(height: fullHeight, alignment: .bottom)

            Text(Self.weekdayShort.string(from: row.date).uppercased())
                .font(.system(size: 9, weight: isToday ? .bold : .medium))
                .foregroundStyle(isToday ? Theme.gold : Theme.muted.opacity(0.8))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: История

    private var historyPanel: some View {
        let rows = historyRows

        return Group {
            if rows.isEmpty {
                VStack(spacing: 6) {
                    Text("Летопись пока пуста.")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Theme.muted)
                    Text("Выполни первый квест — и здесь появится история.")
                        .font(.system(size: 11))
                        .foregroundStyle(Theme.muted.opacity(0.7))
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 28)
                .padding(.horizontal, 12)
                .background(RoundedRectangle(cornerRadius: 14).fill(Theme.panel.opacity(0.6)))
                .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Theme.line, lineWidth: 1))
            } else {
                VStack(spacing: 0) {
                    ForEach(rows.indices, id: \.self) { index in
                        let row = rows[index]
                        if index > 0 {
                            Rectangle()
                                .fill(Theme.line)
                                .frame(height: 1)
                                .padding(.leading, 14)
                        }
                        historyRow(row)
                    }
                }
                .background(RoundedRectangle(cornerRadius: 14).fill(Theme.panel.opacity(0.6)))
                .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Theme.line, lineWidth: 1))
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
        }
    }

    private func historyRow(_ row: Row) -> some View {
        HStack(spacing: 10) {
            Text(Self.dayMonthShort.string(from: row.date))
                .font(.system(size: 11.5, weight: .medium))
                .foregroundStyle(Theme.text)
                .frame(width: 62, alignment: .leading)
                .lineLimit(1)

            HStack(spacing: 4) {
                ForEach(0..<QuestPool.perDay, id: \.self) { index in
                    Circle()
                        .fill(index < row.done ? Theme.green : Color.white.opacity(0.09))
                        .frame(width: 6, height: 6)
                }
            }

            Spacer(minLength: 6)

            Text(row.xp > 0 ? "+\(fmt(row.xp)) XP" : "—")
                .font(.system(size: 11.5, weight: .semibold))
                .foregroundStyle(row.xp > 0 ? Theme.gold : Theme.muted.opacity(0.5))
                .monospacedDigit()
                .lineLimit(1)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
    }
}
