# How to run Smart Campus on Ubuntu

Firebase **does not work** on Linux desktop. You must run in **Chrome/Chromium (Web)**.

## Quick start (copy-paste)

```bash
cd /home/ewostatewos/SMART_CAMPUS_APP
chmod +x run.sh
./run.sh
```

Wait 30–60 seconds. Chromium should open with the app.

## If Chromium is not installed

```bash
sudo apt update
sudo apt install -y chromium-browser
./run.sh
```

## Manual command

```bash
export CHROME_EXECUTABLE=/usr/bin/chromium-browser
cd /home/ewostatewos/SMART_CAMPUS_APP
flutter pub get
flutter run -d chrome --no-web-resources-cdn
```

Always use `./run.sh` — it includes `--no-web-resources-cdn` automatically.

## White screen / “Failed to fetch canvaskit.js”

The app tried to download graphics from `gstatic.com` and failed (no internet, VPN, or firewall).

**Fix:** use the project script (bundles CanvasKit locally):

```bash
flutter clean
flutter pub get
./run.sh
```

Or manually:

```bash
flutter run -d chrome --no-web-resources-cdn
```

`DebugService: Cannot send Null` lines in the terminal are harmless debug noise on web.

## Common mistakes

| Command | Result |
|---------|--------|
| `flutter run` | Uses **Linux** → shows “Use Web on Linux” or Firebase error |
| `flutter run -d android` | Needs emulator + licenses (not set up on your PC) |
| `flutter run -d chrome` without `CHROME_EXECUTABLE` | “Cannot find Chrome” |

## Run from VS Code / Cursor

1. Install extension: **Dart** and **Flutter**
2. Press **F5** or Run → **Smart Campus (Chrome Web)**

## If the app opens but login fails

1. Firebase Console → **Authentication** → enable **Email/Password**
2. Firestore → create `users/{uid}` for admin with `role: "admin"`, `isActive: true`
3. Deploy rules: `firebase deploy --only firestore:rules`

## Still stuck?

```bash
flutter clean
flutter pub get
./run.sh
```
