import Foundation
import Observation

/// Which stops the player has found in each quest.
///
/// Always saved on the phone. While the player is signed in, it's also saved to iCloud
/// (their Apple account), so it follows them to a new or second iPhone.
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
    private(set) var savesToCloud = false

    @ObservationIgnored private let local: UserDefaults
    @ObservationIgnored private let cloud: NSUbiquitousKeyValueStore?
    @ObservationIgnored private var cloudObserver: NSObjectProtocol?
    private static let key = "progress.v1"

    init(local: UserDefaults = .standard, cloud: NSUbiquitousKeyValueStore? = .default) {
        self.local = local
        self.cloud = cloud
        records = Self.decode(local.data(forKey: Self.key))
        #if DEBUG
        if let count = DebugScreen.foundStops { setFoundForScreenshots(count) }
        #endif
    }

    #if DEBUG
    /// Debug builds only (the -LQFound launch argument): the first quest's first `count` stops,
    /// found a few minutes apart and ending now. Replaces that quest's progress.
    private func setFoundForScreenshots(_ count: Int) {
        guard let quest = Quest.all.first else { return }
        let stops = quest.stops.prefix(max(count, 0))
        var record = QuestRecord()
        for (index, stop) in stops.enumerated() {
            record.finds[stop.id] = Date.now.addingTimeInterval(Double(index + 1 - stops.count) * 8 * 60)
        }
        records[quest.id] = record
        save()
    }
    #endif

    // MARK: Reading

    func foundDate(_ stop: Stop, in quest: Quest) -> Date? { records[quest.id]?.finds[stop.id] }
    func isFound(_ stop: Stop, in quest: Quest) -> Bool { foundDate(stop, in: quest) != nil }
    func foundCount(in quest: Quest) -> Int { quest.stops.filter { isFound($0, in: quest) }.count }
    func isComplete(_ quest: Quest) -> Bool { foundCount(in: quest) == quest.stops.count }

    /// When the last stop was found, once every stop is.
    func finishedAt(_ quest: Quest) -> Date? {
        guard isComplete(quest) else { return nil }
        return quest.stops.compactMap { foundDate($0, in: quest) }.max()
    }

    var hasAnyProgress: Bool { Quest.all.contains { foundCount(in: $0) > 0 } }

    // MARK: Changing

    /// Marks the stop found if the answer is right. Returns whether it was.
    @discardableResult
    func tryUnlock(_ stop: Stop, in quest: Quest, with answer: String) -> Bool {
        guard stop.accepts(answer) else { return false }
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
        let cloudRecords = Self.decode(cloud.data(forKey: Self.key))
        let merged = Self.merge(records, cloudRecords)
        if merged != records {
            records = merged
            local.set(Self.encode(merged), forKey: Self.key)
        }
        if merged != cloudRecords {
            cloud.set(Self.encode(merged), forKey: Self.key)
        }
    }

    private func save() {
        let data = Self.encode(records)
        local.set(data, forKey: Self.key)
        if savesToCloud { cloud?.set(data, forKey: Self.key) }
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

    private nonisolated static func decode(_ data: Data?) -> [String: QuestRecord] {
        guard let data, let records = try? JSONDecoder().decode([String: QuestRecord].self, from: data) else { return [:] }
        return records
    }

    private nonisolated static func encode(_ records: [String: QuestRecord]) -> Data {
        (try? JSONEncoder().encode(records)) ?? Data()
    }
}
