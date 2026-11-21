import SwiftUI

/// A stop's details and the question that unlocks it.
struct StopView: View {
    let stop: Stop
    let quest: Quest

    @Environment(ProgressStore.self) private var progress

    @Environment(\.dismiss) private var dismiss
    @State private var answer = ""
    @State private var wrongTries = 0
    @State private var justUnlocked = false
    @FocusState private var answerFocused: Bool

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    LabeledContent("Address", value: stop.address)
                    Link(destination: stop.directionsURL) {
                        Label("Walking Directions", systemImage: "figure.walk")
                    }
                }

                if progress.isFound(stop, in: quest) {
                    Section {
                        Label("Unlocked", systemImage: "checkmark.seal.fill")
                            .font(.title3.bold())
                            .foregroundStyle(.green)
                    }
                } else {
                    Section("Question") {
                        Text(stop.question)
                        TextField("Your answer", text: $answer)
                            .focused($answerFocused)
                            .autocorrectionDisabled()
                            .submitLabel(.done)
                            .onSubmit(check)
                        if wrongTries > 0 {
                            Text("Not quite. Look around and try again.")
                                .foregroundStyle(.red)
                        }
                    }
                    Section {
                        Button("Unlock", action: check)
                            .bold()
                            .disabled(answer.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                }
            }
            .navigationTitle(stop.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .sensoryFeedback(.success, trigger: justUnlocked)
            .sensoryFeedback(.error, trigger: wrongTries)
        }
    }

    private func check() {
        if progress.tryUnlock(stop, in: quest, with: answer) {
            answerFocused = false
            justUnlocked = true
            Task {
                try? await Task.sleep(for: .seconds(1))
                dismiss()
            }
        } else {
            wrongTries += 1
        }
    }
}
