import SwiftUI

/// Shown once every stop is unlocked. The pulsing seal and ticking clock show it's live, not a screenshot.
struct QuestCompleteView: View {
    let quest: Quest
    let finishedAt: Date

    @Environment(AccountStore.self) private var account
    @Environment(\.dismiss) private var dismiss

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

                Text("\(account.name ?? "You") found all \(quest.stops.count) stops on the \(quest.title) quest.")
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
    }
}

#Preview {
    QuestCompleteView(quest: .downtownLogan, finishedAt: .now)
        .environment(AccountStore())
}
