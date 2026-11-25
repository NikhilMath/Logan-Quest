import SwiftUI

/// What the player has done in every quest and the badges they've earned, plus sign-in and resetting.
struct MyProgressView: View {
    @Environment(ProgressStore.self) private var progress
    @Environment(AccountStore.self) private var account
    @Environment(\.dismiss) private var dismiss
    @State private var confirmingSignOut = false
    @State private var debugShowsReset = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    if account.isSignedIn {
                        LabeledContent("Signed in", value: account.name ?? "With Apple")
                    } else {
                        AppleSignInButton()
                    }
                } header: {
                    Text("Account")
                } footer: {
                    Text(account.isSignedIn
                         ? "Your progress is saved to iCloud and shows up on any iPhone where you sign in."
                         : "Right now your progress is saved on this iPhone only.")
                }

                BadgesSection()

                ForEach(Quest.all) { quest in
                    QuestProgressSection(quest: quest)
                }

                if progress.hasAnyProgress {
                    Section {
                        NavigationLink {
                            ResetProgressView(target: .everything)
                        } label: {
                            Text("Reset All Progress").foregroundStyle(.red)
                        }
                    }
                }

                if account.isSignedIn {
                    Section {
                        Button("Sign Out", role: .destructive) { confirmingSignOut = true }
                    } footer: {
                        Text("Your progress stays on this iPhone but stops saving to iCloud.")
                    }
                }
            }
            .navigationTitle("My Progress")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .confirmationDialog("Sign out?", isPresented: $confirmingSignOut, titleVisibility: .visible) {
                Button("Sign Out", role: .destructive) { account.signOut() }
            } message: {
                Text("Your progress stays on this iPhone but stops saving to iCloud.")
            }
            .navigationDestination(isPresented: $debugShowsReset) {
                ResetProgressView(target: .everything)
            }
            #if DEBUG
            .task { debugShowsReset = DebugScreen.current == "reset" }
            #endif
        }
    }
}

private struct QuestProgressSection: View {
    let quest: Quest
    @Environment(ProgressStore.self) private var progress

    var body: some View {
        Section {
            ForEach(shownStops) { stop in
                let found = progress.foundDate(stop, in: quest)
                HStack {
                    Image(systemName: found == nil ? "circle" : "checkmark.circle.fill")
                        .foregroundStyle(found == nil ? Color.secondary : Color.green)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(stop.name)
                        if let only = onlyOn(stop) {
                            Text(only).font(.caption).foregroundStyle(.secondary)
                        }
                    }
                    Spacer()
                    if let found {
                        Text(found.formatted(date: .abbreviated, time: .omitted))
                            .foregroundStyle(.secondary)
                    }
                }
            }
            if progress.hasProgress(in: quest) {
                NavigationLink {
                    ResetProgressView(target: .quest(quest))
                } label: {
                    Text("Reset This Quest").foregroundStyle(.red)
                }
            }
        } header: {
            Text(quest.title)
        } footer: {
            Text(status)
        }
    }

    /// The stops on routes that can be played now, plus any found already, so stops only on a
    /// coming-soon route stay a surprise.
    private var shownStops: [Stop] {
        let open = Set(quest.openRoutes.flatMap(\.stops))
        return quest.allStops.filter { open.contains($0) || progress.isFound($0, in: quest) }
    }

    /// One line per difficulty: "Medium: 6 of 9 stops found." or "Medium: Coming soon."
    private var status: String {
        quest.routes.map { route in
            let level = quest.hasDifficulties ? "\(route.difficulty.title): " : ""
            if let finished = progress.finishedAt(route, in: quest) {
                return level + "Completed \(finished.formatted(date: .long, time: .shortened))."
            }
            if route.isComingSoon { return level + "Coming soon." }
            let found = progress.foundCount(on: route, in: quest)
            return level + (found > 0 ? "\(found) of \(route.stops.count) stops found." : "Not started yet.")
        }
        .joined(separator: "\n")
    }

    /// "Medium and Hard", for a stop that isn't on every difficulty's route.
    private func onlyOn(_ stop: Stop) -> String? {
        let difficulties = quest.difficulties(with: stop)
        guard difficulties.count < quest.routes.count else { return nil }
        return difficulties.map(\.title).formatted(.list(type: .and))
    }
}

/// The first warning before erasing progress: a page that spells out what will be lost.
/// Its button brings up the second warning.
struct ResetProgressView: View {
    enum Target: Hashable {
        case quest(Quest)
        case everything
    }

    let target: Target

    @Environment(ProgressStore.self) private var progress
    @Environment(AccountStore.self) private var account
    @Environment(\.dismiss) private var dismiss
    @State private var confirming = false

    private var quests: [Quest] {
        switch target {
        case .quest(let quest): [quest]
        case .everything: Quest.all
        }
    }

    private var foundStops: [(quest: Quest, stop: Stop)] {
        quests.flatMap { quest in
            quest.allStops.filter { progress.isFound($0, in: quest) }.map { (quest, $0) }
        }
    }

    private var title: String {
        switch target {
        case .quest(let quest): "Reset \(quest.title)?"
        case .everything: "Reset all progress?"
        }
    }

    var body: some View {
        List {
            Section {
                VStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(.orange)
                    Text(title)
                        .font(.title2.bold())
                    Text("Every stop below will be locked again, and you'll have to find them all over.")
                        .foregroundStyle(.secondary)
                    if account.isSignedIn {
                        Text("This also erases it from iCloud and your other devices.")
                            .foregroundStyle(.secondary)
                    }
                    if !progress.badges.isEmpty {
                        Text("Your badges stay.")
                            .foregroundStyle(.secondary)
                    }
                }
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            }

            Section("What gets erased") {
                if foundStops.isEmpty {
                    Text("Nothing. You haven't found any stops yet.")
                        .foregroundStyle(.secondary)
                }
                ForEach(foundStops, id: \.stop.id) { item in
                    VStack(alignment: .leading, spacing: 2) {
                        Text(item.stop.name)
                        if case .everything = target {
                            Text(item.quest.title).font(.caption).foregroundStyle(.secondary)
                        }
                    }
                }
            }

            Section {
                Button("Reset Progress", role: .destructive) { confirming = true }
                    .frame(maxWidth: .infinity)
                    .disabled(foundStops.isEmpty)
            }
        }
        .navigationTitle("Reset")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Are you sure?", isPresented: $confirming) {
            Button("Erase Progress", role: .destructive) {
                erase()
                dismiss()
            }
            Button("Keep My Progress", role: .cancel) {}
        } message: {
            Text("This can't be undone.")
        }
    }

    private func erase() {
        switch target {
        case .quest(let quest): progress.reset(quest)
        case .everything: progress.resetAll()
        }
    }
}

#Preview {
    MyProgressView()
        .environment(ProgressStore())
        .environment(AccountStore())
}
