# Logan Quests

An iPhone app of scavenger hunts around Logan, Utah. Players walk to each stop on a quest, answer a question only someone standing there would know, and unlock it. Finding every stop brings up a "Quest complete" screen with a ticking clock, so it can't be passed off as a screenshot.

## What's in the app

- **Quests** (home screen): every quest and how far along you are. Downtown Logan is the first one; add more in `LoganQuest/Quest.swift`.
- **A quest**: a map of its stops and the list to unlock them. Each stop has walking directions and its question.
- **My Progress** (person button, top right): every stop you've found and when, plus resetting. Resetting asks twice: a page that lists exactly what will be erased, then an "Are you sure?" alert.
- **Sign in with Apple** (optional): saves progress to iCloud so it follows you to another iPhone, and puts your first name on the "Quest complete" screen. Without signing in, progress stays on that phone. There's no server: progress lives in iCloud key-value storage on the player's own Apple account.
- **iPhone Duo and wide screens**: the map sits beside the list instead of above it. The app supports every orientation and doesn't require full screen, so it fills the Duo's inner screen.

## Before launch

- **Real questions.** The three questions in `LoganQuest/Quest.swift` are practice placeholders ("what's this building called?"). Walk downtown and replace each with something only someone there would know, like what's carved on a plaque. List every spelling you'd accept in `acceptedAnswers`; matching already ignores case, punctuation, accents and a leading "the".
- **Check the pins.** Coordinates came from Apple Maps. The old courthouse pin is the Cache Valley Visitors Bureau address (199 N Main St).
- **Rewards.** Nothing in the app mentions a reward or a business yet.

## Adding a quest

Add a `Quest` to `Quest.all` in `LoganQuest/Quest.swift`. Progress is saved by quest `id` and stop `id`, so never change those once a build is out.

## Building

Open `LoganQuest.xcodeproj` in Xcode and run. From the command line, point at the full Xcode (or run `sudo xcode-select -s /Applications/Xcode.app/Contents/Developer` once):

```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild -project LoganQuest.xcodeproj -scheme LoganQuest -destination 'generic/platform=iOS Simulator' build
```

Debug builds can open straight to a screen for screenshots: launch with `-LQScreen myProgress`, `reset`, `quest` or `complete`.

## TestFlight

The app is set up in App Store Connect as **Logan Quests** (SKU `loganquests`). Its internal TestFlight group **Me** has automatic distribution on, so every uploaded build reaches the group once Apple finishes processing it (5–15 minutes).

**To upload a build:** run `Tools/release.sh`. It archives, signs with the Apple account signed in to Xcode, and uploads. Xcode picks the next build number.

**Getting it on your iPhone:** install **TestFlight** from the App Store, sign in with the same Apple Account as the developer account, and tap **Install** next to Logan Quests. TestFlight offers each new build as it arrives.

To add someone else on the developer team, open App Store Connect → Logan Quests → TestFlight → **Me** → Testers → **+**.

Friends outside your developer account go in an **External Testing** group. Apple reviews the first build sent to external testers.

## Icon

`Tools/icon/make_icon.py` draws the icon (a stylized Old Main tower at sunset over the Cache Valley mountains, with the quest pin and trail). Rerun it after editing, then copy the result to the `Logo` image set too (`sips -z 512 512 …`), which the home screen header uses.
