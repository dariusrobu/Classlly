# Classlly Production Launch Map

This document outlines the critical path to moving from a development prototype to a live, production-ready application.

---

## 🛠 1. Technical Infrastructure (Backend & Security)

### Supabase Production Environment
- [x] **Migrate to Production Project:** Create a separate Supabase project for production (do not use the dev project for live users).
- [x] **Row Level Security (RLS):** 
    - [x] Enable RLS on all tables (`notes`, `tasks`, `folders`, `courses`, etc.).
    - [x] Implement policies so users can ONLY read/write their own data (`auth.uid() = user_id`).
- [x] **Storage Buckets:** 
    - [x] Configure production storage buckets for audio recordings and images.
    - [x] Set public/private access rules appropriately.
- [x] **Database Indexes:** Add indexes to frequently queried columns (e.g., `user_id`, `is_deleted`) to ensure performance at scale. (See `INDEXES.sql`)

### Error Tracking & Stability
- [ ] **Integrate Sentry or Firebase Crashlytics:** Essential for tracking crashes on real user devices.
- [X] **Global Error Boundary:** Implement a UI-level error boundary to prevent the "black screen of death" if a widget fails to build.

---

## 🔐 2. Authentication & Identity

- [ ] **Complete Google Sign-In:**
    - [ ] Generate production OAuth Client IDs for iOS, Android, and Web.
    - [ ] Update reversed Client ID in `Info.plist`.
- [x] **Complete Apple Sign-In:**
    - [x] Enable "Sign In with Apple" capability in the Apple Developer Portal.
    - [ ] Add the capability in Xcode for both iOS and macOS targets.
- [ ] **Email Templates:** Customize the Supabase "Confirm Email" and "Password Reset" templates with Classlly branding.

---

## 🎨 3. Design & UX Polish

- [X] **App Icons:** Generate a full set of icons for iOS, Android, and macOS using `flutter_launcher_icons`.
- [X] **Splash Screens:** Create branded splash screens for all platforms.
- [x] **Empty States:** Ensure every screen has a "Nothing here yet" illustration and call-to-action (currently some are just text).
- [x] **Loading Indicators:** Add consistent shimmer effects or progress bars for sync and data fetching. (Added Syncing indicator to Canvas)
- [X] **Onboarding:** Finalize the `OnboardingScreen` with real copy and skip button.

---

## 📱 4. Platform-Specific Prep

### iOS / macOS
- [ ] **App Store Connect:** Create the app record.
- [x] **Privacy Info (plist):** Ensure all `NSUsageDescription` keys are descriptive and translated if necessary.
- [ ] **Push Notifications:** Configure APNs (Apple Push Notification service) if remote push is needed (currently using local).

### Android
- [ ] **Google Play Console:** Create the app record.
- [ ] **ProGuard/R8:** Configure obfuscation to protect code and reduce app size.
- [x] **Permissions:** Ensure `AndroidManifest.xml` only requests necessary permissions.

### Web
- [ ] **Domain:** Connect a custom domain (e.g., `app.classlly.com`).
- [ ] **SEO:** Update `web/index.html` with proper meta tags, title, and description.

---

## ⚖️ 5. Legal & Compliance

- [x] **Privacy Policy:** Create a hosted privacy policy (required by Apple/Google). (Draft created in `docs/legal/`)
- [x] **Terms of Service:** Define user rights and usage rules. (Draft created in `docs/legal/`)
- [x] **Data Deletion:** Provide a way for users to delete their entire account and all associated data (GDPR/CCPA compliance). (UI added to Profile)

---

## 🚀 6. Deployment Pipeline

- [ ] **CI/CD:** Setup GitHub Actions or Codemagic to automate:
    - [x] Running tests (`flutter test`). (See `.github/workflows/build.yml`)
    - [ ] Building production APKs/IPAs.
    - [ ] Deploying to TestFlight and Google Play Beta tracks.
- [ ] **Versioning:** Implement a system for incrementing build numbers (`pubspec.yaml`).

---

## ✅ Live Readiness Checklist (The Final 48 Hours)
1. [ ] **Verify Configs:** Check `SupabaseConfig` points to the production URL.
2. [ ] **Smoke Test:** Perform a full walkthrough from Signup -> Profile Setup -> Create Course -> Take Note -> Export PDF.
3. [ ] **Sync Check:** Ensure data correctly syncs between two different devices.
4. [ ] **Performance:** Verify the canvas remains smooth with 100+ strokes.
5. [ ] **Store Assets:** Finalize high-res screenshots and promotional text.
