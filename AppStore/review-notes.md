# Notes for App Review (draft)

Paste the text in the box into App Store Connect → Logan Quest → the version's **App Review
Information → Notes**. **Fill in** the business's name before submitting.

The reviewer can't walk around Logan, so the notes tell them how to unlock stops from anywhere.
Typing `Nikhil` works for them because App Review builds run in the same sandbox as TestFlight
(`TestUnlock.swift`). The App Store version still turns it off.

```
Logan Quest is a walking scavenger hunt in downtown Logan, Utah. Each stop asks a question about something you can only see when you're standing there, so players have to visit every stop.

TESTING WITHOUT TRAVELING TO LOGAN
Type Nikhil as the answer to any stop and tap Unlock. This shortcut works only in TestFlight and App Review builds. The App Store version turns it off, so real players have to visit the stops.

A QUICK WAY THROUGH THE APP
1. On the home screen, tap Downtown Logan.
2. Leave the difficulty on Easy (7 stops). Medium and Hard say "Coming Soon" and can't be played yet.
3. Tap a stop, type Nikhil and tap Unlock. Do the same for the other six stops.
4. After the last stop, the Quest complete screen opens. Tap "Open your prize box", then tap the box to see the coupon.
5. Back on the home screen, tap My Progress to see the badge you earned, and the Reset options.

SIGN IN WITH APPLE IS OPTIONAL
Every feature works without signing in, so no demo account is needed. Signing in only turns on saving progress to the player's own iCloud key-value storage and shows their first name on the Quest complete screen. The app has no server, so no account is created anywhere and nothing is sent to us. Sign Out is under My Progress.

LOCATION
The app doesn't use location services. The Walking Directions button opens Apple Maps.

THE PRIZE
Every player who finds all the stops on a route gets the same coupon from [BUSINESS], a business in Logan, which agreed to the offer shown. It's redeemed in person by showing the screen at the counter. It isn't a contest, sweepstakes or drawing, nothing is bought in the app, and Apple is not a sponsor.
```
