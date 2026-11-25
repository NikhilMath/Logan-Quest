import SwiftUI

/// The badge for finishing one of a quest's routes. Players keep their badges for good, even
/// after resetting their progress, so they can always see what they've finished.
struct Badge: Identifiable, Hashable {
    let quest: Quest
    let route: Route

    /// How the badge is saved: the quest's `id` and the difficulty's raw value, so never
    /// change either once a build is out.
    var id: String { "\(quest.id).\(route.difficulty.rawValue)" }

    /// "Hard", or the quest's name for a quest without difficulties.
    var name: String { quest.hasDifficulties ? route.difficulty.title : quest.title }

    /// Every badge there is: each quest's routes, easiest first.
    static var all: [Badge] { Quest.all.flatMap(\.badges) }
}

extension Quest {
    var badges: [Badge] { routes.map { Badge(quest: self, route: $0) } }
}

/// A badge drawn as a seal with the quest's symbol on it: bronze, silver or gold by difficulty
/// once earned, gray with a lock until then.
struct BadgeSeal: View {
    let badge: Badge
    let earned: Bool
    var size: CGFloat = 64

    var body: some View {
        ZStack {
            Image(systemName: "seal.fill")
                .font(.system(size: size))
                .foregroundStyle(earned
                    ? AnyShapeStyle(LinearGradient(colors: colors, startPoint: .top, endPoint: .bottom))
                    : AnyShapeStyle(Color(.systemGray5)))
                .shadow(color: .black.opacity(earned ? 0.2 : 0), radius: 3, y: 2)
            Image(systemName: badge.quest.badgeSymbol)
                .font(.system(size: size * 0.38, weight: .semibold))
                .foregroundStyle(earned ? Color.white : Color(.systemGray2))
                .shadow(color: .black.opacity(earned ? 0.25 : 0), radius: 1, y: 1)
        }
        .overlay(alignment: .bottomTrailing) {
            if !earned {
                Image(systemName: "lock.fill")
                    .font(.system(size: size * 0.2, weight: .bold))
                    .foregroundStyle(.secondary)
                    .padding(size * 0.06)
                    .background(Circle().fill(Color(.secondarySystemGroupedBackground)))
            }
        }
        .frame(width: size * 1.15, height: size * 1.15)
        .accessibilityHidden(true)
    }

    /// Light to dark, top to bottom.
    private var colors: [Color] {
        guard badge.quest.hasDifficulties else { return [.questGoldLight, .questGoldDark] }
        switch badge.route.difficulty {
        case .easy: return [Color(red: 0.93, green: 0.69, blue: 0.45), Color(red: 0.66, green: 0.40, blue: 0.18)]
        case .medium: return [Color(red: 0.86, green: 0.88, blue: 0.91), Color(red: 0.52, green: 0.56, blue: 0.62)]
        case .hard: return [.questGoldLight, .questGoldDark]
        }
    }
}

/// Every badge, earned or not, grouped by quest. Shown in My Progress.
struct BadgesSection: View {
    @Environment(ProgressStore.self) private var progress

    var body: some View {
        Section {
            ForEach(Quest.all) { quest in
                VStack(alignment: .leading, spacing: 12) {
                    if Quest.all.count > 1 || quest.hasDifficulties {
                        Text(quest.title).font(.subheadline.weight(.semibold))
                    }
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 92), spacing: 8, alignment: .top)], spacing: 16) {
                        ForEach(quest.badges) { badge in
                            BadgeTile(badge: badge, earnedAt: progress.badges[badge.id])
                        }
                    }
                }
                .padding(.vertical, 8)
            }
        } header: {
            Text("Badges")
        } footer: {
            Text("\(earnedCount) of \(Badge.all.count) earned. Find every stop on a route to earn its badge. Badges stay even if you reset your progress.")
        }
    }

    private var earnedCount: Int { Badge.all.filter { progress.badges[$0.id] != nil }.count }
}

/// A quest's badges on its own screen, earned or not, so players see what each difficulty earns.
struct QuestBadgesRow: View {
    let quest: Quest
    @Environment(ProgressStore.self) private var progress

    var body: some View {
        let earned = quest.badges.filter { progress.badges[$0.id] != nil }
        HStack(spacing: 14) {
            Image(systemName: "rosette")
                .font(.title2)
                .foregroundStyle(Color.accentColor)
                .frame(width: 32)
            VStack(alignment: .leading, spacing: 2) {
                Text("Badges").font(.headline)
                Text(summary(earned: earned.count))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 8)
            HStack(alignment: .top, spacing: 6) {
                ForEach(quest.badges) { badge in
                    VStack(spacing: 2) {
                        BadgeSeal(badge: badge, earned: progress.badges[badge.id] != nil, size: 28)
                        if quest.hasDifficulties {
                            Text(badge.name)
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(.secondary)
                                .fixedSize()
                        }
                    }
                }
            }
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Badges")
        .accessibilityValue(spokenValue)
    }

    /// "1 of 3 earned"
    private func summary(earned: Int) -> String {
        if quest.badges.count == 1 { return earned == 1 ? "Earned" : "Not earned yet" }
        return "\(earned) of \(quest.badges.count) earned"
    }

    /// "Easy earned. Medium and Hard not earned yet."
    private var spokenValue: String {
        let earned = quest.badges.filter { progress.badges[$0.id] != nil }.map(\.name)
        let notYet = quest.badges.filter { progress.badges[$0.id] == nil }.map(\.name)
        return [
            earned.isEmpty ? nil : "\(earned.formatted(.list(type: .and))) earned.",
            notYet.isEmpty ? nil : "\(notYet.formatted(.list(type: .and))) not earned yet.",
        ]
        .compactMap { $0 }
        .joined(separator: " ")
    }
}

private struct BadgeTile: View {
    let badge: Badge
    let earnedAt: Date?

    var body: some View {
        VStack(spacing: 6) {
            BadgeSeal(badge: badge, earned: earnedAt != nil)
            VStack(spacing: 2) {
                Text(badge.name)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(earnedAt == nil ? .secondary : .primary)
                Text(earnedAt?.formatted(date: .abbreviated, time: .omitted)
                     ?? (badge.route.isComingSoon ? "Coming soon" : "Not yet"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityText)
    }

    private var accessibilityText: String {
        let name = badge.quest.hasDifficulties ? "\(badge.quest.title) \(badge.name)" : badge.name
        guard let earnedAt else {
            return "\(name) badge, \(badge.route.isComingSoon ? "coming soon" : "not earned yet")"
        }
        return "\(name) badge, earned \(earnedAt.formatted(date: .long, time: .omitted))"
    }
}

#Preview {
    List { BadgesSection() }
        .environment(ProgressStore())
}
