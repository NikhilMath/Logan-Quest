import SwiftUI

/// A stop's details and the riddle that unlocks it.
struct StopView: View {
    let stop: Stop
    let quest: Quest

    @Environment(ProgressStore.self) private var progress

    @Environment(\.dismiss) private var dismiss
    @State private var answer = ""
    @State private var wrongTries = 0
    @State private var justUnlocked = false
    @State private var showingHint = false
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

                // Just unlocked: the riddle stays up, outlined green, until the sheet closes.
                if progress.isFound(stop, in: quest) && !justUnlocked {
                    Section {
                        Label("Unlocked", systemImage: "checkmark.seal.fill")
                            .font(.title3.bold())
                            .foregroundStyle(.green)
                    }
                } else {
                    Section("Riddle") {
                        Text(stop.riddle)
                        answerField
                        if justUnlocked {
                            Label("Unlocked!", systemImage: "checkmark.seal.fill")
                                .bold()
                                .foregroundStyle(.green)
                        } else if wrongTries > 0 {
                            Text("Not quite. Look around and try again.")
                                .foregroundStyle(.red)
                        }
                        if let hint = stop.hint {
                            if showingHint {
                                Label(hint, systemImage: "lightbulb.fill")
                                    .foregroundStyle(.secondary)
                            } else {
                                Button("Show Hint", systemImage: "lightbulb") {
                                    withAnimation { showingHint = true }
                                }
                            }
                        }
                    }
                    Section {
                        Button("Unlock", action: check)
                            .bold()
                            .disabled(answer.trimmingCharacters(in: .whitespaces).isEmpty || justUnlocked)
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

    /// The answer box: outlined red, turning green (with a checkmark) once what's typed is right.
    private var answerField: some View {
        let isRight = justUnlocked || stop.unlocks(with: answer)
        return HStack {
            TextField("Your answer", text: $answer)
                .focused($answerFocused)
                .autocorrectionDisabled()
                .submitLabel(.done)
                .onSubmit(check)
                .disabled(justUnlocked)
            if isRight {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                    .accessibilityLabel("Right answer")
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .overlay {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .strokeBorder(isRight ? Color.green : Color.red, lineWidth: 2)
        }
        .animation(.easeInOut(duration: 0.2), value: isRight)
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
