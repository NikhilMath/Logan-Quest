import SwiftUI

@main
struct LoganQuestApp: App {
    @State private var progress = ProgressStore()
    @State private var account = AccountStore()

    var body: some Scene {
        WindowGroup {
            QuestListView()
                .environment(progress)
                .environment(account)
                .task { await account.confirmStillSignedIn() }
                .onChange(of: account.isSignedIn, initial: true) { _, signedIn in
                    progress.setSavesToCloud(signedIn)
                }
        }
    }
}
