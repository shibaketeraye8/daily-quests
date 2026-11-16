import SwiftUI
import Foundation
import Combine

enum AppTab: String, CaseIterable {
    case quests
    case hero
    case journal

    var title: String {
        switch self {
        case .quests: return "Квесты"
        case .hero: return "Герой"
        case .journal: return "Журнал"
        }
    }

    var icon: String {
        switch self {
        case .quests: return "⚔️"
        case .hero: return "🛡️"
        case .journal: return "📜"
        }
    }
}

struct RootView: View {
    @EnvironmentObject private var game: GameState
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var pedometer = PedometerService()

    @State private var tab: AppTab = .quests
    @State private var showSettings = false
    @State private var showOnboarding = false

    private let ticker = Timer.publish(every: 30, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            Theme.background

            VStack(spacing: 0) {
                TopBar(onSettings: { showSettings = true })
                content
            }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                TabBar(selection: $tab)
            }

            VStack {
                Spacer()
                ToastStack()
                    .padding(.bottom, 82)
                    .padding(.horizontal, 16)
            }
            .allowsHitTesting(false)
        }
        .onAppear {
            game.refreshDay()
            if game.reminderEnabled {
                game.updateReminder()
            }
            pedometer.refresh { steps in
                game.syncSteps(steps)
            }
            if !game.onboarded {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                    showOnboarding = true
                }
            }
        }
        .onReceive(ticker) { _ in
            game.refreshDay()
            pedometer.refresh { steps in
                game.syncSteps(steps)
            }
        }
        .onChange(of: scenePhase) { phase in
            if phase == .active {
                game.refreshDay()
                pedometer.refresh(force: true) { steps in
                    game.syncSteps(steps)
                }
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsSheet()
        }
        .fullScreenCover(isPresented: $showOnboarding) {
            OnboardingSheet()
        }
        .environmentObject(pedometer)
    }

    @ViewBuilder
    private var content: some View {
        switch tab {
        case .quests:
            QuestsScreen()
        case .hero:
            HeroScreen(onSettings: { showSettings = true })
        case .journal:
            JournalScreen()
        }
    }
}

// MARK: - Верхняя панель

struct TopBar: View {
    @EnvironmentObject private var game: GameState
    let onSettings: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            levelBadge

            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Text(game.title)
                        .font(.display(16))
                        .foregroundStyle(Theme.goldLight)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)

                    Spacer(minLength: 4)

                    Text("🔥 \(game.currentStreak)")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Theme.gold)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Capsule().fill(Theme.gold.opacity(0.09)))
                        .overlay(Capsule().strokeBorder(Theme.gold.opacity(0.18), lineWidth: 1))
                }

                HStack(spacing: 8) {
                    ProgressTrack(value: game.level.progress, height: 7)
                    Text("\(fmt(game.level.cur)) / \(fmt(game.level.need))")
                        .font(.system(size: 10.5))
                        .foregroundStyle(Theme.muted)
                        .fixedSize()
                }
            }

            Button(action: onSettings) {
                Image(systemName: "gearshape")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(Theme.muted)
                    .frame(width: 38, height: 38)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color.white.opacity(0.04))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .strokeBorder(Color.white.opacity(0.07), lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
            LinearGradient(
                colors: [Theme.bg.opacity(0.99), Theme.bg.opacity(0.75)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .overlay(Rectangle().fill(Theme.line).frame(height: 1), alignment: .bottom)
    }

    private var levelBadge: some View {
        VStack(spacing: 0) {
            Text("\(game.level.level)")
                .font(.display(21, weight: .bold))
                .foregroundStyle(Theme.goldLight)
            Text("ур.")
                .font(.system(size: 8, weight: .semibold))
                .tracking(1)
                .foregroundStyle(Theme.goldDeep)
        }
        .frame(width: 44, height: 48)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Theme.gold.opacity(0.22), Theme.gold.opacity(0.04)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(Theme.lineStrong, lineWidth: 1)
        )
    }
}

// MARK: - Нижняя панель

struct TabBar: View {
    @Binding var selection: AppTab

    var body: some View {
        HStack(spacing: 0) {
            ForEach(AppTab.allCases, id: \.self) { tab in
                Button {
                    selection = tab
                } label: {
                    VStack(spacing: 2) {
                        Text(tab.icon)
                            .font(.system(size: 19))
                            .saturation(selection == tab ? 1 : 0)
                            .opacity(selection == tab ? 1 : 0.6)
                        Text(tab.title)
                            .font(.system(size: 9.5, weight: .medium))
                            .tracking(1)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 7)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(selection == tab ? Theme.gold.opacity(0.08) : Color.clear)
                    )
                    .foregroundStyle(selection == tab ? Theme.goldLight : Theme.muted)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 10)
        .padding(.top, 6)
        .background(Theme.bg.opacity(0.97))
        .overlay(Rectangle().fill(Theme.line).frame(height: 1), alignment: .top)
    }
}

// MARK: - Тосты

struct ToastStack: View {
    @EnvironmentObject private var game: GameState

    var body: some View {
        VStack(spacing: 8) {
            ForEach(game.toasts) { toast in
                Text(toast.text)
                    .font(.system(size: 12.5, weight: .semibold))
                    .foregroundStyle(toast.green ? Color(hex: 0xC9F7DD) : Theme.goldLight)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Theme.panel)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .strokeBorder(
                                (toast.green ? Theme.green : Theme.gold).opacity(0.45),
                                lineWidth: 1
                            )
                    )
                    .shadow(color: Color.black.opacity(0.5), radius: 16, x: 0, y: 10)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.82), value: game.toasts.count)
    }
}
