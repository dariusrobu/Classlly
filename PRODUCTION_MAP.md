# Classlly Production Launch Map 🗺️

This document outlines the final steps required to transition **Classlly** from a functional prototype to a public product on the Apple App Store and Google Play Store.

---

## 🚀 Current Status Overview
- **Core Engine:** Verified (Canvas, Audio Sync, Real-time Sync).
- **iOS:** Technical compliance complete (including Account Deletion).
- **Android:** Infrastructure ready; awaiting configuration files.
- **Engagment:** Notifications and Home Screen Widgets implemented.

---

## 🛠️ Technical Tasks (To be done by Developer/Agent)

### 1. PDF Snippet Refinement
- [ ] **Precision Cropping:** Upgrade the PDF insertion logic to allow users to select a specific area of a page instead of inserting the full page.
- [ ] **Resolution Tweak:** Ensure snippets remain crisp when zoomed in on the canvas.

### 2. Real-time Collaboration (Phase 22)
- [ ] **Supabase Presence:** Implement actual Realtime Presence to show who is online in the `_AvatarStack`.
- [ ] **Shared State:** Ensure strokes from other users appear instantly with their specific user color.

### 3. Polish & Optimization
- [ ] **Asset Compression:** Optimize Base64 image storage or move to Supabase Storage buckets for large files to reduce local database size.
- [ ] **Crash Analytics:** Integrate Sentry or Firebase Crashlytics to monitor production errors.

---

## 👤 User Action Items (Things YOU need to do)

### 🔐 Android Release Setup (Critical)
1.  **Firebase:** Go to [Firebase Console](https://console.firebase.google.com/), add an Android app to your project (`com.robudarius.classlly`), download `google-services.json`, and place it in `android/app/`.
2.  **Keystore:** Generate your production upload keystore:
    ```bash
    keytool -genkey -v -keystore ~/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
    ```
3.  **Signing:** Create a `key.properties` file in the `android/` folder based on `key.properties.example` with your actual passwords and path.

### 🎨 Store Marketing Assets
1.  **Screenshots:** Take 5 high-resolution screenshots for each store:
    -   **Dashboard:** Showing academic stats and the calendar.
    -   **Canvas:** Showing a beautiful handwritten note with a PDF snippet.
    -   **Audio Replay:** Highlighting the "Tap to jump" feature.
    -   **Task Board:** Showing the Kanban organization.
2.  **App Description:** Finalize the "Long Description" for the stores, focusing on the "Student Central Command" value proposition.

### ⚖️ Legal & Deployment
1.  **Privacy Policy URL:** Host your privacy policy (available in `docs/legal/`) on a public website (e.g., GitHub Pages or your own domain) as required by Apple and Google.
2.  **App Store Connect:** Create the app listing and upload the iOS `.ipa` build.
3.  **Play Store Console:** Create the app listing and upload the Android `.aab` build.

---

## 🏗️ Future Roadmap (Post-Launch)
- [ ] **Bring Your Own Cloud (BYOC):** Google Drive and iCloud integration.
- [ ] **Desktop Native Apps:** Optimized window management for macOS/Windows.
- [ ] **AI Summarization:** Auto-generate study summaries from recorded audio.