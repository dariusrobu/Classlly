# Automated App Store Screenshots

This directory contains automation scripts to generate App Store screenshots using Flutter's `integration_test` package.

## Prerequisites

- Flutter SDK installed and configured.
- An iOS Simulator or Android Emulator running.
- `integration_test` dependency in `pubspec.yaml`.

## Running the Automation

To generate screenshots, run the following command in your terminal:

```bash
flutter drive \
  --driver=test_driver/integration_test.dart \
  --target=integration_test/app_store_screenshots_test.dart
```

## Output

Screenshots will be saved in the `screenshots/` directory in the project root.

## Scenarios Covered

1.  **Onboarding**: Captures the initial onboarding screen.
2.  **Dashboard**: Captures the main dashboard populated with courses ("Advanced Mathematics", "Physics").
3.  **Note Canvas**: Enters the Mathematics course, measures drawing canvas.
4.  **Tasks View**: Captures the Tasks management screen with sample assignments.
5.  **Calendar View**: Captures the Academic Calendar screen.
6.  **Course Stats**: Captures the Course Detail view with Grade History and Performance stats.
