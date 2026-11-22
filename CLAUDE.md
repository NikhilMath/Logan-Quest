# Logan Quests: notes for Claude

## Commit and push every change

The user wants every change committed and pushed to `main` (they may call it "master"; the
branch is `main`). After each piece of work, commit it on its own with a clear message and run
`git push origin HEAD:main`. Don't leave work uncommitted, and don't lump unrelated changes into
one commit. If the push is rejected because `main` moved, `git pull --rebase origin main` and
push again. Never force-push.

## Project notes

- iPhone app (SwiftUI, iOS 18+), bundle ID `com.nikhilmath.loganquest`, team `A5SDFXT5VB`. The home-screen and App Store name is **Logan Quests**; the Xcode project and target are still called `LoganQuest`.
- Build with `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer` and `-allowProvisioningUpdates`. Put build output outside `~/Documents` (iCloud Drive can break code signing).
- Every push to `main` ships a TestFlight build through Xcode Cloud (README → TestFlight). `Tools/release.sh` uploads by hand if Xcode Cloud is down.
- Quests and stops live in `LoganQuest/Quest.swift`. Progress is keyed by quest and stop `id`: never rename one that has shipped.
- The current questions are practice placeholders. Don't invent "real" ones (plaque wording and so on); the user collects those on foot.
- Don't name a business or promise a reward in the app until the user says one is agreed.
- Progress: `ProgressStore` (UserDefaults, plus iCloud key-value storage while signed in with Apple). Resets are timestamps so they win over stale copies on other devices; keep `ProgressStore.merge` symmetric.
- Resetting progress must keep its two warnings (the `ResetProgressView` page, then the alert).
- Layout must keep working on iPhone Duo (wide inner screen): no `UIRequiresFullScreen`, all orientations, map beside the list in regular width.
