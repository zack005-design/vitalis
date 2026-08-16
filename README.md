<div align="center">

<img src="assets/icon/app_icon.jpg" alt="Vitalis App Icon" width="150" height="150" />

<br/>

# 🌿 Vitalis
### Personal Calorie, Water & Sleep Tracker

**Privacy-first &nbsp;·&nbsp; 100% Offline &nbsp;·&nbsp; On-Device AI &nbsp;·&nbsp; Android**

[![Flutter](https://img.shields.io/badge/Flutter-3.2%2B-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.2%2B-0175C2?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev)
[![Android](https://img.shields.io/badge/Android-minSdk%2026-3DDC84?style=for-the-badge&logo=android&logoColor=white)](https://developer.android.com)
[![License](https://img.shields.io/badge/License-MIT-green?style=for-the-badge)](LICENSE)
[![Version](https://img.shields.io/badge/Version-1.2.0-blueviolet?style=for-the-badge)](pubspec.yaml)

<br/>

> *Track calories, hydration, sleep, and activity in one beautiful glassmorphic interface — entirely on your device. No cloud. No subscriptions. No rate limits.*

<br/>

</div>

---

## 📋 Table of Contents

- [Overview](#-overview)
- [Features](#-features)
- [Architecture](#-architecture)
- [Tech Stack](#%EF%B8%8F-tech-stack)
- [Getting Started](#-getting-started)
- [Project Structure](#-project-structure)
- [AI Engine](#-on-device-ai-engine)
- [Data & Privacy](#-data--privacy)
- [Testing](#-testing)
- [Contributing](#-contributing)
- [License](#-license)

---

## 🌟 Overview

**Vitalis** is a holistic personal health companion built with Flutter for Android. It unifies nutrition logging, smart hydration tracking, circadian sleep analytics, and real-time activity sensing into a single cohesive experience styled with premium iOS-inspired frosted-glass aesthetics.

Every computation — from BMR/TDEE calculations to AI-generated health narratives — runs fully on-device, leveraging your phone's NPU/APU via Android NNAPI and TFLite. Your health data never leaves your device.

---

## ✨ Features

### 🍽️ Smart Tiered Nutrition Tracking

Vitalis resolves food data across a **4-tier cascade**, maximising speed and offline coverage:

| Priority | Source | Description |
|----------|--------|-------------|
| **1st** | User History & Custom Recipes | Instant retrieval from local Drift SQLite |
| **2nd** | ICMR-NIN Indian Food DB | Bundled offline dataset — South Indian & Kerala dishes |
| **3rd** | Open Food Facts API | Barcode scanning & global packaged foods |
| **4th** | USDA FoodData Central API | Scientific macro/micronutrient data for raw ingredients |

- **Live Macro Rings** — Real-time visual breakdown of Calories, Protein, Carbs & Fat
- **Custom Recipe Builder** — Save and reuse multi-ingredient dish templates
- **Barcode Scanner** — Scan packaged food barcodes for instant nutritional lookup
- **Shimmer Loading States** — Polished skeleton screens during data fetch

---

### 💧 Weather-Aware Dynamic Hydration

Hydration targets adapt to your local environment in real time:

- **Open-Meteo Integration** *(free, zero-auth)* — Fetches ambient temperature and humidity
- **Dynamic Scaling** — Target automatically adjusts $+300\text{ ml}$ to $+500\text{ ml}$ on hot/humid days
- **Quick Log Controls** — One-tap $+250\text{ ml}$, $+500\text{ ml}$, and fully custom entry
- **Progress Visualisation** — Animated circular ring with daily percentage completion

---

### 🌙 Circadian Sleep Analytics

- **Midnight-Safe Timestamp Engine** — Correctly handles sessions crossing midnight without boundary bugs
- **Trend Charts** — Interactive 7-day and 30-day sleep history built with `fl_chart`
- **Android Health Connect Sync** — Direct on-device sync with smartwatches and wearable sleep records
- **Evening Wind-Down Reminders** — Configurable local notifications for bedtime preparation

---

### 🏃 Activity Recognition & Motion Sensing

- **Passive Activity Detection** — Classifies Walking, Running, Cycling, and more via `activity_recognition_flutter`
- **Sensor Fusion** — Accelerometer and gyroscope data via `sensors_plus` for richer motion context
- **Screen Continuity** — `wakelock_plus` keeps the display active during active tracking sessions
- **Health Connect Integration** — Activity data synced back to the Android system health store

---

### 🧠 On-Device AI Health Engine

Zero network calls. Zero cloud dependency. All intelligence runs locally:

```
Tier A  →  Pure Dart deterministic rule templates     (100% offline baseline)
Tier B  →  Multi-factor vitality & recovery scorer    (0–100 balance score)
Tier C  →  On-device TFLite health narration          (contextual daily insights)
```

- **Hardware-Accelerated** via Android NNAPI and MediaTek APU
- **Capability-Gated** — Falls back gracefully through tiers if hardware is unavailable
- **Daily Balance Score** — Composite metric combining nutrition, hydration, sleep, and activity

---

### 🔒 Local-First & 100% Private

- **Drift SQLite** — All personal health records stored strictly on-device
- **Full JSON Backup & Restore** — One-tap database export/import via OS Share Sheet
- **No Cloud Backend** — Zero external authentication, zero telemetry, zero rate limits
- **Android Health Connect** — Write nutrition, hydration, and activity records back to the system health store

---

## 🏗️ Architecture

Vitalis follows a **clean layered architecture** with unidirectional data flow:

```
┌────────────────────────────────────────────────────────┐
│                       UI Layer                         │
│  Glassmorphic screens · Design System Components       │
│  (AppScaffold · GlassContainer · CircularProgressRing) │
└─────────────────────┬──────────────────────────────────┘
                      │  Riverpod Providers
┌─────────────────────▼──────────────────────────────────┐
│                    Domain Layer                        │
│   Food Providers · Insights Engine · User Profiles     │
│   Activity Recognition · Hydration Service             │
└─────────────────────┬──────────────────────────────────┘
                      │  Repositories & Services
┌─────────────────────▼──────────────────────────────────┐
│                     Data Layer                         │
│  Drift SQLite · Health Connect · REST APIs · TFLite    │
│  Sensor Streams · Local Notifications                  │
└────────────────────────────────────────────────────────┘
```

---

## 🛠️ Tech Stack

| Category | Technology |
|----------|-----------|
| **Framework** | Flutter (Dart) — Android primary target |
| **State Management** | Riverpod 2.x / 3.x |
| **Local Database** | Drift (SQLite) with reactive streams |
| **AI / ML** | TFLite Flutter (`tflite_flutter`) — NPU/NNAPI accelerated |
| **Health Data** | Android Health Connect (`health` package v13) |
| **Charts** | `fl_chart` |
| **Typography** | Google Fonts — Inter |
| **Notifications** | `flutter_local_notifications` |
| **HTTP** | Dart `http` — Open Food Facts, USDA, Open-Meteo |
| **Activity Sensing** | `activity_recognition_flutter` + `sensors_plus` |
| **Screen Continuity** | `wakelock_plus` |
| **Loading States** | `shimmer` |
| **File I/O** | `file_picker` · `path_provider` |
| **Code Generation** | `drift_dev` + `build_runner` |

---

## 🚀 Getting Started

### Prerequisites

- **Flutter SDK** `>=3.2.0`
- **Dart SDK** `>=3.2.0 <4.0.0`
- **Android Studio** or **VS Code** with the Flutter extension
- **Android device** — minSdk 26+, optimised for modern NPU/APU chipsets

> **Recommended:** A physical Android device with a Qualcomm, MediaTek Dimensity, or Google Tensor chipset for full NPU/NNAPI acceleration.

### Installation

```bash
# 1. Clone the repository
git clone https://github.com/your-username/vitalis.git
cd vitalis

# 2. Install Flutter dependencies
flutter pub get

# 3. Run Drift code generator
dart run build_runner build --delete-conflicting-outputs

# 4. Run on a connected device
flutter run
```

> **Note:** The app is optimised for physical Android devices. An emulator will work but NPU/NNAPI acceleration and activity recognition will not be available.

---

## 📁 Project Structure

```
lib/
├── data/
│   ├── export/                        # JSON backup & restore service
│   ├── food/                          # Food repository: USDA, OpenFoodFacts, INDB
│   ├── health/                        # Android Health Connect client
│   └── local/                         # Drift SQLite database, tables & DAOs
├── domain/
│   ├── food/                          # Food search providers & state
│   ├── insights/                      # NPU narrator, balance scorer, rule engine
│   └── profile/                       # User profile state & BMR/TDEE calculations
├── services/
│   ├── notification_service.dart      # Scheduled wind-down & hydration alerts
│   └── weather_hydration_service.dart # Open-Meteo dynamic hydration
└── ui/
    ├── design_system/                 # AppScaffold, GlassContainer, AppButton, tokens
    ├── food/                          # Food search sheet, custom logger, meal cards
    ├── insights/                      # AI vitality score card & contextual insights
    ├── more/                          # Settings, data export, and profile screens
    ├── sleep/                         # Sleep screen, fl_chart trends, log sheet
    └── today/                         # Main dashboard & quick log actions

assets/
├── data/
│   └── indb_kerala_foods.json         # Bundled ICMR-NIN offline food dataset
├── icon/
│   └── app_icon.jpg                   # App launcher icon
└── models/
    └── health_narrator.tflite         # On-device TFLite AI narration model
```

---

## 🤖 On-Device AI Engine

The AI insights module operates on a **3-tier capability cascade**:

### Tier A — Deterministic Rules *(Always Available)*
Pure Dart logic with no ML dependencies. Generates structured health tips based on threshold comparisons (e.g., calories vs. TDEE, sleep duration vs. target, hydration rate).

### Tier B — Balance Scorer *(CPU/GPU)*
A multi-factor scoring model that produces a **0–100 Vitality Score** combining:
- Calorie adherence (vs. personalised TDEE)
- Hydration rate (vs. weather-adjusted target)
- Sleep quality (duration, consistency, and timing)
- Activity level (steps and active minutes)

### Tier C — TFLite Narration *(NPU/NNAPI Gated)*
A quantised TFLite model running on the device NPU that generates **contextual, natural-language daily summaries** — powered entirely on-chip with no network calls.

```dart
// Tier selection is automatic and transparent to the UI
final insight = await insightEngine.generateDailyInsight(
  profile: userProfile,
  todayLog: healthLog,
);
```

---

## 🔐 Data & Privacy

Vitalis was designed with a **privacy-first, local-first** philosophy:

- ✅ **No account required** — zero sign-up, zero sign-in
- ✅ **No network telemetry** — no analytics SDKs or crash reporters
- ✅ **No paid APIs** — all external APIs used are free and do not require authentication
- ✅ **Full data portability** — export your entire database as JSON at any time
- ✅ **Health Connect** — writes health records to the Android system store; you stay in full control
- ✅ **On-device AI only** — no prompts or personal data ever sent to a remote model

---

## 🧪 Testing

Run the full automated test suite:

```bash
# Run all unit & widget tests
flutter test

# Run tests with verbose output
flutter test --reporter=expanded
```

| Test File | Coverage |
|-----------|---------|
| `bmr_calculator_test.dart` | Mifflin-St Jeor equation accuracy |
| `food_repository_test.dart` | Tiered resolution and fallback logic |
| `weather_hydration_test.dart` | Dynamic target scaling |
| `sleep_timestamp_test.dart` | Midnight-boundary edge cases |
| `export_service_test.dart` | JSON serialisation and restore integrity |
| `insight_engine_test.dart` | Tier A rule outputs and Tier B scoring accuracy |

---

<div align="center">

Built with ❤️ using Flutter &nbsp;·&nbsp; Powered by on-device intelligence &nbsp;·&nbsp; Zero cloud, zero compromise

</div>
