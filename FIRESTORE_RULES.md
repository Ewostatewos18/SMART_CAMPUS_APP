# Firestore rules (required for register & login)

Registration and login **will fail** until these rules are active in your Firebase project.

## Option A — Firebase CLI

```bash
npm install -g firebase-tools
firebase login
cd SMART_CAMPUS_APP
firebase use smartcampusapp-bf9af
./scripts/deploy_firestore_rules.sh
```

## Option B — Firebase Console

1. Open [Firebase Console](https://console.firebase.google.com/) → project **smartcampusapp-bf9af**
2. **Firestore Database** → **Rules**
3. Copy the full contents of `firestore.rules` from this repo
4. Click **Publish**

## "Client is offline" during register

This means the browser could not reach **Cloud Firestore** (not the same as "no Wi‑Fi").

1. Confirm internet works in the same browser (open https://google.com).
2. Disable VPN / ad-blockers for localhost or your app URL.
3. In [Firebase Console](https://console.firebase.google.com/) → **Firestore Database** → ensure a database exists (Create database if empty).
4. Publish the rules above, then hard-refresh the app (Ctrl+Shift+R).

## After deploying

1. Restart the app: `./run.sh`
2. Register as **Student** with email like `BDU1403952@bdu.edu.et`
3. Log in with the same email and password

If you previously tried to register and it failed, that email may already exist in Firebase Auth. Use **Forgot password** on the login screen or delete the user in Firebase Console → Authentication.
