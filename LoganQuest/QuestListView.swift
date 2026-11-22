import AuthenticationServices
import SwiftUI

/// Home screen: every quest and how far along the player is.
struct QuestListView: View {
    @Environment(ProgressStore.self) private var progress
    @Environment(AccountStore.self) private var account
    @State private var showingMyProgress = false
    @State private var path: [Quest] = []

    var body: some View {
        NavigationStack(path: $path) {
            List {
                Section {
                    LogoHeader()
                }

                if !account.isSignedIn {
                    Section {
                        AppleSignInButton()
                    } header: {
                        Text("Save your progress")
                    } footer: {
                        Text("Sign in with Apple to keep your progress in iCloud, on any iPhone you use.")
                    }
                }

                Section {
                    ForEach(Quest.all) { quest in
                        NavigationLink(value: quest) {
                            QuestRow(quest: quest)
                        }
                    }
                } header: {
                    Text("Quests")
                } footer: {
                    Text("More quests are on the way.")
                }
            }
            // The logo header shows the name, so the bar stays empty here. The title is
            // still set so the back button in a quest reads "Logan Quests".
            .navigationTitle("Logan Quests")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: Quest.self) { quest in
                QuestView(quest: quest)
            }
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text(verbatim: "")
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingMyProgress = true
                    } label: {
                        Label("My Progress", systemImage: "person.crop.circle")
                    }
                }
            }
            .sheet(isPresented: $showingMyProgress) {
                MyProgressView()
            }
            #if DEBUG
            .task {
                // Debug builds only: open a screen at launch for screenshots, e.g.
                //   xcrun simctl launch booted com.nikhilmath.loganquest -LQScreen myProgress
                switch DebugScreen.current {
                case "myProgress", "reset": showingMyProgress = true
                case "quest", "stop", "complete", "prize", "prizeOpen": path = [Quest.all[0]]
                default: break
                }
            }
            #endif
        }
    }
}

#if DEBUG
enum DebugScreen {
    /// myProgress, reset, quest, stop, complete, prize or prizeOpen (from the -LQScreen launch argument).
    static var current: String? { UserDefaults.standard.string(forKey: "LQScreen") }
    /// How many of the first quest's stops to mark found at launch (the -LQFound launch argument),
    /// counted along the route for its chosen difficulty.
    static var foundStops: Int? { UserDefaults.standard.string(forKey: "LQFound").flatMap { Int($0) } }
    /// easy, medium or hard: picks that difficulty for the first quest at launch (the -LQDifficulty
    /// launch argument). It stays picked afterwards, as if chosen in the app.
    static var difficulty: Difficulty? { UserDefaults.standard.string(forKey: "LQDifficulty").flatMap(Difficulty.init) }
}
#endif

/// The app's logo (Old Main tower artwork) and name.
private struct LogoHeader: View {
    var body: some View {
        HStack(spacing: 16) {
            Image("Logo")
                .resizable()
                .scaledToFit()
                .frame(width: 84, height: 84)
                .clipShape(RoundedRectangle(cornerRadius: 19, style: .continuous))
                .shadow(color: .black.opacity(0.15), radius: 6, y: 3)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 4) {
                Text("Logan Quests")
                    .font(.largeTitle.bold())
                    .minimumScaleFactor(0.7)
                    .lineLimit(1)
                Text("Scavenger hunts around Logan, Utah")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
        .listRowBackground(Color.clear)
        .listRowInsets(EdgeInsets())
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
    }
}

private struct QuestRow: View {
    let quest: Quest
    @Environment(ProgressStore.self) private var progress
    /// The difficulty picked on the quest's own screen.
    @AppStorage private var difficulty: Difficulty

    init(quest: Quest) {
        self.quest = quest
        _difficulty = AppStorage(wrappedValue: quest.routes[0].difficulty, quest.difficultyKey)
    }

    private var route: Route { quest.route(difficulty) }

    var body: some View {
        let done = progress.isComplete(route, in: quest)
        HStack(spacing: 14) {
            Image(systemName: done ? "checkmark.seal.fill" : "map.fill")
                .font(.title2)
                .foregroundStyle(done ? Color.green : Color.accentColor)
                .frame(width: 34)
            VStack(alignment: .leading, spacing: 3) {
                Text(quest.title).font(.headline)
                Text(route.summary).font(.subheadline).foregroundStyle(.secondary)
                Text("\(Image(systemName: "figure.walk")) \(route.walkingTime) walk · \(route.walkingDistance)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(status)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(done ? Color.green : Color.secondary)
            }
        }
        .padding(.vertical, 4)
    }

    /// "Medium · 6 of 9 stops found"
    private var status: String {
        let level = quest.hasDifficulties ? "\(route.difficulty.title) · " : ""
        if let finished = progress.finishedAt(route, in: quest) {
            return level + "Completed \(finished.formatted(date: .abbreviated, time: .omitted))"
        }
        let found = progress.foundCount(on: route, in: quest)
        return level + (found > 0 ? "\(found) of \(route.stops.count) stops found" : "\(route.stops.count) stops · Not started")
    }
}

/// The Sign in with Apple button, wired to the account store and styled for light and dark mode.
struct AppleSignInButton: View {
    @Environment(AccountStore.self) private var account
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        @Bindable var account = account
        SignInWithAppleButton(.signIn, onRequest: account.configure, onCompletion: account.handle)
            .signInWithAppleButtonStyle(colorScheme == .dark ? .white : .black)
            .frame(height: 50)
            .listRowInsets(EdgeInsets())
            .listRowBackground(Color.clear)
            .alert("Couldn't Sign In", isPresented: Binding(
                get: { account.signInError != nil },
                set: { if !$0 { account.signInError = nil } }
            )) {
                Button("OK") {}
            } message: {
                Text(account.signInError ?? "")
            }
    }
}

#Preview {
    QuestListView()
        .environment(ProgressStore())
        .environment(AccountStore())
}
