import SwiftUI

/// Shown once every stop is unlocked. The pulsing seal and ticking clock show it's live, not a screenshot.
struct QuestCompleteView: View {
    let quest: Quest
    let route: Route
    let finishedAt: Date

    @Environment(AccountStore.self) private var account
    @Environment(\.dismiss) private var dismiss
    @State private var showingPrize = false

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.08, green: 0.36, blue: 0.20), Color(red: 0.05, green: 0.50, blue: 0.48)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 24) {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 130))
                    .symbolEffect(.pulse)

                Text("Quest complete!")
                    .font(.largeTitle.bold())

                Text("\(account.name ?? "You") found all \(route.stops.count) stops on the \(level)\(quest.title) quest.")
                    .font(.title3)
                    .multilineTextAlignment(.center)

                VStack(spacing: 6) {
                    Text("Finished \(finishedAt.formatted(date: .abbreviated, time: .shortened))")
                    TimelineView(.periodic(from: .now, by: 1)) { context in
                        Text("It's \(context.date.formatted(date: .omitted, time: .standard))")
                            .monospacedDigit()
                    }
                }
                .font(.headline)
                .padding(.top, 8)

                Button {
                    showingPrize = true
                } label: {
                    HStack(spacing: 12) {
                        PrizeBox(size: 34)
                        Text("Open your prize box")
                            .font(.headline)
                    }
                    .padding(.leading, 16)
                    .padding(.trailing, 24)
                    .padding(.vertical, 10)
                    .background(Capsule().fill(.white))
                    .foregroundStyle(Color(red: 0.08, green: 0.36, blue: 0.20))
                }
                .padding(.top, 12)
            }
            .foregroundStyle(.white)
            .padding(32)
        }
        .overlay(alignment: .topTrailing) {
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.largeTitle)
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(.white)
            }
            .accessibilityLabel("Close")
            .padding()
        }
        .fullScreenCover(isPresented: $showingPrize) {
            PrizeView(quest: quest, route: route)
        }
    }

    /// "hard ", as in "the hard Downtown Logan quest", for a quest with difficulties.
    private var level: String {
        quest.hasDifficulties ? "\(route.difficulty.rawValue) " : ""
    }
}

#Preview {
    QuestCompleteView(quest: .downtownLogan, route: Quest.downtownLogan.routes[0], finishedAt: .now)
        .environment(ProgressStore())
        .environment(AccountStore())
}
