# Goals Challenge App — Plan

A habit challenge app for a small group (2–8 people): each person tracks their own daily and weekly goals and sees how the others are doing.

## Platforms
| Who | How | Widget |
|-----|-----|--------|
| Android | Native Flutter app (APK, installed directly; no Play Store needed) | Yes, a home-screen widget that rotates through the partner's photos from today, plus their % for the day |
| iPhone | The same Flutter code built for the web, installed as a PWA ("Add to Home Screen", iOS 16.4+ for push notifications) | Not for now. Can become a native app later with the $99/yr Apple account and Codemagic cloud builds |

## Stack
- **Flutter**: one codebase for the Android app and the web app
- **Firebase** (free tier): Auth (login), Firestore (live sync), Cloud Messaging (push), Hosting (web app), Cloud Functions (scheduled and partner notifications)
- **Steps**: read automatically from Health Connect on Android, and you can always enter them manually (the manual entry is the main input on iPhone/web)
- **Languages**: Hebrew (default, RTL) and English, chosen separately by each user

## Default goals (editable for each challenge round)
**Daily**
| Goal | Type | Target |
|------|------|--------|
| Water | counter | ≥ 8 glasses |
| Steps | number | ≥ 10,000 |
| No sugary drinks | yes/no | yes |
| Vegetables with every meal | yes/no | yes |
| 3 meals | counter | = 3 |
| No sugar in the morning | yes/no | yes |
| Sweets/snacks | counter | ≤ 1 |
| Social media | minutes | ≤ 60 |
| Reading | minutes | ≥ 60 |

**Weekly**
| Goal | Type | Target |
|------|------|--------|
| Workouts (≥ 30 min each) | log entries | 1 run + 2 strength |
| Junk food | counter | ≤ 1 |

## Screens
1. **Today**: quick logging (+1 buttons, toggles, minutes), with a summary strip of your partner's day
2. **Week**: workout log (type and duration) and the junk-food counter
3. **Board**: heatmap for each person across the challenge period. The color strength is the % of daily goals met. Also shows streaks and success rates per goal
4. **Settings**: challenge start and end dates (start new rounds), goal editing, language, reminder times, partner pairing

## Partner visibility
**Summary only**: you see your partner's ✔/✘ for each goal and their daily %, not their exact numbers. For weekly goals (workouts, junk food), you see only whether the goal was met, not the counts. Photos are the exception: they are shared on purpose.

## Photos
- **Optional:** every goal card has a 📷 button (camera or gallery) to attach a photo for that goal, like a meal, a workout, a book page or the last glass of water.
- **Storage is free (no credit card):** photos are resized to about 1080px (roughly 100 KB) and stored in Firestore, one document per photo. They are visible to both partners; the detailed numbers stay private.
- **Partner view:** today's photos appear in the partner card, and tapping one opens it full-screen.
- **Reactions:** ❤️ 💪 🔥 on your partner's photos, shown in the app live. Push notifications for reactions come with the Notifications step.
- **Photo diary:** tap a day on the board to see both partners' photos from that day.

## Notifications
- **End-of-day check (וידוא)**: at a time you choose, a summary of the day. Any goals not logged yet are listed with a button to fill them in
- **Scheduled reminders**: e.g. water and reading
- **Nudge your partner**: send your partner a reminder about a specific goal

## Scoring
Daily score = met daily goals ÷ total daily goals. Weekly goals are shown separately on the week view and the board.

## Milestones
1. ✅ Project setup, Firebase, login and partner pairing, Today screen with sync, Hebrew/English
2. ✅ Photos: attach a photo to a goal, compress and store it, group photo strips and viewer, reactions
3. ✅ Android home-screen widget: rotates through the group's photos from today, with everyone's %; launcher shortcuts; iPhone install guide
4. ✅ Week screen, Board (heatmap, stats and photo diary), goal editing, challenge rounds, leaving a group and replacing the invite code
5. Notifications: ✅ end-of-day check and midday reminder on Android (on-device). Still to do: nudges and reaction pushes between members, which need a server (Cloud Functions)
6. Health Connect steps (Android)
7. Later: native iPhone app and widget

## What you'll need to provide
- A Google account to create the Firebase project (I'll walk you through it and give you the config to paste in)
- An Android phone that allows installing an APK from outside the store
