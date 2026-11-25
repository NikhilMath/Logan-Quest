# Logan Quest: notes for Claude

This file is the whole playbook: setting up a Mac, building, running, committing, pushing and
shipping. It's used on more than one computer:

- **Nikhil** owns the project (GitHub `NikhilMath`, the Apple developer account, App Store
  Connect).
- **Forrest**, Nikhil's friend, works on his own Mac with his own Claude Code. His GitHub
  account is `fso5`, and he's already a collaborator with push access.

If `gh api user --jq .login` prints `fso5`, you're on Forrest's Mac. On a Mac that isn't set up
yet, start with **Setting up a new Mac** below and walk the person through it one step at a
time. When something here changes, update this file (and the README, if it says the same thing)
in the same commit.

## Rules

### Commit and push every change

Every change gets committed and pushed to `main` (people may call it "master"; the branch is
`main`). This goes for Forrest too, not only Nikhil.

1. Before starting, get the latest: `git pull --rebase origin main`.
2. Build for the simulator (below) and make sure it succeeds. For anything visible, look at it
   in the simulator too.
3. Commit each piece of work on its own with a clear, short message in the imperative, the way
   the log reads ("Add Thatcher-Young Mansion as a fifth Downtown Logan stop"). Don't lump
   unrelated changes into one commit, and don't leave work uncommitted.
4. `git push origin HEAD:main`. This works from any branch, including a Claude Code worktree
   branch.
5. If the push is rejected because `main` moved (someone else pushed), run
   `git pull --rebase origin main`, fix any conflicts, build again, and push again.
   **Never force-push.**

Every push to `main` ships a TestFlight build (see **Shipping to TestFlight**), so don't push
something that doesn't build.

### Project rules

- iPhone app (SwiftUI, iOS 18+), bundle ID `com.nikhilmath.loganquest`, Apple team
  `A5SDFXT5VB`. The home-screen and App Store name is **Logan Quest** (Nikhil renamed it from "Logan
  Quests" on 2026-11-22; the SKU stays `loganquests`, since Apple doesn't let a SKU change).
  Everything that shows the name, in the app, its images and the docs, says "Logan Quest" (or
  "LOGAN QUEST"), never the plural. The Xcode project and target are
  still called `LoganQuest`. Don't change the team, bundle ID or entitlements in a
  commit, even to get a build working on another Mac.
- Quests and stops live in `LoganQuest/Quest.swift`. Progress is keyed by quest and stop `id`:
  never rename one that has shipped.
- The questions are practice placeholders, except the Logan Tabernacle's ("What year was this
  building erected?", answer 1891), which Nikhil gave on 2026-11-22. Don't invent "real" ones
  (plaque wording and so on). Nikhil collects those on foot.
- Downtown Logan's Medium and Hard are coming soon (Nikhil asked on 2026-11-25): their routes
  have `isComingSoon: true`, so picking one shows a "Coming Soon" panel instead of its map,
  stops and prize box, and everywhere else uses Easy. Keep them that way until Nikhil says one
  is ready; to open it, delete its `isComingSoon: true` and update the App Store drafts in
  `AppStore/`, which leave Medium and Hard out of the listing for now.
- Downtown Logan's prize box holds a generic coupon that reads "Your Business" and "Your offer
  here", so Nikhil can pitch it to more than one Logan business (he asked for this on
  2026-11-21, replacing the Handles coupon). Don't put in a business's name, offer or terms
  until Nikhil says which business signed on and what was agreed, and don't add rewards unasked.
  The pitch coupon (`Partners/coupon.png`) and `CouponView` show the same thing: keep them
  matching.
- Progress: `ProgressStore` (UserDefaults, plus iCloud key-value storage while signed in with
  Apple). Resets are timestamps so they win over stale copies on other devices. Keep
  `ProgressStore.merge` symmetric.
- Badges: `ProgressStore.badges`, one per quest route (`Badge.swift`), saved apart from the
  finds under `badges.v1`. Resetting must never take a badge away; that's the point of them
  (Nikhil asked for this on 2026-11-21). Badge IDs are the quest `id` plus the difficulty's raw
  value, so never rename a `Difficulty` case. Keep `ProgressStore.mergeBadges` symmetric too.
- Deleting the app and downloading it again must keep everything. Progress, badges and the sign-in
  (`AccountStore`) are also saved in the keychain (`Keychain.swift`), which iOS keeps when an
  app is deleted. Anything new that gets saved needs a keychain copy too.
- Privacy: no tracking, analytics, ads or server, and nothing leaves the phone except to the
  player's own iCloud. `LoganQuest/PrivacyInfo.xcprivacy` (the privacy manifest Apple reads on
  upload) says so and declares the one "required reason" API the app uses, UserDefaults
  (`CA92.1`). If code starts using another API on Apple's list (file timestamps, system boot
  time, disk space, active keyboards) or sends data anywhere, update the manifest,
  `AppStore/privacy.md` and the App Privacy answers in `AppStore/listing.md` in the same commit.
- Resetting progress must keep its two warnings (the `ResetProgressView` page, then the alert).
- Layout must keep working on iPhone Duo (wide inner screen): no `UIRequiresFullScreen`, all
  orientations, map beside the list in regular width. Nikhil's own test phone is an iPhone Duo.
- Keep build output out of iCloud-synced folders (Desktop and Documents). iCloud Drive tags
  files with Finder metadata that breaks code signing. Xcode's default DerivedData folder
  (`~/Library/Developer/Xcode/DerivedData`) and `/tmp` are fine.

## Setting up a new Mac

Do these in order. Steps marked **(they run it)** need the person's Mac password or a sign-in
in a window, so give them the command and wait for them to say it's done.

1. **Xcode.** Install the newest Xcode from the Mac App Store. Nikhil builds with Xcode 27, but
   anything from Xcode 16 up should build the project (that's the oldest Xcode that reads its
   project format), though only Xcode 27 has actually been tried. Xcode 16 needs macOS
   14.5 or later; check with `sw_vers -productVersion`. If the App Store says the newest Xcode
   needs a newer macOS, either update macOS or download the newest Xcode that this macOS
   supports from https://developer.apple.com/download/all (any Apple Account can sign in).
   Older Xcodes may not have an iPhone Duo simulator. Open Xcode once and let it install its
   components. Then **(they run it)**:

   ```bash
   sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
   sudo xcodebuild -license accept
   ```

   If no iPhone simulators show up in `xcrun simctl list devices available`, download the iOS
   platform (a few GB): `xcodebuild -downloadPlatform iOS`.

2. **Homebrew** (if `brew` isn't installed) **(they run it)**: paste the install command from
   https://brew.sh into Terminal, then follow the "Next steps" it prints.

3. **GitHub CLI and sign-in.**

   ```bash
   brew install gh
   gh auth login          # (they run it) GitHub.com, HTTPS, log in with a web browser
   gh auth setup-git
   ```

4. **Git identity.** Ask the person for the name and email they want on commits (don't guess
   them), then set `git config --global user.name "…"` and `git config --global user.email "…"`.

5. **Get the code.** The repo is public, so anyone can clone it. Clone it somewhere outside
   Desktop and Documents:

   ```bash
   mkdir -p ~/Developer && cd ~/Developer
   git clone https://github.com/NikhilMath/Logan-Quest.git
   cd Logan-Quest
   ```

6. **Push access.** Check with `gh repo view NikhilMath/Logan-Quest --json viewerPermission`:
   `WRITE` or `ADMIN` means they can push. Forrest (`fso5`) already has `WRITE`, so if it
   says otherwise on his Mac, `gh auth login` was done with a different GitHub account. Anyone
   else needs Nikhil to add their GitHub username under the repo's Settings → Collaborators →
   Add people, then accepts the invite from the email or at
   https://github.com/NikhilMath/Logan-Quest/invitations.

7. **Python tools** (only for redrawing the coupon or the icon):
   `python3 -m pip install --user pillow`.

8. **Check it all works:** build for the simulator and launch it (next section). If that
   works, the Mac is ready for everyday work.

### Apple access (for running on a real iPhone)

The simulator needs no Apple access at all. A real iPhone needs one of these:

- **TestFlight as an internal tester.** Nikhil adds the person in App Store Connect → Users and
  Access → **+** (role Developer is enough), then under Logan Quest → TestFlight → **Me** →
  Testers → **+**. They install TestFlight from the App Store, sign in with that Apple Account,
  and tap **Install**. Every push to `main` shows up there 15–30 minutes later.
- **The public TestFlight link**: https://testflight.apple.com/join/ynz9DXQa (QR code in
  `TestFlight/qr.png`). Anyone can join, but it only offers builds that Nikhil uploaded with
  `Tools/release.sh` and that passed Beta App Review, so it lags behind `main`.
- **Running straight from Xcode** onto a plugged-in iPhone needs the person's Apple Account on
  team `A5SDFXT5VB` (App Store Connect user, as above) and signed in under Xcode → Settings →
  Accounts. If Nikhil's developer account is an individual one rather than an organization,
  added users can't sign builds, so use TestFlight instead. Never switch the project to a
  personal team to get around this: Sign in with Apple and iCloud need the real team.

## Building and running

Use the commands with `DEVELOPER_DIR` as written; they work even if `xcode-select` points at the
Command Line Tools instead of Xcode.

**Build for the simulator** (works on any Mac, no Apple account or team needed):

```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild -project LoganQuest.xcodeproj -scheme LoganQuest -destination 'generic/platform=iOS Simulator' -derivedDataPath /tmp/LoganQuest-DD build -quiet
```

**Run it in a simulator** and take a screenshot. If your session has an iOS Simulator tool, you
can use that instead. Otherwise:

```bash
export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
xcrun simctl boot "iPhone 17"            # any name from: xcrun simctl list devices available
open -a Simulator                        # only if the person wants to watch
xcrun simctl install "iPhone 17" /tmp/LoganQuest-DD/Build/Products/Debug-iphonesimulator/LoganQuest.app
xcrun simctl launch --terminate-running-process "iPhone 17" com.nikhilmath.loganquest
xcrun simctl io "iPhone 17" screenshot /tmp/loganquest.png
```

Debug builds can open straight to a screen: add `-LQScreen <name>` to the `launch` line, where
`<name>` is `myProgress`, `reset`, `quest`, `stop` (the first stop not found yet), `complete`,
`prize` or `prizeOpen` (the prize box opening by itself). Add `-LQFound <n>` to start with the
first quest's first `n` stops found (`0` clears it; it replaces that simulator's saved progress,
and its badges with just the ones those finds earn).
Deleting the app from a simulator doesn't clear its progress, badges or sign-in (the keychain keeps
them): use `-LQFound 0` and the Sign Out button instead. Add `-LQDifficulty easy`, `medium` or
`hard` to pick Downtown Logan's difficulty first (it stays picked); `-LQFound` counts along that
difficulty's route, or Easy's while that difficulty is coming soon. Check layout changes on the **iPhone Duo** simulator too, if this Xcode has
one, in both orientations.

To unlock a stop without its real answer, type `1`. That works in Xcode and TestFlight builds
but never in the App Store version (`TestUnlock`, checked at launch); keep it that way, since it
would let anyone open a prize box.

On a simulator outside team `A5SDFXT5VB`, Sign in with Apple and iCloud sync may not work.
Everything else does.

**In Xcode instead:** open `LoganQuest.xcodeproj`, pick a simulator or a plugged-in iPhone at
the top, press ⌘R.

**On a Mac signed in to the team** (Nikhil's), device builds also need
`-allowProvisioningUpdates` so Xcode can make the signing profiles itself.

## Shipping to TestFlight

The app is set up in App Store Connect as **Logan Quest** (SKU `loganquests`).

- **Automatic:** Xcode Cloud's **Default** workflow archives `main` on every push and sends the
  build to the internal TestFlight group **Me**, usually 15–30 minutes after the push. A newer
  push cancels a build that's still running. Xcode Cloud numbers the builds itself. Nikhil
  manages the workflow in App Store Connect → Xcode Cloud (failed builds show there and get
  emailed to him). Nothing in the repo needs changing for this.
- **Version:** every build goes up by .1. `ci_scripts/ci_pre_xcodebuild.sh` (Xcode Cloud runs
  it before each build) turns the build number into the version: build 21 is 1.1, build 22 is
  1.2, and 1.9 is followed by 1.10. Builds 20 and earlier all shipped as 1.0. Nothing is
  committed for it, so leave `MARKETING_VERSION` in the project at 1.0. A cancelled build still
  uses up its number, so TestFlight can skip a version. If Nikhil resets the build number in
  Xcode Cloud, change `first_build` in the script to match.
- **By hand**, if Xcode Cloud is down, or to put a build in the public group:
  `Tools/release.sh <version>`, where the version is .1 above the newest build in TestFlight
  (`Tools/release.sh 1.7` after 1.6). It archives, signs with the Apple account signed in to
  Xcode, and uploads, and Xcode picks the next build number. The next Xcode Cloud build still
  takes its version from its own build number. Only a Mac signed in to the team with permission
  to upload can run it, which
  in practice means Nikhil's. To reach the public link, Nikhil then adds the build under
  TestFlight → **Public** → Builds → **+**, and it waits for Beta App Review.

## Everyday tasks

- **Add a quest:** add a `Quest` to `Quest.all` in `LoganQuest/Quest.swift`, with its `routes`,
  a `prize` (a badge, `.badge(symbol:)` with an SF Symbol, or a business's coupon,
  `.coupon(…)`) and a `badgeSymbol` (an SF Symbol for the badges its routes earn). Only add a coupon for a business Nikhil has said yes to. Each route is a
  difficulty (easy, medium, hard) with its stops in walking order; one route means no difficulty
  picker. Routes share `Stop` values, so a stop found on one difficulty counts on the others.
  Downtown Logan has all three: Medium is Easy plus 4 stops, Hard is Medium plus 6 (Medium and
  Hard are coming soon for now; a route's `isComingSoon` does that). To get each
  stop's address and coordinates and a loop's walking time from Apple Maps:

  ```bash
  DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer swift Tools/walk_time.swift "Logan Tabernacle" "Cache Valley Visitors Bureau" "Umbrella Alley Logan" "Thatcher Young Mansion" "Ellen Eccles Theatre"
  ```

- **Change a stop's question or answers:** edit it in `Quest.swift`. List every spelling to
  accept in `acceptedAnswers`. Matching already ignores case, punctuation, accents and a leading
  "the". Only put in real questions that Nikhil (or whoever walked there) gave you.
- **Give a stop a hint:** set its `hint` in `Quest.swift` (leave it out for none). It stays
  hidden under the question until the player taps **Show Hint**. Same rule: only real facts
  someone gave you, and never one that gives the answer away. No stop has a hint right now (the
  Tabernacle's "finished being built in 1891" became its question's answer).
- **Put a business on the coupon** (only once Nikhil says who signed on and gives the agreed
  wording): set `business` and `offer`, and any new `terms` or `lastDay`, in the `prize` in
  `Quest.swift` (and its `title` and `detail`), make the same changes in
  `Partners/make_coupon.py`, then redraw the pitch coupon:
  `python3 Partners/make_coupon.py Partners/coupon.png`.
- **Redraw the icon:** edit `Tools/icon/make_icon.py`, then run the two commands in its
  docstring (the second copies it into the `Logo` image set used by the home-screen header).
- **Redraw the TestFlight QR code** for a different link (it checks the new image scans):
  `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer swift Tools/make_qr.swift <link> TestFlight/qr.png`.
- **Retake the App Store screenshots:** `Tools/screenshots.sh` (any Mac, no Apple account). It
  saves five 1320×2868 PNGs in `AppStore/Screenshots`; Nikhil uploads them in App Store Connect →
  Distribution → App Previews and Screenshots. Retake them whenever a pictured screen changes.
- **Before launch** (open items): real questions, checking the map pins, timing the walk, a
  business and offer for the coupon, then retaking the screenshots and filling in the App
  Store listing. The README's "Before launch" section has the details.
- **App Store listing:** the drafts are in `AppStore/` (`listing.md`, `review-notes.md`, and the
  public `privacy.md` and `support.md` that the Privacy Policy and Support URLs point to).
  When a change affects what they say (what the app saves, the stops, walking times, the
  coupon, the test unlock), update them in the same commit. The privacy policy must stay true
  to what the app actually saves and sends.

## When something goes wrong

- **"xcodebuild requires Xcode, but active developer directory … is a command line tools
  instance":** add `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer` to the command,
  or run the `xcode-select` line from setup step 1.
- **"No Account for Team A5SDFXT5VB" or "No profiles for com.nikhilmath.loganquest":** this Mac
  isn't signed in to Nikhil's team. Build for the simulator, or see **Apple access**. Don't
  change the team in the project.
- **Code signing fails with "resource fork, Finder information, or similar detritus":** the
  build output is in an iCloud-synced folder. Build with `-derivedDataPath /tmp/LoganQuest-DD`,
  or move the clone out of Desktop and Documents.
- **Push fails with 403 or "Permission denied":** `gh auth setup-git` wasn't run, or the
  GitHub account signed in isn't a collaborator. Check `gh api user --jq .login`: on Forrest's
  Mac it should print `fso5`. Anyone else needs Nikhil to add them (setup step 6).
- **The simulator shows an older build than the code:** another Claude Code worktree on this Mac
  built into the same `/tmp/LoganQuest-DD`. Build with your own `-derivedDataPath`, like
  `/tmp/LoganQuest-DD-<worktree name>`, and install from there.
- **Push rejected as "non-fast-forward" or "fetch first":** someone else pushed.
  `git pull --rebase origin main`, build, push again. Never force-push.
- **No build on TestFlight 30+ minutes after a push:** check App Store Connect → Xcode Cloud →
  Builds (Nikhil's account) for a failed or cancelled build.
