# Logan Quest

An iPhone app of scavenger hunts around Logan, Utah. Players walk to each stop on a quest, answer a question only someone standing there would know, and unlock it. Finding every stop brings up a "Quest complete" screen with a ticking clock, so it can't be passed off as a screenshot.

## What's in the app

- **Quests** (home screen): every quest, how long it takes to walk, and how far along you are. Downtown Logan is the first one; add more in `LoganQuest/Quest.swift`.
- **A quest**: a map of its numbered stops and the list to unlock them. Each quest is a loop: visit the stops in order and you end up back at the first one. Each stop has walking directions and its question, and it can have a hint that stays hidden until the player taps Show Hint. The answer box is outlined red and turns green (with a checkmark) as soon as what's typed is right. A quest can come in difficulties (Easy, Medium, Hard), picked at the top of its screen. Each harder one keeps the easier one's stops and adds more, and a stop found on one difficulty counts on all of them.
- **Downtown Logan**: three difficulties, each a loop from the Logan Tabernacle and back. Walking times are Apple Maps' estimates, not counting time spent at each stop.
  - **Easy** (5 stops, about 20 minutes, 0.9 mi): Logan Tabernacle → Old Cache County Courthouse → Umbrella Alley → Thatcher-Young Mansion → Ellen Eccles Theatre.
  - **Medium** (9 stops, about 30 minutes, 1.4 mi) adds St. John's Episcopal Church, the Cache Pioneer Museum, Logan Library and the Caine Lyric Theatre: Tabernacle → St. John's → Pioneer Museum → Library → Courthouse → Umbrella Alley → Caine Lyric → Thatcher-Young → Ellen Eccles.
  - **Hard** (15 stops, about 70 minutes, 3.3 mi) adds Logan City Hall, First Presbyterian Church, the Utah Theatre, Pioneer Park, Merlin Olsen Park and the Logan Utah Temple: Tabernacle → Pioneer Museum → Courthouse → Library → City Hall → First Presbyterian → Umbrella Alley → Caine Lyric → Utah Theatre → Thatcher-Young → Ellen Eccles → Pioneer Park → Merlin Olsen Park → Temple → St. John's.
- **Prize box**: every quest has one, shown under the walking time. It stays locked until every stop on the chosen difficulty is found. Then a tap sends the lid flying and the prize rises out, with spinning rays and a ticking clock so it can't be passed off as a screenshot either. The "Quest complete" screen has a button to it too. Downtown Logan's prize is a coupon to show at a business's counter, the same on every difficulty. For now it's a generic one ("Your Business", "Your offer here") for pitching to Logan businesses. It's good through Dec 31, 2026 (Logan time) and turns gray and says "Expired" after that.
- **Testing shortcut**: typing `1` as any stop's answer unlocks it, so you can test without walking downtown. It works in builds from Xcode (the simulator too) and from TestFlight, never in the App Store version. The app checks which one it is at launch (`LoganQuest/TestUnlock.swift`).
- **My Progress** (person button, top right): your badges, every stop you've found and when, plus resetting. Resetting asks twice: a page that lists exactly what will be erased, then an "Are you sure?" alert.
- **Badges**: finishing a route earns its badge (Downtown Logan has bronze Easy, silver Medium and gold Hard). Each quest's screen shows its badges under the prize box, and My Progress shows every badge there is, with the ones not earned yet grayed out and locked, so you can compare what you have. Badges are kept for good: resetting your progress never takes them away. They're saved like progress (on the phone, in the keychain, and in iCloud while signed in).
- **Sign in with Apple** (optional): saves progress to iCloud so it follows you to another iPhone, and puts your first name on the "Quest complete" screen. Without signing in, progress stays on that phone. There's no server: progress lives in iCloud key-value storage on the player's own Apple account.
- **Deleting the app** and downloading it again keeps everything: progress, badges and the sign-in are also saved in the phone's keychain, which iOS keeps when an app is deleted.
- **iPhone Duo and wide screens**: the map sits beside the list instead of above it. The app supports every orientation and doesn't require full screen, so it fills the Duo's inner screen.

## Before launch

- **Real questions.** 14 of the 15 questions in `LoganQuest/Quest.swift` are still practice placeholders ("what's this building called?"); the Logan Tabernacle's (what year it was erected: 1891) is real. Walk downtown and replace each with something only someone there would know, like what's carved on a plaque. List every spelling you'd accept in `acceptedAnswers`; matching already ignores case, punctuation, accents and a leading "the".
- **Check the pins.** Coordinates came from Apple Maps. The old courthouse pin is the Cache Valley Visitors Bureau address (199 N Main St). Apple Maps has no street address for Pioneer Park, so its stop says "Pioneer Park Walkway".
- **Walk the loops.** The 18, 30 and 72 minutes are Apple Maps' estimates. Time each difficulty yourself and adjust its route's `walkingMinutes` if it's off.
- **The prize.** Downtown Logan's prize box holds a generic coupon that reads "Your Business" and "Your offer here". Once a business signs on, put its name in `business` and the agreed offer in `offer` (and any changed `terms` or date, plus the prize's `title` and `detail`) in the `prize` in `LoganQuest/Quest.swift`, then make the same changes in `Partners/make_coupon.py` and redraw the pitch coupon to match.
- **Retake the screenshots.** Once the questions and the offer are real, run `Tools/screenshots.sh` and upload the new set (see **App Store screenshots** below).

## Adding a quest

Add a `Quest` to `Quest.all` in `LoganQuest/Quest.swift`, with one or more `routes`, a `prize` for its prize box (a badge, `.badge(symbol:)` with an SF Symbol, or a business's coupon, `.coupon(…)`) and a `badgeSymbol`: the SF Symbol on the badges for finishing its routes, which show up in My Progress by themselves. Each route is a difficulty with its stops in walking order; give a quest just one route and it has no difficulty picker. Define each stop once (like Downtown Logan's, in the `Stop` extension at the bottom of the file) and list it in every route that visits it, so a find counts on each. Progress is saved by quest `id` and stop `id`, and badges by quest `id` and difficulty, so never change those once a build is out.

To pick stops and fill in the walking time, give `Tools/walk_time.swift` the places in order. It looks each one up in Apple Maps (address and coordinates for the `Stop`), then times the loop back to the first place:

```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer swift Tools/walk_time.swift "Logan Tabernacle" "Cache Valley Visitors Bureau" "Umbrella Alley Logan" "Thatcher Young Mansion" "Ellen Eccles Theatre"
```

## Building

Open `LoganQuest.xcodeproj` in Xcode and run. From the command line, point at the full Xcode (or run `sudo xcode-select -s /Applications/Xcode.app/Contents/Developer` once):

```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild -project LoganQuest.xcodeproj -scheme LoganQuest -destination 'generic/platform=iOS Simulator' build
```

Debug builds can open straight to a screen for screenshots: launch with `-LQScreen myProgress`, `reset`, `quest`, `stop` (the first stop not found yet, showing its question), `complete`, `prize` or `prizeOpen` (the prize box opening by itself). Add `-LQFound 3` to start with the first quest's first three stops found (any number; `0` clears it), counted along the chosen difficulty's route. This replaces the progress saved on that simulator, and its badges with just the ones those finds earn. Add `-LQDifficulty medium` (or `easy`, `hard`) to pick that difficulty first; it stays picked afterwards. Deleting the app from a simulator doesn't clear its progress or sign-in (the keychain keeps them), so use `-LQFound 0` and Sign Out instead.

## App Store screenshots

`Tools/screenshots.sh` takes the App Store screenshots and saves them in [`AppStore/Screenshots`](AppStore/Screenshots): the quest map, a stop's question, "Quest complete", the open prize box and the home screen, at 1320×2868 (App Store Connect's 6.9-inch iPhone size, which covers every iPhone). It builds a Debug copy and runs it on the newest "Pro Max" simulator, so it needs no Apple account. Upload them under App Store Connect → Logan Quest → Distribution → iOS App Version → App Previews and Screenshots, in order. The current set shows the practice questions and the generic coupon, so retake them once those are real.

## TestFlight

The app is set up in App Store Connect as **Logan Quest** (SKU `loganquests`).

**Every push to `main` ships a TestFlight build.** Xcode Cloud's **Default** workflow archives `main` on each push and sends the build to the internal TestFlight group **Me**, usually 15–30 minutes after the push. If another push lands while a build is running, the older build is cancelled. Xcode Cloud numbers the builds itself, starting at 10 (after the five builds uploaded by hand); change that under App Store Connect → Xcode Cloud → Settings → Build Number. Edit the workflow under App Store Connect → Xcode Cloud → Manage Workflows, or in Xcode with Integrate → Manage Workflows.

**Every build raises the version by .1.** Before each build, Xcode Cloud runs [`ci_scripts/ci_pre_xcodebuild.sh`](ci_scripts/ci_pre_xcodebuild.sh), which turns the build number into the version: build 21 is 1.1, build 22 is 1.2, and so on (1.9 is followed by 1.10). Builds 20 and earlier all shipped as 1.0. Nothing gets committed for it, so the project itself stays at 1.0. A cancelled build still uses up its number, so TestFlight can skip a version now and then. If the build number in Xcode Cloud is ever reset, change `first_build` in the script to match.

**To upload by hand instead:** run `Tools/release.sh <version>`, with the version .1 above the newest build in TestFlight (for example `Tools/release.sh 1.7` after 1.6). It archives, signs with the Apple account signed in to Xcode, and uploads. Xcode picks the next build number.

**Getting it on your iPhone:** install **TestFlight** from the App Store, sign in with the same Apple Account as the developer account, and tap **Install** next to Logan Quest. TestFlight offers each new build as it arrives.

To add someone else on the developer team, open App Store Connect → Logan Quest → TestFlight → **Me** → Testers → **+**.

**Public link for everyone else:** https://testflight.apple.com/join/ynz9DXQa, or scan [`TestFlight/qr.png`](TestFlight/qr.png). It joins the external group **Public** (open to anyone, no tester limit). Testers can install only once a build in **Public** has passed Beta App Review. Xcode Cloud builds are internal-only, so builds reach **Public** only when uploaded with `Tools/release.sh` and added to the group (App Store Connect → TestFlight → Public → Builds → **+**). The answers to the review questions are under TestFlight → Test Information. To redraw the QR code for a different link, run `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer swift Tools/make_qr.swift <link> TestFlight/qr.png`. It checks that the new image scans.

## Partners

`Partners/coupon.png` is a generic coupon mockup for pitching Logan businesses. It reads "Your Business" and "Your offer here", and it expires December 31, 2026. `make_coupon.py` beside it redraws the coupon; its docstring has the command. The app's prize box draws the same coupon in SwiftUI (`LoganQuest/CouponView.swift`) from the `prize` in `Quest.swift`, so change both when the offer changes.

## Icon

`Tools/icon/make_icon.py` draws the icon: L and Q drawn as one road on red-rock orange. The L's road turns the corner into the Q, a roundabout with a gold flag on its island, and the Q's tail is a road leaving it. Rerun it after editing, then copy the result to the `Logo` image set too (`sips -z 512 512 …`), which the home screen header uses. The script's docstring has both commands.
