# Fix login — do these 4 steps

Your users are already in Firebase. Follow **every step**.

## Step 1 — Publish Firestore rules (required)

1. Open https://console.firebase.google.com/ → project **smartcampusapp-bf9af**
2. **Firestore Database** → **Rules**
3. Open the file `firestore.rules` in this project on your computer
4. Select all → copy → paste into Firebase Console
5. Click **Publish**

Without this, login will never work.

## Step 2 — Enable Email login

1. **Authentication** → **Sign-in method**
2. **Email/Password** → **Enable** → Save

## Step 3 — Run the app

```bash
cd /home/ewostatewos/SMART_CAMPUS_APP
flutter clean
flutter pub get
./run.sh
```

## Step 4 — Log in

1. Open **Log in** (do not register again if you already have an account)
2. Email: **exactly** as in Authentication (e.g. `BDU1403952@bdu.edu.et`)
3. Password: what you set at registration

The app will now **auto-fix** a missing or wrong Firestore profile when you log in.

---

## Still stuck?

### A) Reset password

Authentication → Users → your user → **Reset password**  
Or use **Forgot password** in the app.

### B) Check Firestore manually

1. Authentication → copy **User UID**
2. Firestore → `users` → document with **that exact ID**
3. Fields should include:
   - `accountStatus`: `approved`
   - `role`: `student` or `admin`
   - `isActive`: `true`

### C) Delete and register once more

Only if nothing else works:

1. Delete user in **Authentication**
2. Delete matching doc in **Firestore → users**
3. Register again in the app → Log in

---

## Admin login

1. Register as Administrator (code: `BDU-SMARTCAMPUS-ADMIN`)
2. Firestore → `users/{your-uid}` → set `accountStatus` = `approved`, `role` = `admin`
3. Log in
