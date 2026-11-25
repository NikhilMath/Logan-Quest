import MapKit
import SwiftUI

/// One quest: the difficulty picker, the map of its stops, its prize box and badges, and the
/// list to unlock its stops.
struct QuestView: View {
    let quest: Quest

    @Environment(ProgressStore.self) private var progress
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @AppStorage private var difficulty: Difficulty
    @State private var mapPosition: MapCameraPosition
    @State private var selectedStopID: String?
    @State private var showingComplete = false
    @State private var showingPrize = false
    @State private var celebrateOnDismiss = false

    init(quest: Quest) {
        self.quest = quest
        let difficulty = AppStorage(wrappedValue: quest.routes[0].difficulty, quest.difficultyKey)
        _difficulty = difficulty
        _mapPosition = State(initialValue: .region(quest.route(difficulty.wrappedValue).region))
    }

    /// The picked route, or the easiest open one when the picked one is coming soon.
    private var route: Route { quest.route(difficulty) }

    /// The picked route when it's coming soon: the screen says so in place of its map and stops.
    private var comingSoonRoute: Route? {
        quest.routes.first { $0.difficulty == difficulty && $0.isComingSoon }
    }

    private var selectedStop: Binding<Stop?> {
        Binding(
            get: { route.stops.first { $0.id == selectedStopID } },
            set: { selectedStopID = $0?.id }
        )
    }

    var body: some View {
        Group {
            if horizontalSizeClass == .regular {
                // Wide screens (iPhone Duo's inner screen, big iPhones in landscape): map beside the list.
                HStack(spacing: 0) {
                    questMap
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .padding([.leading, .vertical])
                    stopList(showsMap: false)
                        .frame(maxWidth: 420)
                }
                .background(Color(.systemGroupedBackground))
            } else {
                stopList(showsMap: true)
            }
        }
        .navigationTitle(quest.title)
        .sheet(item: selectedStop, onDismiss: {
            if celebrateOnDismiss {
                celebrateOnDismiss = false
                showingComplete = true
            }
        }) { stop in
            StopView(stop: stop, quest: quest)
        }
        .fullScreenCover(isPresented: $showingComplete) {
            QuestCompleteView(quest: quest, route: route, finishedAt: progress.finishedAt(route, in: quest) ?? .now)
        }
        .fullScreenCover(isPresented: $showingPrize) {
            PrizeView(quest: quest, route: route)
        }
        .onChange(of: progress.isComplete(route, in: quest)) { _, isComplete in
            // Only when a stop just unlocked, not when switching to a difficulty that's already done.
            if isComplete && selectedStopID != nil { celebrateOnDismiss = true }
        }
        .onChange(of: difficulty) {
            withAnimation { mapPosition = .region(route.region) }
        }
        #if DEBUG
        .task {
            showingComplete = DebugScreen.current == "complete"
            showingPrize = DebugScreen.current?.hasPrefix("prize") == true
            if DebugScreen.current == "stop" {
                // The first stop not found yet, so its riddle shows.
                selectedStopID = (route.stops.first { !progress.isFound($0, in: quest) } ?? route.stops[0]).id
            }
        }
        #endif
    }

    private var questMap: some View {
        Map(position: $mapPosition, selection: $selectedStopID) {
            // No pins for a difficulty that's coming soon (the map shows beside the list on wide screens).
            ForEach(Array((comingSoonRoute == nil ? route.stops : []).enumerated()), id: \.element.id) { index, stop in
                if progress.isFound(stop, in: quest) {
                    Marker(stop.name, systemImage: "checkmark", coordinate: stop.coordinate)
                        .tint(Color.green)
                        .tag(stop.id)
                } else {
                    Marker(stop.name, systemImage: "\(index + 1).circle", coordinate: stop.coordinate)
                        .tint(Color.accentColor)
                        .tag(stop.id)
                }
            }
        }
        .mapStyle(.standard(pointsOfInterest: .excludingAll))
    }

    private func stopList(showsMap: Bool) -> some View {
        List {
            if quest.hasDifficulties {
                Section {
                    Picker("Difficulty", selection: $difficulty) {
                        ForEach(quest.routes) { route in
                            Text(route.difficulty.title).tag(route.difficulty)
                        }
                    }
                    .pickerStyle(.segmented)
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                } footer: {
                    Text(difficultyFooter)
                }
            }

            if let comingSoonRoute {
                Section {
                    ComingSoonRow(difficulty: comingSoonRoute.difficulty, openNow: quest.openRoutes.map(\.difficulty))
                }
            } else {
                routeSections(showsMap: showsMap)
            }
        }
    }

    /// The picked route's map, walk, prize box, badges and stops.
    @ViewBuilder
    private func routeSections(showsMap: Bool) -> some View {
        if showsMap {
            Section {
                questMap
                    .frame(height: 300)
                    .listRowInsets(EdgeInsets())
            }
        }

        Section {
            WalkSummary(route: route)
            Button {
                showingPrize = true
            } label: {
                PrizeBoxRow(route: route, found: progress.foundCount(on: route, in: quest))
            }
            .foregroundStyle(.primary)
            QuestBadgesRow(quest: quest)
        }

        Section {
            ForEach(Array(route.stops.enumerated()), id: \.element.id) { index, stop in
                Button {
                    selectedStopID = stop.id
                } label: {
                    StopRow(stop: stop, number: index + 1, found: progress.isFound(stop, in: quest))
                }
                .foregroundStyle(.primary)
            }
        } header: {
            Text("\(progress.foundCount(on: route, in: quest)) of \(route.stops.count) stops found")
        } footer: {
            if !progress.isComplete(route, in: quest) {
                Text("Walk to each stop and solve its riddle to unlock it.")
            }
        }

        if progress.isComplete(route, in: quest) {
            Section {
                Button {
                    showingComplete = true
                } label: {
                    Label("Show quest complete screen", systemImage: "checkmark.seal.fill")
                }
            }
        }
    }

    /// "Easy has 5 stops, Medium 9 and Hard 15. A stop you find counts on every difficulty.",
    /// or "Easy has 5 stops. Medium and Hard are coming soon."
    private var difficultyFooter: String {
        let open = quest.openRoutes.enumerated().map { index, route in
            index == 0 ? "\(route.difficulty.title) has \(route.stops.count) stops" : "\(route.difficulty.title) \(route.stops.count)"
        }
        let soon = quest.routes.filter(\.isComingSoon).map(\.difficulty.title)
        return [
            "\(open.formatted(.list(type: .and))).",
            soon.isEmpty ? nil : "\(soon.formatted(.list(type: .and))) \(soon.count == 1 ? "is" : "are") coming soon.",
            open.count > 1 ? "A stop you find counts on every difficulty." : nil,
        ]
        .compactMap { $0 }
        .joined(separator: " ")
    }
}

/// In place of the map and stops when the picked difficulty isn't ready yet.
private struct ComingSoonRow: View {
    let difficulty: Difficulty
    /// The difficulties that can be played now.
    let openNow: [Difficulty]

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: "hourglass")
                .font(.system(size: 44))
                .foregroundStyle(Color.accentColor)
            Text("Coming Soon")
                .font(.title2.bold())
            Text("\(difficulty.title) isn't ready yet. Pick \(openNow.map(\.title).formatted(.list(type: .or))) to play now.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .accessibilityElement(children: .combine)
    }
}

/// How long the whole loop takes on foot.
private struct WalkSummary: View {
    let route: Route

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: "figure.walk")
                .font(.title2)
                .foregroundStyle(Color.accentColor)
                .frame(width: 32)
            VStack(alignment: .leading, spacing: 2) {
                Text("\(route.walkingTime) walk · \(route.walkingDistance)")
                    .font(.headline)
                if let start = route.stops.first {
                    Text("Visit the stops in order and you'll end up back at \(start.name).")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
    }
}

/// The prize box: locked until every stop on the route is found.
private struct PrizeBoxRow: View {
    let route: Route
    let found: Int

    var body: some View {
        let unlocked = found == route.stops.count
        HStack(spacing: 14) {
            PrizeBox(size: 34, isLocked: !unlocked)
                .frame(width: 32)
            VStack(alignment: .leading, spacing: 2) {
                Text(unlocked ? "Prize box unlocked!" : "Prize box")
                    .font(.headline)
                Text(unlocked
                     ? "Tap to open it."
                     : "Opens when you've found all \(route.stops.count) stops.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
    }
}

private struct StopRow: View {
    let stop: Stop
    let number: Int
    let found: Bool

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: found ? "checkmark.circle.fill" : "\(number).circle")
                .font(.title2)
                .foregroundStyle(found ? Color.green : Color.secondary)
                .frame(width: 32)
            VStack(alignment: .leading, spacing: 2) {
                Text(stop.name).font(.headline)
                Text(stop.address).font(.subheadline).foregroundStyle(.secondary)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
    }
}

#Preview {
    NavigationStack {
        QuestView(quest: .downtownLogan)
    }
    .environment(ProgressStore())
    .environment(AccountStore())
}
