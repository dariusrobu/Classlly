# Classlly Production Launch Map 🗺️

This document outlines the final steps required to transition **Classlly** from a functional prototype to a public product on the Apple App Store and Google Play Store.

---

## 🚀 Current Status Overview
- **Core Engine:** Verified (Canvas, Audio Sync, Real-time Sync).
- **Egress Optimization:** ✅ **COMPLETED** (Images moved to Supabase Storage, Stroke data rounded).
- **iOS:** Technical compliance complete (including Backend Account Deletion).
- **Android:** Infrastructure ready; awaiting configuration files.
- **Engagement:** Notifications and Home Screen Widgets implemented.

---

## 🛠️ Technical Tasks (To be done by Developer/Agent)

### 1. PDF Snippet Refinement
- [x] **Precision Cropping:** Upgrade the PDF insertion logic to allow users to select a specific area of a page instead of inserting the full page.
- [ ] **Resolution Tweak:** Ensure snippets remain crisp when zoomed in on the canvas.

### 2. Real-time Collaboration (Phase 22)
- [ ] **Supabase Presence:** Implement actual Realtime Presence to show who is online in the `_AvatarStack`.
- [ ] **Shared State:** Ensure strokes from other users appear instantly with their specific user color.

### 3. Polish & Monitoring
- [ ] **Crash Analytics:** Integrate Sentry or Firebase Crashlytics to monitor production errors.

---

## 👤 User Action Items (Things YOU need to do)

### ☁️ Supabase Configuration (Critical)
1.  **Storage Bucket:** Go to your Supabase Dashboard -> Storage and create a new bucket named `note-images`. 
2.  **Permissions:** Make the bucket **Public** or add an RLS policy for `authenticated` users to SELECT and INSERT.

### 🔐 Android Release Setup (Critical)
1.  **Firebase:** Go to [Firebase Console](https://console.firebase.google.com/), add an Android app to your project (`com.robudarius.classlly`), download `google-services.json`, and place it in `android/app/`.
2.  **Keystore:** Generate your production upload keystore:
    ```bash
    keytool -genkey -v -keystore ~/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
    ```
3.  **Signing:** Create a `key.properties` file in the `android/` folder based on `key.properties.example` with your actual passwords and path.

### 🍎 iOS Widget Activation
1.  **Xcode Target:** Open `ios/Runner.xcworkspace` in Xcode. Add a new **Widget Extension** target named `ClassllyWidgets`.
2.  **App Groups:** Add the `group.com.robudarius.classlly` App Group to both the **Runner** target and the **ClassllyWidgets** target.

### 🎨 Store Marketing Assets
1.  **Screenshots:** Take 5 high-resolution screenshots for each store. Focus on the Dashboard stats and the unique Audio-Sync Canvas.
2.  **App Description:** Finalize the store descriptions.

---

## 🏗️ Future Roadmap (Post-Launch)
- [ ] **Bring Your Own Cloud (BYOC):** Google Drive and iCloud integration.
- [ ] **Desktop Native Apps:** Optimized window management for macOS/Windows.
- [ ] **AI Summarization:** Auto-generate study summaries from recorded audio.
