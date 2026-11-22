import Foundation
import Observation

/// Which stops the player has found in each quest, and the badges they've earned.
///
/// Always saved on the phone, in UserDefaults and in the keychain. The keychain copy stays when
/// the app is deleted, so progress comes back if the player downloads the app again. While the
/// player is signed in, it's also saved to iCloud (their Apple account), so it follows them to a
/// new or second iPhone. Badges are saved apart from the finds, and resetting never takes them away.
@MainActor
@Observable
final class ProgressStore {
    struct QuestRecord: Codable, Equatable {
        /// Stop ID → when it was found.
        var finds: [String: Date] = [:]
        /// When this quest was last reset. Finds from before then are erased everywhere, even
        /// if another device that hasn't heard about the reset still has them.
        var resetAt: Date?
    }

    /// Quest ID → that quest's progress.
    private(set) var records: [String: QuestRecord]
    /// Badge ID → when it was earned: when the last stop on its route was found. Never removed.
    private(set) var badges: [String: Date]
    private(set) var savesToCloud = false

    @ObservationIgnored private let local: UserDefaults
    @ObservationIgnored private let keychain: Keychain?
    @ObservationIgnored private let cloud: NSUbiquitousKeyValueStore?
    @ObservationIgnored private var cloudObserver: NSObjectProtocol?
    private static let key = "progress.v1"
    private static let badgesKey = "badges.v1"

    init(
        local: UserDefaults = .standard,
        keychain: Keychain? = .standard,
        cloud: NSUbiquitousKeyValueStore? = .default
    ) {
        self.local = local
        self.keychain = keychain
        self.cloud = cloud
        // After a reinstall only the keychain has it; after updating from a build without the
        // keychain copy, only UserDefaults does. Merging covers both and fills in the other.
        let saved: [String: QuestRecord] = Self.decode(local.data(forKey: Self.key))
        let kept: [String: QuestRecord] = Self.decode(keychain?.data(forKey: Self.key))
        records = Self.merge(saved, kept)
        let savedBadges: [String: Date] = Self.decode(local.data(forKey: Self.badgesKey))
        let keptBadges: [String: Date] = Self.decode(keychain?.data(forKey: Self.badgesKey))
        badges = Self.mergeBadges(savedBadges, keptBadges)
        if records != saved || records != kept { saveOnPhone(Self.encode(records), forKey: Self.key) }
        // Also gives badges for routes finished before there were badges.
        awardBadges()
        if badges != savedBadges || badges != keptBadges { saveOnPhone(Self.encode(badges), forKey: Self.badgesKey) }
        #if DEBUG
        if let difficulty = DebugScreen.difficulty, let quest = Quest.all.first {
            UserDefaults.standard.set(difficulty.rawValue, forKey: quest.difficultyKey)
        }
        if let count = DebugScreen.foundStops { setFoundForScreenshots(count) }
        #endif
    }

    #if DEBUG
    /// Debug builds only (the -LQFound launch argument): the first `count` stops on the first
    /// quest's chosen route, found a few minutes apart and ending now. Replaces that quest's
    /// progress, and all badges with just the ones those finds earn.
    private func setFoundForScreenshots(_ count: Int) {
        guard let quest = Quest.all.first else { return }
        let difficulty = UserDefaults.standard.string(forKey: quest.difficultyKey).flatMap(Difficulty.init)
        let stops = quest.route(difficulty).stops.prefix(max(count, 0))
        var record = QuestRecord()
        for (index, stop) in stops.enumerated() {
            record.finds[stop.id] = Date.now.addingTimeInterval(Double(index + 1 - stops.count) * 8 * 60)
        }
        records[quest.id] = record
        badges = [:]
        save()
        saveBadges()
    }
    #endif

    // MARK: Reading

    // Finds are saved per quest, not per route, so a stop found on one difficulty counts on all of them.

    func foundDate(_ stop: Stop, in quest: Quest) -> Date? { records[quest.id]?.finds[stop.id] }
    func isFound(_ stop: Stop, in quest: Quest) -> Bool { foundDate(stop, in: quest) != nil }
    func foundCount(on route: Route, in quest: Quest) -> Int { route.stops.filter { isFound($0, in: quest) }.count }
    func isComplete(_ route: Route, in quest: Quest) -> Bool { foundCount(on: route, in: quest) == route.stops.count }

    /// When the route's last stop was found, once every stop on it is.
    func finishedAt(_ route: Route, in quest: Quest) -> Date? {
        guard isComplete(route, in: quest) else { return nil }
        return route.stops.compactMap { foundDate($0, in: quest) }.max()
    }

    /// Whether any stop on any of the quest's routes has been found.
    func hasProgress(in quest: Quest) -> Bool { quest.allStops.contains { isFound($0, in: quest) } }
    var hasAnyProgress: Bool { Quest.all.contains(where: hasProgress) }

    // MARK: Badges

    /// Gives the badge for every finished route that doesn't have it yet, dated when the route's
    /// last stop was found. Returns whether there were any.
    @discardableResult
    private func awardBadges() -> Bool {
        var earned = badges
        for badge in Badge.all where earned[badge.id] == nil {
            earned[badge.id] = finishedAt(badge.route, in: badge.quest)
        }
        guard earned != badges else { return false }
        badges = earned
        return true
    }

    // MARK: Changing

    /// Marks the stop found if the answer is right (or is the test code). Returns whether it was.
    @discardableResult
    func tryUnlock(_ stop: Stop, in quest: Quest, with answer: String) -> Bool {
        guard stop.unlocks(with: answer) else { return false }
        if !isFound(stop, in: quest) {
            records[quest.id, default: QuestRecord()].finds[stop.id] = .now
            save()
        }
        return true
    }

    func reset(_ quest: Quest) {
        records[quest.id] = QuestRecord(resetAt: .now)
        save()
    }

    func resetAll() {
        let now = Date.now
        for id in Set(records.keys).union(Quest.all.map(\.id)) {
            records[id] = QuestRecord(resetAt: now)
        }
        save()
    }

    // MARK: iCloud

    /// Turned on while the player is signed in with Apple.
    func setSavesToCloud(_ enabled: Bool) {
        guard enabled != savesToCloud else { return }
        savesToCloud = enabled
        guard let cloud else { return }
        if enabled {
            cloudObserver = NotificationCenter.default.addObserver(
                forName: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
                object: cloud,
                queue: .main
            ) { [weak self] _ in
                MainActor.assumeIsolated { self?.syncWithCloud() }
            }
            cloud.synchronize()
            syncWithCloud()
        } else if let cloudObserver {
            NotificationCenter.default.removeObserver(cloudObserver)
            self.cloudObserver = nil
        }
    }

    /// Combines this phone's progress with what's in iCloud and saves the result to both.
    private func syncWithCloud() {
        guard savesToCloud, let cloud else { return }
        let cloudRecords: [String: QuestRecord] = Self.decode(cloud.data(forKey: Self.key))
        let merged = Self.merge(records, cloudRecords)
        if merged != records {
            records = merged
            saveOnPhone(Self.encode(merged), forKey: Self.key)
        }
        if merged != cloudRecords {
            cloud.set(Self.encode(merged), forKey: Self.key)
        }

        let cloudBadges: [String: Date] = Self.decode(cloud.data(forKey: Self.badgesKey))
        let mergedBadges = Self.mergeBadges(badges, cloudBadges)
        var badgesChanged = mergedBadges != badges
        if badgesChanged { badges = mergedBadges }
        // Finds from another device can finish a route here.
        if awardBadges() { badgesChanged = true }
        if badgesChanged { saveOnPhone(Self.encode(badges), forKey: Self.badgesKey) }
        if badges != cloudBadges {
            cloud.set(Self.encode(badges), forKey: Self.badgesKey)
        }
    }

    private func save() {
        let data = Self.encode(records)
        saveOnPhone(data, forKey: Self.key)
        if savesToCloud { cloud?.set(data, forKey: Self.key) }
        if awardBadges() { saveBadges() }
    }

    private func saveBadges() {
        let data = Self.encode(badges)
        saveOnPhone(data, forKey: Self.badgesKey)
        if savesToCloud { cloud?.set(data, forKey: Self.badgesKey) }
    }

    private func saveOnPhone(_ data: Data, forKey key: String) {
        local.set(data, forKey: key)
        keychain?.set(data, forKey: key)
    }

    /// Keeps every find from either side (earliest date wins), minus anything from before the latest reset.
    nonisolated static func merge(_ a: [String: QuestRecord], _ b: [String: QuestRecord]) -> [String: QuestRecord] {
        var result: [String: QuestRecord] = [:]
        for id in Set(a.keys).union(b.keys) {
            let x = a[id] ?? QuestRecord(), y = b[id] ?? QuestRecord()
            let resetAt = [x.resetAt, y.resetAt].compactMap { $0 }.max()
            var finds = x.finds.merging(y.finds) { min($0, $1) }
            if let resetAt { finds = finds.filter { $0.value > resetAt } }
            result[id] = QuestRecord(finds: finds, resetAt: resetAt)
        }
        return result
    }

    /// Keeps every badge from either side, each with the earliest date it was earned.
    nonisolated static func mergeBadges(_ a: [String: Date], _ b: [String: Date]) -> [String: Date] {
        a.merging(b) { min($0, $1) }
    }

    /// Empty when there's nothing saved yet (or it can't be read).
    private nonisolated static func decode<Key: Hashable & Decodable, Value: Decodable>(_ data: Data?) -> [Key: Value] {
        guard let data, let value = try? JSONDecoder().decode([Key: Value].self, from: data) else { return [:] }
        return value
    }

    private nonisolated static func encode(_ value: some Encodable) -> Data {
        (try? JSONEncoder().encode(value)) ?? Data()
    }
}
