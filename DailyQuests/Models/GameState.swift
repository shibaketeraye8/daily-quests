import SwiftUI
import Foundation
import Combine

// MARK: - Записи

struct QuestRecord: Codable, Equatable {
    var progress: Int = 0
    var done: Bool = false
    var reward: Int = 0
    var ts: Date? = nil
}

struct DayState: Codable, Equatable {
    var quests: [String: QuestRecord] = [:]
    var bonus: Bool = false
}

private struct Snapshot: Codable {
    var xp: Int
    var started: String
    var preset: Preset
    var days: [String: DayState]
    var achievements: [String: String]
    var onboarded: Bool
    var stepSync: Bool
    var reminderEnabled: Bool
    var reminderHour: Int
    var reminderMinute: Int
}

struct Toast: Identifiable, Equatable {
    let id = UUID()
    let text: String
    let green: Bool
}

struct LevelInfo {
    let level: Int
    let cur: Int
    let need: Int
    let title: String

    var progress: Double {
        need > 0 ? min(1, Double(cur) / Double(need)) : 0
    }
}

struct Stats {
    var totalQuests: Int
    var perfectDays: Int
    var stepsDone: Bool
    var level: Int
    var currentStreak: Int
    var bestStreak: Int
    var daysInGame: Int
}

struct Achievement: Identifiable {
    let id: String
    let icon: String
    let name: String
    let detail: String
    let test: (Stats) -> Bool
}

let allAchievements: [Achievement] = [
    Achievement(id: "first", icon: "🗡️", name: "Первый удар",
                detail: "Выполни первый квест", test: { $0.totalQuests >= 1 }),
    Achievement(id: "streak3", icon: "🔥", name: "Три дня подряд",
                detail: "Стрик 3 дня", test: { $0.bestStreak >= 3 }),
    Achievement(id: "streak7", icon: "⚡", name: "Неделя силы",
                detail: "Стрик 7 дней", test: { $0.bestStreak >= 7 }),
    Achievement(id: "streak30", icon: "👑", name: "Месяц легенды",
                detail: "Стрик 30 дней", test: { $0.bestStreak >= 30 }),
    Achievement(id: "perfect", icon: "⭐", name: "Идеальный день",
                detail: "Выполни все 5 квестов", test: { $0.perfectDays >= 1 }),
    Achievement(id: "steps10k", icon: "🥾", name: "Десять тысяч",
                detail: "Закрой квест шагов", test: { $0.stepsDone }),
    Achievement(id: "q50", icon: "🏰", name: "Ветеран",
                detail: "Выполни 50 квестов", test: { $0.totalQuests >= 50 }),
    Achievement(id: "lvl5", icon: "🛡️", name: "Рыцарь",
                detail: "Достигни 5 уровня", test: { $0.level >= 5 }),
    Achievement(id: "lvl10", icon: "🌟", name: "Легенда",
                detail: "Достигни 10 уровня", test: { $0.level >= 10 })
]

// MARK: - Игровое состояние

final class GameState: ObservableObject {

    static let dailyGoal = 3
    static let perfectBonus = 50
    private static let storageKey = "daily_quests_state_v1"

    @Published private(set) var xp: Int = 0
    @Published private(set) var days: [String: DayState] = [:]
    @Published private(set) var achievements: [String: String] = [:]
    @Published private(set) var toasts: [Toast] = []

    @Published var preset: Preset = .normal {
        didSet {
            cacheKey = ""
            save()
        }
    }
    @Published var onboarded: Bool = false {
        didSet { save() }
    }
    @Published var stepSync: Bool = true {
        didSet { save() }
    }
    @Published var reminderEnabled: Bool = false {
        didSet {
            save()
            updateReminder()
        }
    }
    @Published var reminderHour: Int = 20 {
        didSet {
            save()
            updateReminder()
        }
    }
    @Published var reminderMinute: Int = 0 {
        didSet {
            save()
            updateReminder()
        }
    }

    let started: String

    private var cacheKey = ""
    private var cachePreset: Preset = .normal
    private var cacheItems: [QuestItem] = []

    // MARK: Инициализация

    init() {
        let today = GameState.key(for: Date())

        if let data = UserDefaults.standard.data(forKey: GameState.storageKey),
           let snapshot = try? JSONDecoder().decode(Snapshot.self, from: data) {
            xp = snapshot.xp
            started = snapshot.started
            preset = snapshot.preset
            days = snapshot.days
            achievements = snapshot.achievements
            onboarded = snapshot.onboarded
            stepSync = snapshot.stepSync
            reminderEnabled = snapshot.reminderEnabled
            reminderHour = snapshot.reminderHour
            reminderMinute = snapshot.reminderMinute
        } else {
            started = today
        }

        if days[today] == nil {
            days[today] = DayState()
        }
    }

    // MARK: Сохранение

    private func save() {
        let snapshot = Snapshot(
            xp: xp,
            started: started,
            preset: preset,
            days: days,
            achievements: achievements,
            onboarded: onboarded,
            stepSync: stepSync,
            reminderEnabled: reminderEnabled,
            reminderHour: reminderHour,
            reminderMinute: reminderMinute
        )
        if let data = try? JSONEncoder().encode(snapshot) {
            UserDefaults.standard.set(data, forKey: GameState.storageKey)
        }
    }

    // MARK: Даты

    private static let keyFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    private static let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ru_RU")
        formatter.dateFormat = "d MMMM"
        return formatter
    }()

    static func key(for date: Date) -> String {
        keyFormatter.string(from: date)
    }

    static func date(from key: String) -> Date? {
        keyFormatter.date(from: key)
    }

    static func shift(_ key: String, by days: Int) -> String {
        guard let date = date(from: key) else { return key }
        let next = Calendar.current.date(byAdding: .day, value: days, to: date) ?? date
        return self.key(for: next)
    }

    static func dayTitle(_ key: String) -> String {
        guard let date = date(from: key) else { return key }
        let weekday = DateFormatter()
        weekday.locale = Locale(identifier: "ru_RU")
        weekday.dateFormat = "E"
        let wd = weekday.string(from: date).capitalized
        return "\(wd), \(dayFormatter.string(from: date))"
    }

    var todayKey: String { GameState.key(for: Date()) }

    var dayTitle: String {
        GameState.dayTitle(todayKey)
    }

    func refreshDay() {
        let key = todayKey
        if days[key] == nil {
            days[key] = DayState()
            save()
        }
    }

    // MARK: Квесты дня

    func todayItems() -> [QuestItem] {
        let key = todayKey
        if cacheKey == key && cachePreset == preset {
            return cacheItems
        }
        let items = QuestPool.daily(key: key, preset: preset)
        cacheKey = key
        cachePreset = preset
        cacheItems = items
        return items
    }

    func record(for item: QuestItem) -> QuestRecord {
        days[todayKey]?.quests[item.id] ?? QuestRecord()
    }

    func doneCount(in day: DayState?) -> Int {
        guard let day = day else { return 0 }
        return day.quests.values.filter { $0.done }.count
    }

    func isCounted(_ day: DayState?) -> Bool {
        doneCount(in: day) >= GameState.dailyGoal
    }

    // MARK: Действия

    func setProgress(_ item: QuestItem, to value: Int) {
        let key = todayKey
        guard var day = days[key] else { return }
        var record = day.quests[item.id] ?? QuestRecord()
        guard !record.done else { return }

        let clamped = max(0, min(value, item.target))
        record.progress = clamped
        day.quests[item.id] = record
        days[key] = day

        if clamped >= item.target {
            complete(item)
        } else {
            save()
        }
    }

    func addProgress(_ item: QuestItem, by delta: Int) {
        let current = record(for: item)
        setProgress(item, to: current.progress + delta)
    }

    func complete(_ item: QuestItem) {
        let key = todayKey
        guard var day = days[key] else { return }
        var record = day.quests[item.id] ?? QuestRecord()
        guard !record.done else { return }

        let levelBefore = levelInfo(xp).level

        record.progress = item.target
        record.done = true
        record.reward = item.xp
        record.ts = Date()
        day.quests[item.id] = record
        days[key] = day
        xp += item.xp

        save()
        Haptics.success()
        pushToast("+\(item.xp) XP · \(item.def.title)")

        let levelAfter = levelInfo(xp)
        if levelAfter.level > levelBefore {
            pushToast("🎉 Уровень \(levelAfter.level) — \(levelAfter.title)", green: true)
        }

        checkPerfectDay()
        checkAchievements()
    }

    func undo(_ item: QuestItem) {
        let key = todayKey
        guard var day = days[key],
              var record = day.quests[item.id],
              record.done else { return }

        xp = max(0, xp - record.reward)

        record.done = false
        record.progress = max(0, item.target - max(1, item.step))
        record.reward = 0
        record.ts = nil
        day.quests[item.id] = record

        if day.bonus {
            day.bonus = false
            xp = max(0, xp - GameState.perfectBonus)
        }

        days[key] = day
        save()
        pushToast("Квест возвращён в работу")
    }

    /// Автоматическая синхронизация шагов с датчиком движения iPhone.
    func syncSteps(_ steps: Int) {
        guard stepSync, steps > 0 else { return }
        guard let item = todayItems().first(where: { $0.def.id == "steps" }) else { return }

        let current = record(for: item)
        guard !current.done else { return }

        let value = min(steps, item.target)
        if value > current.progress {
            setProgress(item, to: value)
        }
    }

    private func checkPerfectDay() {
        let key = todayKey
        guard var day = days[key] else { return }
        let items = todayItems()
        guard !items.isEmpty else { return }

        let allDone = items.allSatisfy { day.quests[$0.id]?.done == true }
        guard allDone, !day.bonus else { return }

        day.bonus = true
        days[key] = day
        xp += GameState.perfectBonus
        save()
        pushToast("⭐ Идеальный день! +50 XP", green: true)
        Haptics.success()
        checkAchievements()
    }

    // MARK: Достижения

    var stats: Stats {
        var totalQuests = 0
        var perfectDays = 0
        var stepsDone = false

        for day in days.values {
            let done = doneCount(in: day)
            totalQuests += done
            if done >= QuestPool.perDay { perfectDays += 1 }
            if day.quests["steps"]?.done == true { stepsDone = true }
        }

        return Stats(
            totalQuests: totalQuests,
            perfectDays: perfectDays,
            stepsDone: stepsDone,
            level: levelInfo(xp).level,
            currentStreak: currentStreak,
            bestStreak: bestStreak,
            daysInGame: daysInGame
        )
    }

    private func checkAchievements() {
        let current = stats
        var unlocked = false
        for achievement in allAchievements {
            if achievements[achievement.id] == nil && achievement.test(current) {
                achievements[achievement.id] = todayKey
                unlocked = true
                let name = achievement.name
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { [weak self] in
                    self?.pushToast("🏆 Достижение: \(name)", green: true)
                }
            }
        }
        if unlocked {
            save()
        }
    }

    // MARK: Уровень

    func levelInfo(_ value: Int) -> LevelInfo {
        var level = 1
        var need = 100
        var rest = max(0, value)

        while rest >= need && level < 99 {
            rest -= need
            level += 1
            need = 100 + (level - 1) * 60
        }

        return LevelInfo(level: level, cur: rest, need: need, title: titleFor(level))
    }

    var level: LevelInfo { levelInfo(xp) }

    var title: String { level.title }

    func titleFor(_ level: Int) -> String {
        switch level {
        case 12...: return "Легенда"
        case 9...: return "Мастер"
        case 6...: return "Паладин"
        case 4...: return "Рыцарь"
        case 2...: return "Воин"
        default: return "Странник"
        }
    }

    // MARK: Стрик

    var currentStreak: Int {
        var date = Date()
        if !isCounted(days[GameState.key(for: date)]) {
            date = Calendar.current.date(byAdding: .day, value: -1, to: date) ?? date
        }

        var streak = 0
        while streak < 4000 {
            let key = GameState.key(for: date)
            guard isCounted(days[key]) else { break }
            streak += 1
            date = Calendar.current.date(byAdding: .day, value: -1, to: date) ?? date
        }
        return streak
    }

    var bestStreak: Int {
        let counted = days.filter { isCounted($0.value) }.map { $0.key }.sorted()
        guard !counted.isEmpty else { return 0 }

        var best = 0
        for key in counted {
            if counted.contains(GameState.shift(key, by: -1)) { continue }
            var length = 0
            var cursor = key
            while counted.contains(cursor) {
                length += 1
                cursor = GameState.shift(cursor, by: 1)
            }
            best = max(best, length)
        }
        return best
    }

    var daysInGame: Int {
        guard let start = GameState.date(from: started) else { return 1 }
        let diff = Calendar.current.dateComponents([.day], from: start, to: Date()).day ?? 0
        return max(1, diff + 1)
    }

    func xp(for key: String) -> Int {
        guard let day = days[key] else { return 0 }
        var sum = day.quests.values.filter { $0.done }.reduce(0) { $0 + $1.reward }
        if day.bonus { sum += GameState.perfectBonus }
        return sum
    }

    // MARK: Тосты

    func pushToast(_ text: String, green: Bool = false) {
        let toast = Toast(text: text, green: green)
        toasts.append(toast)
        if toasts.count > 3 {
            toasts.removeFirst(toasts.count - 3)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.4) { [weak self] in
            guard let self = self else { return }
            withAnimation(.easeOut(duration: 0.25)) {
                self.toasts.removeAll { $0.id == toast.id }
            }
        }
    }

    // MARK: Напоминания

    func updateReminder() {
        if reminderEnabled {
            Reminder.schedule(hour: reminderHour, minute: reminderMinute)
        } else {
            Reminder.cancel()
        }
    }

    func applyReminderSettings() {
        updateReminder()
    }

    // MARK: Сброс

    func resetAll() {
        xp = 0
        days = [:]
        achievements = [:]
        preset = .normal
        onboarded = false
        cacheKey = ""
        refreshDay()
        save()
    }
}
