# Logan Quests

An iPhone app of scavenger hunts around Logan, Utah. Players walk to each stop on a quest, answer a question only someone standing there would know, and unlock it. Finding every stop brings up a "Quest complete" screen with a ticking clock, so it can't be passed off as a screenshot.

## What's in the app

- **Quests** (home screen): every quest, how long it takes to walk, and how far along you are. Downtown Logan is the first one; add more in `LoganQuest/Quest.swift`.
- **A quest**: a map of its numbered stops and the list to unlock them. Each quest is a loop: visit the stops in order and you end up back at the first one. Each stop has walking directions and its question.
- **Downtown Logan**: Logan Tabernacle → Old Cache County Courthouse → Umbrella Alley → Ellen Eccles Theatre → back to the Tabernacle. About 15 minutes (0.8 mi) on foot by Apple Maps, not counting time spent at each stop.
- **Prize box**: every quest has one, shown under the walking time. It stays locked until every stop is found. Then a tap sends the lid flying and the prize rises out, with spinning rays and a ticking clock so it can't be passed off as a screenshot either. The "Quest complete" screen has a button to it too.
- **My Progress** (person button, top right): every stop you've found and when, plus resetting. Resetting asks twice: a page that lists exactly what will be erased, then an "Are you sure?" alert.
- **Sign in with Apple** (optional): saves progress to iCloud so it follows you to another iPhone, and puts your first name on the "Quest complete" screen. Without signing in, progress stays on that phone. There's no server: progress lives in iCloud key-value storage on the player's own Apple account.
- **iPhone Duo and wide screens**: the map sits beside the list instead of above it. The app supports every orientation and doesn't require full screen, so it fills the Duo's inner screen.

## Before launch

- **Real questions.** The four questions in `LoganQuest/Quest.swift` are practice placeholders ("what's this building called?"). Walk downtown and replace each with something only someone there would know, like what's carved on a plaque. List every spelling you'd accept in `acceptedAnswers`; matching already ignores case, punctuation, accents and a leading "the".
- **Check the pins.** Coordinates came from Apple Maps. The old courthouse pin is the Cache Valley Visitors Bureau address (199 N Main St).
- **Walk the loop.** The 15 minutes is Apple Maps' estimate. Time it yourself on the walk and adjust `walkingMinutes` if it's off.
- **The prize.** Each prize box holds a badge for now (`prize` in `LoganQuest/Quest.swift`). Nothing in the app names a business or a real-world reward yet. Put the real prize there once one is agreed.

## Adding a quest

Add a `Quest` to `Quest.all` in `LoganQuest/Quest.swift`, with its stops in walking order and a `prize` for its prize box. Progress is saved by quest `id` and stop `id`, so never change those once a build is out.

To pick stops and fill in the walking time, give `Tools/walk_time.swift` the places in order. It looks each one up in Apple Maps (address and coordinates for the `Stop`), then times the loop back to the first place:

```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer swift Tools/walk_time.swift "Logan Tabernacle" "Cache Valley Visitors Bureau" "Umbrella Alley Logan" "Ellen Eccles Theatre"
```

## Building

Open `LoganQuest.xcodeproj` in Xcode and run. From the command line, point at the full Xcode (or run `sudo xcode-select -s /Applications/Xcode.app/Contents/Developer` once):

```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild -project LoganQuest.xcodeproj -scheme LoganQuest -destination 'generic/platform=iOS Simulator' build
```

Debug builds can open straight to a screen for screenshots: launch with `-LQScreen myProgress`, `reset`, `quest`, `complete`, `prize` or `prizeOpen` (the prize box opening by itself).

## TestFlight

The app is set up in App Store Connect as **Logan Quests** (SKU `loganquests`). Its internal TestFlight group **Me** has automatic distribution on, so every uploaded build reaches the group once Apple finishes processing it (5–15 minutes).

**To upload a build:** run `Tools/release.sh`. It archives, signs with the Apple account signed in to Xcode, and uploads. Xcode picks the next build number.

**Getting it on your iPhone:** install **TestFlight** from the App Store, sign in with the same Apple Account as the developer account, and tap **Install** next to Logan Quests. TestFlight offers each new build as it arrives.

To add someone else on the developer team, open App Store Connect → Logan Quests → TestFlight → **Me** → Testers → **+**.

Friends outside your developer account go in an **External Testing** group. Apple reviews the first build sent to external testers.

## Icon

`Tools/icon/make_icon.py` draws the icon: LOGAN in cream over QUESTS in gold, on navy. Rerun it after editing, then copy the result to the `Logo` image set too (`sips -z 512 512 …`), which the home screen header uses. The script's docstring has both commands.
