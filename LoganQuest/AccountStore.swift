import AuthenticationServices
import Foundation
import Observation

/// Sign in with Apple. Signing in turns on saving progress to iCloud and puts the player's
/// first name on the quest complete screen. There's no server: the Apple user ID and name
/// stay on the phone (and the name in the player's own iCloud). They're kept in the keychain
/// too, so deleting the app and downloading it again doesn't sign the player out.
@MainActor
@Observable
final class AccountStore {
    private(set) var userID: String?
    private(set) var name: String?
    var signInError: String?

    var isSignedIn: Bool { userID != nil }

    @ObservationIgnored private let local: UserDefaults
    @ObservationIgnored private let keychain: Keychain?
    @ObservationIgnored private let cloud: NSUbiquitousKeyValueStore?
    private static let userKey = "appleUserID"
    private static let nameKey = "playerName"

    init(
        local: UserDefaults = .standard,
        keychain: Keychain? = .standard,
        cloud: NSUbiquitousKeyValueStore? = .default
    ) {
        self.local = local
        self.keychain = keychain
        self.cloud = cloud
        // After a reinstall only the keychain has them; after updating from a build without the
        // keychain copy, only UserDefaults does. Saving puts them back in both.
        userID = keychain?.string(forKey: Self.userKey) ?? local.string(forKey: Self.userKey)
        name = keychain?.string(forKey: Self.nameKey) ?? local.string(forKey: Self.nameKey)
        save()
        NotificationCenter.default.addObserver(
            forName: ASAuthorizationAppleIDProvider.credentialRevokedNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated { self?.signOut() }
        }
    }

    func configure(_ request: ASAuthorizationAppleIDRequest) {
        request.requestedScopes = [.fullName]
    }

    func handle(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let authorization):
            guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else { return }
            userID = credential.user
            if let given = credential.fullName?.givenName, !given.isEmpty {
                name = given
                cloud?.set(given, forKey: Self.nameKey)
            } else {
                // Apple only shares the name the first time someone signs in to the app.
                name = name ?? cloud?.string(forKey: Self.nameKey)
            }
            signInError = nil
            save()
        case .failure(let error):
            if (error as? ASAuthorizationError)?.code == .canceled { return }
            signInError = "Make sure you're signed in to your Apple Account in Settings, then try again."
        }
    }

    /// Progress stays on this phone; it just stops saving to iCloud.
    func signOut() {
        userID = nil
        name = nil
        save()
    }

    /// Signs out if the player stopped using Sign in with Apple for this app (Settings → Apple Account).
    func confirmStillSignedIn() async {
        guard let userID else { return }
        let state = try? await ASAuthorizationAppleIDProvider().credentialState(forUserID: userID)
        if state == .revoked { signOut() }
    }

    private func save() {
        local.set(userID, forKey: Self.userKey)
        local.set(name, forKey: Self.nameKey)
        keychain?.set(userID, forKey: Self.userKey)
        keychain?.set(name, forKey: Self.nameKey)
    }
}
