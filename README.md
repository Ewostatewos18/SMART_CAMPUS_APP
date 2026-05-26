# Smart Campus — Complaint & Suggestion Platform

Production-oriented Flutter app for **Bahir Dar University Student Union**. Students submit complaints and suggestions; sector officers respond; leadership handles escalations; administrators manage users and analytics.

## Tech stack

| Layer | Choice |
|-------|--------|
| Frontend | Flutter (Material 3), Riverpod, GoRouter |
| Backend | Firebase Auth, Cloud Firestore, FCM, Storage (ready) |
| Architecture | Feature-first + clean layers (`core/`, `features/`, `services/`, `models/`) |

## Roles

- **Student** — submit/track tickets, notifications, profile
- **Sector Officer** — sector queue, status updates, replies
- **Vice President / President** — escalated complaints
- **Administrator** — users, analytics, search

## Firestore collections

| Collection | Purpose |
|------------|---------|
| `users` | Profiles linked to Firebase Auth UID |
| `complaints` | Tickets with status, priority, smart tags |
| `responses` | Discussion thread per complaint |
| `notifications` | In-app alerts |
| `escalation_logs` | Escalation audit trail |

## Getting started

**On Linux desktop:** Firebase does not support Linux. Use Chromium/Web:

```bash
./scripts/run_web.sh
# or:
export CHROME_EXECUTABLE=/usr/bin/chromium-browser
flutter run -d chrome
```

**Android / other platforms:**

```bash
flutter pub get
flutter doctor
flutter run
```

### Firebase setup

1. Place `android/app/google-services.json`
2. Place `ios/Runner/GoogleService-Info.plist`
3. Deploy security rules: `firebase deploy --only firestore:rules`

### First admin user

1. Register as a student in the app
2. In Firebase Console → Firestore → `users/{uid}` set `role` to `admin`

Staff roles (officer, VP, president) must be assigned by an admin — open registration is **student-only**.

## Project structure

```
lib/
├── main.dart                 # Firebase bootstrap
├── app.dart                  # MaterialApp.router + theme
├── core/
│   ├── constants/
│   ├── theme/
│   ├── router/
│   ├── widgets/              # Shared UI (cards, shimmer, chips)
│   ├── providers/            # Riverpod service providers
│   └── services/             # Smart analysis (rule-based AI)
├── features/auth/            # Auth state (Riverpod)
├── models/                   # Domain models
├── screens/                  # Feature screens
└── services/                 # Firebase data access
```

## Smart features (v2)

Rule-based analysis at submit time:

- Auto category & priority suggestion
- Sentiment score
- Spam / duplicate detection
- Auto-tagging

Swap `SmartAnalysisService` for Cloud Functions + Gemini when ready.

## Roadmap

- [ ] Cloud Functions for FCM push on notification writes
- [ ] Image attachments via Firebase Storage
- [ ] Offline persistence (Hive + sync queue)
- [ ] PDF/Excel report export
- [ ] Real-time typing indicators in chat

## Tests

```bash
flutter test
```

## License

Private — Bahir Dar University Student Union.
