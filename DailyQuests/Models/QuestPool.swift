import Foundation

// MARK: - Описание квеста

struct QuestDef: Identifiable, Hashable {
    enum Kind: String, Codable {
        case count
        case check
    }

    let id: String
    let icon: String
    let category: String
    let isMain: Bool
    let kind: Kind
    let title: String
    let detail: String
    let base: Int
    let step: Int
    let unit: String
    let xp: Int

    init(
        id: String,
        icon: String,
        category: String,
        isMain: Bool = false,
        kind: Kind = .count,
        title: String,
        detail: String,
        base: Int = 0,
        step: Int = 1,
        unit: String = "",
        xp: Int
    ) {
        self.id = id
        self.icon = icon
        self.category = category
        self.isMain = isMain
        self.kind = kind
        self.title = title
        self.detail = detail
        self.base = base
        self.step = step
        self.unit = unit
        self.xp = xp
    }
}

// MARK: - Квест дня

struct QuestItem: Identifiable, Hashable {
    let def: QuestDef
    let target: Int
    let step: Int
    let xp: Int

    var id: String { def.id }
    var kind: QuestDef.Kind { def.kind }

    func progressText(_ value: Int) -> String {
        let unit = def.unit.isEmpty ? "" : " \(def.unit)"
        return "\(fmt(value)) / \(fmt(target))\(unit)"
    }

    var detailText: String {
        def.detail.replacingOccurrences(of: "{t}", with: fmt(target))
    }
}

// MARK: - Сложность

enum Preset: String, Codable, CaseIterable, Identifiable {
    case easy
    case normal
    case hard

    var id: String { rawValue }

    var title: String {
        switch self {
        case .easy: return "Лёгкий"
        case .normal: return "Обычный"
        case .hard: return "Хардкор"
        }
    }

    var factor: Double {
        switch self {
        case .easy: return 0.7
        case .normal: return 1.0
        case .hard: return 1.3
        }
    }

    var xpFactor: Double {
        switch self {
        case .easy: return 0.85
        case .normal: return 1.0
        case .hard: return 1.25
        }
    }
}

// MARK: - Пул квестов

enum QuestPool {
    static let all: [QuestDef] = [
        QuestDef(id: "steps", icon: "👟", category: "move", isMain: true,
                 title: "Тропа тысячи шагов", detail: "Пройди {t} шагов за день",
                 base: 10000, step: 1000, unit: "шагов", xp: 60),
        QuestDef(id: "walk", icon: "🚶", category: "move",
                 title: "Дыхание улиц", detail: "Гуляй на свежем воздухе {t} минут",
                 base: 20, step: 5, unit: "мин", xp: 40),
        QuestDef(id: "run", icon: "🏃", category: "move",
                 title: "Рывок героя", detail: "Бег или быстрая ходьба — {t} минут",
                 base: 15, step: 5, unit: "мин", xp: 45),
        QuestDef(id: "stairs", icon: "🪜", category: "move",
                 title: "Восхождение", detail: "Поднимись по лестнице {t} пролётов",
                 base: 10, step: 1, unit: "прол.", xp: 30),
        QuestDef(id: "water", icon: "💧", category: "health",
                 title: "Живительная влага", detail: "Выпей {t} стаканов воды",
                 base: 8, step: 1, unit: "стак.", xp: 30),
        QuestDef(id: "pushups", icon: "💪", category: "strength",
                 title: "Сила рук", detail: "Отожмись {t} раз",
                 base: 30, step: 5, unit: "раз", xp: 35),
        QuestDef(id: "squats", icon: "🦵", category: "strength",
                 title: "Стойкость ног", detail: "Сделай {t} приседаний",
                 base: 40, step: 10, unit: "раз", xp: 35),
        QuestDef(id: "plank", icon: "🗿", category: "strength",
                 title: "Каменная стойка", detail: "Планка — {t} подхода по минуте",
                 base: 3, step: 1, unit: "подх.", xp: 30),
        QuestDef(id: "stretch", icon: "🤸", category: "health",
                 title: "Разминка героя", detail: "Растяжка и разминка — {t} минут",
                 base: 10, step: 5, unit: "мин", xp: 25),
        QuestDef(id: "fruit", icon: "🍎", category: "health",
                 title: "Дар природы", detail: "Съешь {t} порции фруктов или овощей",
                 base: 3, step: 1, unit: "порц.", xp: 25),
        QuestDef(id: "sun", icon: "☀️", category: "health",
                 title: "Солнечный заряд", detail: "Побудь на солнце {t} минут",
                 base: 15, step: 5, unit: "мин", xp: 25),
        QuestDef(id: "sleep", icon: "🌙", category: "health", kind: .check,
                 title: "Отдых героя", detail: "Ляг спать до 23:30", xp: 40),
        QuestDef(id: "nosugar", icon: "🍬", category: "health", kind: .check,
                 title: "Чистый путь", detail: "День без сладкого и сахара", xp: 45),
        QuestDef(id: "cold", icon: "🧊", category: "health", kind: .check,
                 title: "Испытание холодом", detail: "Контрастный душ", xp: 35),
        QuestDef(id: "meditate", icon: "🕯️", category: "mind",
                 title: "Тишина разума", detail: "Медитация {t} минут",
                 base: 10, step: 5, unit: "мин", xp: 30),
        QuestDef(id: "read", icon: "📖", category: "mind",
                 title: "Мудрость древних", detail: "Прочитай {t} страниц",
                 base: 20, step: 5, unit: "стр.", xp: 30),
        QuestDef(id: "learn", icon: "🧠", category: "mind",
                 title: "Древние знания", detail: "Учись чему-то новому {t} минут",
                 base: 15, step: 5, unit: "мин", xp: 30),
        QuestDef(id: "journal", icon: "✍️", category: "mind", kind: .check,
                 title: "Летопись", detail: "Запиши 3 благодарности", xp: 25),
        QuestDef(id: "plan", icon: "🗺️", category: "mind", kind: .check,
                 title: "План на завтра", detail: "Запиши 3 задачи на завтра", xp: 30),
        QuestDef(id: "detox", icon: "📵", category: "mind", kind: .check,
                 title: "Цифровой детокс", detail: "Час без телефона", xp: 35),
        QuestDef(id: "tidy", icon: "🧹", category: "home",
                 title: "Порядок в инвентаре", detail: "Уборка {t} минут",
                 base: 15, step: 5, unit: "мин", xp: 25),
        QuestDef(id: "call", icon: "📜", category: "social", kind: .check,
                 title: "Весть союзнику", detail: "Напиши или позвони близкому", xp: 30),
        QuestDef(id: "kind", icon: "🤝", category: "social", kind: .check,
                 title: "Доброе дело", detail: "Помоги кому-то сегодня", xp: 35)
    ]

    static let perDay = 5

    /// Детерминированный набор квестов на день.
    static func daily(key: String, preset: Preset) -> [QuestItem] {
        var rng = SplitMix64(seed: UInt64(fnv1a("quests|" + key)))

        guard let main = all.first(where: { $0.isMain }) else { return [] }
        var rest = all.filter { !$0.isMain }

        // перемешивание Фишера—Йетса
        if rest.count > 1 {
            var i = rest.count - 1
            while i > 0 {
                let j = Int(rng.nextUnit() * Double(i + 1))
                rest.swapAt(i, min(j, i))
                i -= 1
            }
        }

        var picked: [QuestDef] = []
        var usedCategories: Set<String> = [main.category]

        for quest in rest where picked.count < perDay - 1 {
            if usedCategories.contains(quest.category) { continue }
            usedCategories.insert(quest.category)
            picked.append(quest)
        }
        for quest in rest where picked.count < perDay - 1 {
            if picked.contains(where: { $0.id == quest.id }) { continue }
            picked.append(quest)
        }

        return ([main] + picked).map { def in
            var target = 0
            var step = 0
            if def.kind == .count {
                let raw = Double(def.base) * preset.factor
                target = Int((raw / Double(max(1, def.step))).rounded()) * def.step
                target = max(def.step, target)
                step = def.step
            }
            let xp = Int((Double(def.xp) * preset.xpFactor).rounded())
            return QuestItem(def: def, target: target, step: step, xp: xp)
        }
    }
}

// MARK: - Детерминированный генератор

func fnv1a(_ string: String) -> UInt32 {
    var hash: UInt32 = 2166136261
    for byte in string.utf8 {
        hash ^= UInt32(byte)
        hash = hash &* 16777619
    }
    return hash
}

struct SplitMix64 {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed &+ 0x9E3779B97F4A7C15
    }

    mutating func next() -> UInt64 {
        state = state &+ 0x9E3779B97F4A7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        z = z ^ (z >> 31)
        return z
    }

    mutating func nextUnit() -> Double {
        Double(next() >> 11) / 9007199254740992.0
    }
}
