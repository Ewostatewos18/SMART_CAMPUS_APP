# smart_campus_app

steps to run the Flutter + Firebase project locally.

1. Clone the repository

```bash
git clone YOUR_GITHUB_REPO_LINK
```

2. Open the project in VS Code or Android Studio

3. Install Flutter packages

```bash
flutter pub get
```

4. Make sure Flutter SDK is installed

Check using:

```bash
flutter doctor
```

5. Firebase Setup

The project already uses Firebase.

For Android:
Place the `google-services.json` file inside:

```text
android/app/
```

For iOS:
Place `GoogleService-Info.plist` inside:

```text
ios/Runner/
```

6. Run the app

```bash
flutter run
```

If there are any dependency issues:

```bash
flutter clean
flutter pub get
```

7. Required tools

* Flutter SDK
* Android Studio or VS Code
* Android Emulator or physical device
* Firebase account
