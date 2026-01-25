# Classlly Production Roadmap & Checklist

This document serves as the master guide for deploying **Classlly** to production on the Apple App Store and Google Play Store. It outlines the current status, critical missing components, and step-by-step instructions for future updates.

---

## 📱 iOS (App Store)
**Current Status:** Ready for TestFlight (Version `2.5.0+31`)
**Bundle ID:** `com.robudarius.classlly`

### ✅ Completed
*   [x] **App Icon:** Updated with production assets.
*   [x] **Versioning:** Synced with legacy Swift app (`2.5.0`).
*   [x] **Compliance:** Account deletion flow implemented (Local Wipe + Logout).
*   [x] **Privacy Permissions:** `Info.plist` includes usage descriptions for Camera, Microphone, and Photo Library.
*   [x] **Functionality:** Real-time dashboard data (no mocks).
*   [x] **Notifications:** Permission requests moved to on-demand (saving tasks/courses).

### ⚠️ Critical Actions Required (Before Public Launch)
1.  **Backend Account Deletion:**
    *   **Task:** Ensure that when a user requests deletion in the app, their data is actually removed from Supabase.
    *   **Solution:** Implement a Supabase Edge Function or manually process deletion requests if relying on the current email trigger simulation.
2.  **App Store Screenshots:**
    *   **Task:** Upload new screenshots to App Store Connect that reflect the new Flutter UI. Using old Swift UI screenshots may lead to rejection.

---

## 🤖 Android (Google Play)
**Current Status:** 🚧 **NOT READY**
**Package Name:** `com.robudarius.classlly`

### 🛑 Critical Blockers
1.  **Missing `google-services.json`:**
    *   **Reason:** Required for Google Sign-In and Firebase services.
    *   **Action:** Download `google-services.json` from Firebase Console (Project Settings > Your Apps > Android) and place it in `android/app/`.
2.  **No Release Signing Key:**
    *   **Reason:** Google Play rejects apps signed with debug keys.
    *   **Action:** Generate a `.jks` keystore and configure `key.properties`.

### 📝 Step-by-Step Android Release Guide

#### 1. Generate Upload Keystore
Run this command in your terminal:
```bash
keytool -genkey -v -keystore ~/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```
*   **Keep the `upload-keystore.jks` file safe. Never lose it.** If you lose this, you cannot update your app on Google Play.

#### 2. Configure `key.properties`
Create a file named `key.properties` in the `android/` folder with:
```properties
storePassword=<your-store-password>
keyPassword=<your-key-password>
keyAlias=upload
storeFile=<path-to-upload-keystore.jks>
```

#### 3. Update `android/app/build.gradle`
Ensure the `buildTypes` section uses the release signing config. You may need to edit `android/app/build.gradle` to read from `key.properties`:

```gradle
def keystoreProperties = new Properties()
def keystorePropertiesFile = rootProject.file('key.properties')
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
}

android {
    signingConfigs {
        release {
            keyAlias = keystoreProperties['keyAlias']
            keyPassword = keystoreProperties['keyPassword']
            storeFile = keystoreProperties['storeFile'] ? file(keystoreProperties['storeFile']) : null
            storePassword = keystoreProperties['storePassword']
        }
    }
    buildTypes {
        release {
            signingConfig signingConfigs.release
        }
    }
}
```

#### 4. Build App Bundle (AAB)
For Google Play, build an AAB instead of an APK:
```bash
flutter build appbundle --no-tree-shake-icons
```
*   **Output:** `build/app/outputs/bundle/release/app-release.aab`

---

## ☁️ Backend & Security (Supabase)

### 🔒 Row Level Security (RLS) - **MANDATORY**
The app connects directly to Supabase. RLS must be enabled on all tables to prevent data leaks.

*   **Policy Example (Notes):**
    ```sql
    -- Enable RLS
    ALTER TABLE notes ENABLE ROW LEVEL SECURITY;

    -- Create Policy
    CREATE POLICY "Users can only see their own notes"
    ON notes FOR ALL
    USING (auth.uid() = user_id);
    ```
*   **Action:** Verify RLS is enabled for `notes`, `tasks`, `courses`, `profiles`, etc. in the Supabase Dashboard.

### 🔑 Authentication
*   **Redirect URLs:** Ensure your production redirect URLs are added to Supabase Auth settings (for Google/Apple Sign-In).

---

## ⚖️ Legal & Compliance

### Privacy Policy
*   **Requirement:** Both Apple and Google require a valid Privacy Policy URL.
*   **Content:** Must explicitly state:
    *   Data collected (Name, Email, Notes, Audio recordings, Photos).
    *   Third-party services used (Supabase, Google Sign-In).
    *   Data retention policy (How long data is kept).
    *   Account deletion instructions.

### User Data Deletion (Apple Requirement)
*   You **must** provide a way for users to delete their account within the app.
*   The current implementation clears local data and logs them out.
*   **For Approval:** You must ensure this action eventually leads to the deletion of their server-side data (via Edge Function or manual admin process mentioned in your privacy policy).

---

## 📢 Store Listing Metadata (Marketing)

### Required Assets
| Asset | iOS (App Store) | Android (Play Store) |
| :--- | :--- | :--- |
| **App Icon** | 1024x1024 (No Alpha) | 512x512 (Alpha Allowed) |
| **Screenshots** | 6.5" Display (1284x2778)<br>5.5" Display (1242x2208)<br>iPad Pro (2048x2732) | Phone, 7" Tablet, 10" Tablet |
| **Feature Graphic** | N/A | 1024x500 (PNG/JPG) |
| **Short Description** | Promotional Text (170 chars) | Short Description (80 chars) |
| **Long Description** | Full Description (4000 chars) | Full Description (4000 chars) |

*   **Note:** Ensure screenshots reflect the **current Flutter UI**. Do not use old Swift UI screenshots.

---

## 🚀 Release Workflow

### To Update the App (Future)

1.  **Update Version:**
    *   Open `pubspec.yaml`.
    *   Increment version (e.g., `2.5.1+32`).

2.  **Run Checks:**
    ```bash
    flutter analyze
    flutter test
    ```

3.  **Build for iOS:**
    ```bash
    flutter build ipa --no-tree-shake-icons
    open build/ios/ipa
    ```
    *   Upload `Runner.ipa` via Transporter.

4.  **Build for Android:**
    ```bash
    flutter build appbundle --no-tree-shake-icons
    open build/app/outputs/bundle/release
    ```
    *   Upload `app-release.aab` to Google Play Console.

### 🛠 Troubleshooting Common Issues

*   **"Tree Shake Icons" Error:**
    *   If the build fails with `IconData` errors, always add `--no-tree-shake-icons` to your build command.
    *   *Why?* The app dynamically loads icons (e.g., for courses), preventing the compiler from knowing which ones are safe to remove.

*   **"Version already exists" (App Store):**
    *   Go to `pubspec.yaml` and increment the build number (the number after the `+`, e.g., `+32`).


*** ON PHONE THE CANVA ISN'T RESPONSIVE THE NAV BAR IS TOO HIGH AT THE TOP**

---

## 🌟 Future Features / Roadmap

### ☁️ Bring Your Own Cloud (BYOC)
Shift from a purely database-centric sync (Supabase) to a storage-provider model, allowing users to choose where their data lives.

#### Phase 1: Abstraction Layer
*   Create a `CloudStorageService` interface to standardize sync operations (connect, disconnect, sync, status).
*   Refactor `SupabaseRepository` to implement this interface.

#### Phase 2: Google Drive Integration
*   **Dependencies:** `googleapis`, `extension_google_sign_in_as_googleapis_auth`.
*   **Mechanism:** Store data as JSON files in a dedicated `Notelly Data/` folder in the user's Drive.
*   **Auth:** Request `drive.file` scope.

#### Phase 3: iCloud Integration
*   **Dependencies:** `icloud_storage` or `cloud_kit`.
*   **Mechanism:** Sync JSON files via the app's ubiquitous container.
*   **Config:** Enable "iCloud" capabilities in Xcode.

#### Phase 4: User Choice & Settings
*   Add "Cloud Provider" selector in Settings.
*   Implement migration/initial sync logic when switching providers.
