# Authentication Setup Guide

The Google and Apple Sign-In features require configuration in the Google Cloud Console and Apple Developer Portal. Follow these steps to enable them.

## 1. Google Sign-In Setup

### A. Get Client IDs [COMPLETED]
- [x] Go to the [Google Cloud Console](https://console.cloud.google.com/).
- [x] Select your project.
- [x] Go to **APIs & Services > Credentials**.
- [x] Click **Create Credentials > OAuth client ID**.
- [x] **For Web:**
   - Application type: **Web application**.
   - Add your authorized redirect URIs (e.g., from Supabase).
   - Copy the **Client ID**.
- [x] **For iOS/macOS:**
   - Application type: **iOS**.
   - Bundle ID: `com.robudarius.classlly`.
   - Copy the **Client ID** and the **iOS URL scheme** (e.g., `com.googleusercontent.apps.YOUR_CLIENT_ID`).

### B. Update Code [COMPLETED]
- [x] Open `lib/data/repositories/auth_repository.dart`.
- [x] Replace `YOUR_WEB_CLIENT_ID` with the Web Client ID you copied.
- [x] Replace `YOUR_IOS_CLIENT_ID` with the iOS Client ID you copied.

```dart
const webClientId = '153897807907-3lph5o2mo39475fp1jjqglnpur5l3eu3.apps.googleusercontent.com';
const iosClientId = '153897807907-tllogka5ud9ploje6n0urqalhu0n7oku.apps.googleusercontent.com';
```

### C. Update Info.plist (iOS & macOS) [COMPLETED]
- [x] Open `ios/Runner/Info.plist`.
- [x] Add the URL scheme configuration inside the main `<dict>` tag.
- [x] Repeat step 2 for `macos/Runner/Info.plist`.

---

## 2. Apple Sign-In Setup

**Note:** This step requires an active Apple Developer Program membership.

### A. Apple Developer Portal [COMPLETED]
- [x] Go to [Apple Developer Account](https://developer.apple.com/account/).
- [x] Ensure your App ID (`com.robudarius.classlly`) has the **Sign In with Apple** capability enabled.
- [x] Create a **Service ID** for Supabase.

### B. Xcode Configuration [PENDING]
**This is the FINAL step!**
1. Open your project in Xcode (`ios/Runner.xcworkspace` or `macos/Runner.xcworkspace`).
2. Select the **Runner** target.
3. Go to the **Signing & Capabilities** tab.
4. Click **+ Capability** and add **Sign In with Apple**.

---

## 3. Supabase Configuration [COMPLETED]

1. Go to your Supabase Project Dashboard > **Authentication > Providers**.
2. **Google:** [COMPLETED]
   - Enable Google.
   - Enter the **Web Client ID** and **Web Client Secret** from Google Cloud Console.
3. **Apple:** [COMPLETED]
   - Enable Apple.
   - Enter your **Service ID**, **Team ID**, **Key ID**, and **Private Key**.

Once these steps are completed, re-run the app, and authentication should work.
