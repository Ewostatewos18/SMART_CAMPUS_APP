# Smart Campus

**Complaint & Suggestion Platform** for Bahir Dar University Student Union.

Students submit complaints and suggestions; sector officers respond; leadership handles escalations; administrators manage users and analytics.

| | |
|---|---|
| **Firebase project** | `smartcampusapp-bf9af` |
| **GitHub** | [afom12/SMART_CAMPUS_APP](https://github.com/afom12/SMART_CAMPUS_APP) |
| **Stack** | Flutter · Firebase Auth · Cloud Firestore · Riverpod · GoRouter |

---

## Table of contents

1. [Share the app with others (deploy)](#share-the-app-with-others-deploy)
2. [Codes & credentials reference](#codes--credentials-reference)
3. [User roles & login](#user-roles--login)
4. [Run locally (developers)](#run-locally-developers)
5. [Firebase setup (first time)](#firebase-setup-first-time)
6. [Firestore rules](#firestore-rules)
7. [Project structure](#project-structure)
8. [Troubleshooting](#troubleshooting)
9. [Tests](#tests)

---

## Share the app with others (deploy)

The easiest way for **other people to use the app in a browser** is **Firebase Hosting** (free tier).

### One-time setup (you, as owner)

1. Install tools:

```bash
# Flutter: https://docs.flutter.dev/get-started/install
npm install -g firebase-tools
firebase login
```

2. Link Firebase project:

```bash
cd SMART_CAMPUS_APP
firebase use smartcampusapp-bf9af
```

3. Publish Firestore rules (if not done yet):

```bash
firebase deploy --only firestore:rules
```

### Build & deploy the website

```bash
./scripts/deploy_web.sh
```

Or manually:

```bash
flutter pub get
flutter build web --no-web-resources-cdn
firebase deploy --only hosting
```

After deploy, Firebase prints a URL like:

```text
https://smartcampusapp-bf9af.web.app
```

**Send that link** to students, officers, and admins. They open it in Chrome and use Register / Log in.

### Other ways to share

| Method | Best for |
|--------|----------|
| **Firebase Hosting URL** | Everyone with internet (recommended) |
| **GitHub repo** | Developers who will run `./run.sh` locally |
| **Android APK** | Phones without laptop — build with `flutter build apk --release` |

### Update the live site after changes

```bash
git pull
flutter pub get
./scripts/deploy_web.sh
```

---

## Codes & credentials reference

> **Security:** There is **no shared password** for all users. Each person chooses their own password when they **register**. Never put real passwords in this file or in git.

### Administrator registration code

Required when someone registers as **Administrator** in the app.

| Item | Value |
|------|--------|
| **Admin registration code** | `BDU-SMARTCAMPUS-ADMIN` |
| **Defined in code** | `lib/core/constants/app_constants.dart` → `adminRegistrationCode` |
| **Change it** | Edit that constant, rebuild, redeploy |

To use a **private** code in production, change `BDU-SMARTCAMPUS-ADMIN` to a secret only your team knows, then redeploy.

### Student email format

| Item | Example |
|------|---------|
| Format | `BDU` + **student ID** + `@bdu.edu.et` |
| Example email | `BDU1303957@bdu.edu.et` |
| Example student ID | `1303957` |

### Password rules (registration)

| Rule | Requirement |
|------|-------------|
| Minimum length | 6 characters |
| Letters / numbers | Optional (any characters allowed) |

Each user sets their **own** password at registration. If forgotten: use **Forgot password** on the login screen.

### Firebase Console access (project owners only)

| Item | Value |
|------|--------|
| Console | https://console.firebase.google.com/ |
| Project ID | `smartcampusapp-bf9af` |
| Authentication | Email / Password must be **enabled** |

Only trusted project owners should have Firebase Console access. Do not share your Google account password.

### Account approval (`accountStatus` in Firestore)

| Role | After registration |
|------|-------------------|
| **Student** | `approved` — can log in immediately |
| **Administrator** | `approved` — can log in immediately (with valid admin code) |
| **Sector Officer / VP / President** | `pending` — an admin must approve in **User management** |

In Firestore, field `accountStatus` must be `approved` for login to work (except auto-fix on login for student/admin).

---

## User roles & login

| Role | Register as | After register | Dashboard route |
|------|-------------|----------------|-----------------|
| Student | Student | Log in right away | `/student` |
| Sector Officer | Sector Officer | Wait for admin approval | `/officer` |
| Vice President | Vice President | Wait for admin approval | `/vp` |
| President | President | Wait for admin approval | `/president` |
| Administrator | Administrator + admin code | Log in right away | `/admin` |

### First administrator

1. **Register** in the app → role **Administrator** → code `BDU-SMARTCAMPUS-ADMIN`
2. **Log in** → Admin dashboard
3. Approve other staff: **User management** → **Pending approval**

### Create staff without self-registration (admin)

Admin dashboard → create staff account (officer / VP / president) with a temporary password; share it securely with that person.

---

## Run locally (developers)

### Requirements

- Flutter SDK 3.7+
- Chrome or Chromium (for web — **required on Ubuntu/Linux**)
- Firebase project configured (`lib/firebase_options.dart`, `google-services.json`)

### Quick start (Linux / Ubuntu)

Firebase does **not** run on Linux desktop. Use **web**:

```bash
git clone https://github.com/afom12/SMART_CAMPUS_APP.git
cd SMART_CAMPUS_APP
chmod +x run.sh
./run.sh
```

`run.sh` runs:

```bash
flutter run -d chrome --no-web-resources-cdn
```

### Android

```bash
flutter pub get
flutter run -d android
```

### Windows / macOS web

```bash
flutter pub get
flutter run -d chrome --no-web-resources-cdn
```

---

## Firebase setup (first time)

### 1. Enable services

In [Firebase Console](https://console.firebase.google.com/) → **smartcampusapp-bf9af**:

| Service | Action |
|---------|--------|
| **Authentication** | Sign-in method → **Email/Password** → Enable |
| **Firestore** | Create database (production mode is OK) |
| **Hosting** | Used when you deploy web (optional until deploy) |

### 2. App configuration files

| Platform | File |
|----------|------|
| Android | `android/app/google-services.json` |
| iOS | `ios/Runner/GoogleService-Info.plist` |
| Web / Dart | `lib/firebase_options.dart` |

Regenerate with FlutterFire if you create a **new** Firebase project:

```bash
dart pub global activate flutterfire_cli
flutterfire configure
```

### 3. Firestore user document (manual fix if needed)

Every Authentication user needs a matching Firestore document:

- Collection: `users`
- **Document ID** = Authentication **User UID** (exact match)
- Required fields: `email`, `name`, `role`, `accountStatus` (`approved`), `isActive` (`true`)

See [FIX_LOGIN.md](FIX_LOGIN.md) for details.

---

## Firestore rules

| File | Purpose |
|------|---------|
| `firestore.rules` | Production security rules (paste into Console or deploy) |
| `FIRESTORE_RULES.md` | Short deploy guide |
| `FIX_LOGIN.md` | Login / profile troubleshooting |

Deploy rules:

```bash
firebase deploy --only firestore:rules
```

Or copy `firestore.rules` into Firebase Console → Firestore → **Rules** → **Publish**.

> If rules fail to publish with syntax errors, use the version in `firestore.rules` in this repo (uses `.get()` instead of `in`).

For early testing you may use **minimal rules** (see `FIX_LOGIN.md`); replace with full `firestore.rules` before public launch.

---

## Firestore collections

| Collection | Purpose |
|------------|---------|
| `users` | User profiles (linked to Auth UID) |
| `student_ids` | Student ID uniqueness |
| `complaints` | Complaints & suggestions |
| `responses` | Replies per complaint |
| `notifications` | In-app notifications |
| `escalation_logs` | Escalation audit |
| `sectors` | Campus sectors (12 BDU sectors) |

---

## Project structure

```text
lib/
├── main.dart                 # Entry, Firebase init
├── app.dart                  # MaterialApp + router
├── core/
│   ├── constants/            # App name, admin code, BDU email
│   ├── router/               # GoRouter + auth guards
│   ├── theme/
│   ├── widgets/
│   └── services/             # Smart analysis
├── features/auth/            # Splash, landing, login, register
├── models/
├── screens/                  # Dashboards, complaints
└── services/                 # Auth, Firestore APIs

scripts/
├── run_web.sh                # Local web dev
├── deploy_web.sh             # Build + Firebase Hosting
└── deploy_firestore_rules.sh
```

---

## Troubleshooting

| Problem | Solution |
|---------|----------|
| Blank / white screen on web | Run with `--no-web-resources-cdn`; see [RUN.md](RUN.md) |
| “Client is offline” | Internet, VPN off, publish Firestore rules |
| Login → back to welcome | Publish rules; check `accountStatus: approved` |
| “Awaiting approval” (admin) | Pull latest code; admin is auto-approved; or set `approved` in Firestore |
| Rules publish error | Use `firestore.rules` from repo (fixed syntax) |
| Linux `flutter run` fails | Use `./run.sh` (web), not Linux desktop |
| Email already in use | Log in or reset password; don’t register again |

More: [RUN.md](RUN.md) · [FIX_LOGIN.md](FIX_LOGIN.md)

---

## Tests

```bash
flutter test
```

---

## Push code to GitHub

```bash
git add .
git commit -m "Your message"
git push origin main
```

Helper (requires token): `./scripts/push_to_github.sh` — see script comments.

---

## Roadmap

- [ ] Cloud Functions for push notifications
- [ ] Complaint image uploads (Firebase Storage)
- [ ] PDF / Excel reports
- [ ] Full production Firestore rules on all environments

---

## License

Private — Bahir Dar University Student Union.  
Unauthorized redistribution of Firebase credentials or admin codes is discouraged.
