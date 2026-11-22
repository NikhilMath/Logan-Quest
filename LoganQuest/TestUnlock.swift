import StoreKit

/// A shortcut for testing without walking downtown: typing "1" as any stop's answer unlocks it.
///
/// It works in builds run from Xcode (including the simulator) and in TestFlight builds, but
/// never in the App Store version, where it would let anyone open a prize box. TestFlight and
/// the App Store get the very same build, so this is decided when the app launches.
@MainActor
enum TestUnlock {
    static let code = "1"

    /// Debug builds always. Release builds once `checkBuild()` finds they came from TestFlight.
    private(set) static var isAvailable: Bool = {
        #if DEBUG
        true
        #else
        false
        #endif
    }()

    /// Whether the answer is the test code, in a build where the code works.
    static func accepts(_ answer: String) -> Bool {
        isAvailable && answer.trimmingCharacters(in: .whitespacesAndNewlines) == code
    }

    /// Called at launch. TestFlight builds are signed in the App Store's sandbox environment;
    /// App Store builds are signed in production, so the code stays off there.
    static func checkBuild() async {
        guard !isAvailable, let result = try? await AppTransaction.shared else { return }
        let environment = switch result {
        case .verified(let transaction), .unverified(let transaction, _): transaction.environment
        }
        isAvailable = environment == .sandbox || environment == .xcode
    }
}
