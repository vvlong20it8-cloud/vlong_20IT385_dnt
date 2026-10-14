# Project 1.1 — PWA: Field Survey

A responsive Flutter web application for creating, viewing, editing, and deleting field survey records.

## Features

- Responsive dashboard with survey count
- Create a survey with location, surveyor, date, status, and notes
- View survey details
- Edit existing records
- Delete records with confirmation
- Search records by location, surveyor, or notes
- Filter records by status
- Local persistence using `shared_preferences`
- Flutter web build configuration and PWA manifest

## Requirements

- Flutter SDK (stable channel)
- Dart SDK included with Flutter
- Google Chrome or another modern browser

## Run locally

From the project root:

```bash
flutter doctor
flutter pub get
flutter run -d chrome
```

If Chrome is not listed, run `flutter devices` and configure a supported web browser.

## Build for web

```bash
flutter build web
```

The deployable website is generated in `build/web/`.

To preview the build using Python:

```bash
python -m http.server 8000 --directory build/web
```

Then open <http://localhost:8000>.

## Data storage

This starter version stores records in the current browser using `shared_preferences`. It does not sync data to a server or between devices. Clearing browser data may remove locally stored records.

## Important note

This project is a complete starter implementation based on the project title “PWA - Field Survey”. If the instructor's specification requires additional features (for example GPS, maps, photos, authentication, REST API, or offline synchronization), implement those requirements before submission.

## Author

Student name: YOUR FULL NAME
Student ID: YOUR STUDENT ID
