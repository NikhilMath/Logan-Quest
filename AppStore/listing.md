# App Store listing (draft)

Everything to fill in under App Store Connect → Logan Quest → Distribution before submitting
the first version for review. The text is ready to paste. Lines marked **Fill in** need a
decision from Nikhil first.

**Don't submit until the questions and the coupon are real.** Apple rejects apps with
placeholder content, and both the "Practice question:" stops and the "Your Business / Your offer
here" coupon count. Retake the screenshots after that (`Tools/screenshots.sh`).

Character limits are App Store Connect's. Everything below fits.

## App Information

| Field | Value |
| --- | --- |
| Name (30) | Logan Quest |
| Subtitle (30) | Scavenger hunts in Logan, Utah |
| Primary category | Travel |
| Secondary category | Entertainment |
| Content rights | No third-party content for now. Once a business is on the coupon, answer **Yes**: it's their name, shown with their permission. |
| Age rating | 4+ (answers below) |
| Privacy Policy URL | https://github.com/NikhilMath/Logan-Quest/blob/main/AppStore/privacy.md |

Travel is where most city scavenger-hunt and walking-tour apps are listed. Games would work
too (Adventure and Trivia), but games need a government license number to be sold in China
mainland, so leave China out if you go that way.

### Age rating answers

Apple's questionnaire comes out at 4+ with these answers:

- Parental controls, age assurance: **No**
- Unrestricted web access: **No**. Walking Directions opens the Apple Maps app; there's no
  browser in the app.
- User-generated content, messaging and chat: **No**
- Advertising: **No**. The coupon is the prize for finishing; there are no ads or ad networks.
- Violence, profanity, sexual content, horror, alcohol, tobacco and drugs, mature themes,
  medical or wellness content: **None**
- Gambling, simulated gambling, loot boxes: **No / None**
- Contests: **None**. Everyone who finishes gets the same prize; nobody is drawn or ranked.

## Pricing and Availability

| Field | Value |
| --- | --- |
| Price | Free |
| Availability | United States (every quest is in Logan). All countries would also be fine. |

## App Privacy

| Question | Answer |
| --- | --- |
| Do you or your third-party partners collect data from this app? | **No, we do not collect data from this app** |
| Tracking | None |

Why "not collected": Apple counts data as collected only when it leaves the phone in a way
that lets the developer or a partner get at it. Logan Quest has no server, analytics, ads or
third-party code. Progress stays on the iPhone and, for players who sign in, in their own
iCloud key-value storage, which only that player's devices can read. The Sign in with Apple
identifier and first name stay on the phone the same way. The privacy policy says the same.

## iOS App Version

### Promotional text (170)

```
Walk downtown Logan, answer a question at every stop, and open the prize box at the end. Pick Easy, Medium or Hard.
```

### Description (4000)

**Fill in** the business and offer in the PRIZE BOX paragraph once one signs on, and change
the walking times if the timed walks come out different from Apple Maps' estimates.

```
Logan Quest turns a walk around downtown Logan, Utah, into a scavenger hunt.

Walk from stop to stop and answer a question at each one. Every question is about something you can only see when you're standing there, so you'll have to go and look. Find every stop to open the prize box at the end.

DOWNTOWN LOGAN
Start and finish at the Logan Tabernacle, and pick how far you want to go:
• Easy: 5 stops, about 20 minutes
• Medium: 9 stops, about 30 minutes
• Hard: 15 stops, about 70 minutes

Along the way you'll pass Umbrella Alley, the Ellen Eccles Theatre, the Thatcher-Young Mansion, the Cache Pioneer Museum, the Logan Utah Temple and more. A stop you find counts on every difficulty.

THE PRIZE BOX
Find every stop on your route and the prize box opens. Inside is a coupon from [BUSINESS]: [OFFER]. Show it at the counter. The ticking clock on it shows it's not a screenshot.

BADGES
Earn a badge for each difficulty you finish. Badges stay, even if you reset your progress and play again.

YOUR PROGRESS
• See every stop on a map, and get walking directions to it in Apple Maps.
• Sign in with Apple (optional) to keep your progress in iCloud on every iPhone you use.
• Your progress stays even if you delete the app and download it again.
• No ads, no tracking, and the app never asks for your location.
```

### Keywords (100)

```
scavenger hunt,walking tour,Cache Valley,downtown,history,landmarks,treasure hunt,USU,family,clues
```

"Logan", "Quest" and "Utah" are left out because the name and subtitle already count as
keywords.

### Everything else on the version page

| Field | Value |
| --- | --- |
| Support URL | https://github.com/NikhilMath/Logan-Quest/blob/main/AppStore/support.md |
| Marketing URL | Leave blank (optional) |
| Screenshots | The five in `AppStore/Screenshots`, in order, retaken once the questions and coupon are real |
| Copyright | **Fill in:** `2026` and your name (or your company's) |
| Sign-in required | No (leave the user name and password blank: Sign in with Apple is optional) |
| App Review contact | **Fill in:** your name, phone and email (only Apple sees these) |
| App Review notes | Paste the text from `AppStore/review-notes.md` |
| Version release | **Manually release this version**, so the app goes live when the business is ready |
