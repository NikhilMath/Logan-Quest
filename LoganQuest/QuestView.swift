import MapKit
import SwiftUI

/// One quest: the map of its stops and the list to unlock them.
struct QuestView: View {
    let quest: Quest

    @Environment(ProgressStore.self) private var progress
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var selectedStopID: String?
    @State private var showingComplete = false
    @State private var showingPrize = false
    @State private var celebrateOnDismiss = false

    private var selectedStop: Binding<Stop?> {
        Binding(
            get: { quest.stops.first { $0.id == selectedStopID } },
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
            QuestCompleteView(quest: quest, finishedAt: progress.finishedAt(quest) ?? .now)
        }
        .fullScreenCover(isPresented: $showingPrize) {
            PrizeView(quest: quest)
        }
        .onChange(of: progress.isComplete(quest)) { _, isComplete in
            if isComplete { celebrateOnDismiss = true }
        }
        #if DEBUG
        .task {
            showingComplete = DebugScreen.current == "complete"
            showingPrize = DebugScreen.current?.hasPrefix("prize") == true
        }
        #endif
    }

    private var questMap: some View {
        Map(initialPosition: .region(quest.region), selection: $selectedStopID) {
            ForEach(Array(quest.stops.enumerated()), id: \.element.id) { index, stop in
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
            if showsMap {
                Section {
                    questMap
                        .frame(height: 300)
                        .listRowInsets(EdgeInsets())
                }
            }

            Section {
                WalkSummary(quest: quest)
                Button {
                    showingPrize = true
                } label: {
                    PrizeBoxRow(quest: quest, found: progress.foundCount(in: quest))
                }
                .foregroundStyle(.primary)
            }

            Section {
                ForEach(Array(quest.stops.enumerated()), id: \.element.id) { index, stop in
                    Button {
                        selectedStopID = stop.id
                    } label: {
                        StopRow(stop: stop, number: index + 1, found: progress.isFound(stop, in: quest))
                    }
                    .foregroundStyle(.primary)
                }
            } header: {
                Text("\(progress.foundCount(in: quest)) of \(quest.stops.count) stops found")
            } footer: {
                if !progress.isComplete(quest) {
                    Text("Walk to each stop and answer its question to unlock it.")
                }
            }

            if progress.isComplete(quest) {
                Section {
                    Button {
                        showingComplete = true
                    } label: {
                        Label("Show quest complete screen", systemImage: "checkmark.seal.fill")
                    }
                }
            }
        }
    }
}

/// How long the whole loop takes on foot.
private struct WalkSummary: View {
    let quest: Quest

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: "figure.walk")
                .font(.title2)
                .foregroundStyle(Color.accentColor)
                .frame(width: 32)
            VStack(alignment: .leading, spacing: 2) {
                Text("\(quest.walkingTime) walk · \(quest.walkingDistance)")
                    .font(.headline)
                if let start = quest.stops.first {
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

/// The prize box: locked until every stop is found.
private struct PrizeBoxRow: View {
    let quest: Quest
    let found: Int

    var body: some View {
        let unlocked = found == quest.stops.count
        HStack(spacing: 14) {
            PrizeBox(size: 34, isLocked: !unlocked)
                .frame(width: 32)
            VStack(alignment: .leading, spacing: 2) {
                Text(unlocked ? "Prize box unlocked!" : "Prize box")
                    .font(.headline)
                Text(unlocked
                     ? "Tap to open it."
                     : "Opens when you've found all \(quest.stops.count) stops.")
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
