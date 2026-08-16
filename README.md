<div align="center">

<br/>

# 🌿 Vitalis
### Personal Calorie, Water & Sleep Tracker

**Privacy-first · 100% Offline · On-Device AI · Android**

[![Flutter](https://img.shields.io/badge/Flutter-3.2%2B-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.2%2B-0175C2?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev)
[![Android](https://img.shields.io/badge/Android-minSdk%2026-3DDC84?style=for-the-badge&logo=android&logoColor=white)](https://developer.android.com)
[![License](https://img.shields.io/badge/License-MIT-green?style=for-the-badge)](LICENSE)
[![Version](https://img.shields.io/badge/Version-1.0.0-blueviolet?style=for-the-badge)](pubspec.yaml)

<br/>

> *Track calories, hydration, and sleep in one beautiful, glassmorphic interface — entirely on your device, with no cloud, no subscriptions, and no rate limits.*

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

---

## 🌟 Overview

**Vitalis** is a holistic personal health companion built with Flutter, designed for Android. It unifies nutrition logging, smart hydration tracking, and circadian sleep analytics into a single, cohesive experience styled with iOS-inspired frosted-glass aesthetics.

Every computation — from BMR/TDEE calculations to AI-generated health narratives — runs fully on-device, leveraging your phone's NPU/APU via Android NNAPI and TFLite. No data ever leaves your device.

---

## ✨ Features

### 🍽️ Smart Tiered Nutrition Tracking

Vitalis resolves food data across a **4-tier cascade**, maximising speed and coverage:

| Priority | Source | Description |
|----------|--------|-------------|
| **1st** | User History & Custom Recipes | Instant retrieval from local Drift SQLite |
| **2nd** | ICMR-NIN Indian Food DB | Bundled offline dataset — South Indian & Kerala traditional dishes |
| **3rd** | Open Food Facts API | Barcode scanning & global packaged foods |
| **4th** | USDA FoodData Central API | Scientific macro/micronutrient data for raw ingredients |

- **Live Macro Rings** — Real-time visual distribution of Calories, Protein, Carbs & Fat
- **Custom Recipe Builder** — Log multi-ingredient dishes with saved templates
- **Barcode Scanner** — Scan packaged food barcodes for instant nutritional lookup

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

### 🧠 On-Device AI Health Engine

Zero network calls. Zero cloud dependency. All intelligence runs locally:

```
Tier A  →  Pure Dart deterministic rule templates     (100% offline baseline)
Tier B  →  Multi-factor vitality & recovery scorer    (0–100 balance score)
Tier C  →  On-device TFLite health narration          (contextual daily insights)
```

- **Hardware-Accelerated** via Android NNAPI and MediaTek APU
- **Capability-Gated** — Falls back gracefully through tiers if hardware is unavailable
- **Daily Balance Score** — Composite metric combining nutrition, hydration, and sleep quality

---

### 🔒 Local-First & 100% Private

- **Drift SQLite** — All personal health records stored strictly on-device
- **Full JSON Backup & Restore** — One-tap database export/import via OS Share Sheet
- **No Cloud Backend** — Zero external authentication, zero telemetry, zero rate limits
- **Android Health Connect** — Write nutrition and hydration records back to the system health store

---

## 🏗️ Architecture

Vitalis follows a **clean layered architecture** with unidirectional data flow:

```
┌─────────────────────────────────────────────────────┐
│                      UI Layer                       │
│   Glassmorphic screens · Design System Components   │
└────────────────────┬────────────────────────────────┘
                     │  Riverpod Providers
┌────────────────────▼────────────────────────────────┐
│                   Domain Layer                      │
│     Food Providers · Insights Engine · Profiles     │
└────────────────────┬────────────────────────────────┘
                     │  Repositories & Services
┌────────────────────▼────────────────────────────────┐
│                    Data Layer                       │
│  Drift SQLite · Health Connect · REST APIs · TFLite │
└─────────────────────────────────────────────────────┘
```

---

## 🛠️ Tech Stack

| Category | Technology |
|----------|-----------|
| **Framework** | Flutter (Dart) — Android primary target |
| **State Management** | Riverpod 2.x / 3.x |
| **Local Database** | Drift (SQLite) with reactive streams |
| **AI / ML** | TFLite Flutter (`tflite_flutter`) — NPU/NNAPI accelerated |
| **Health Data** | Android Health Connect (`health` package) |
| **Charts** | `fl_chart` |
| **Typography** | Google Fonts — Inter |
| **Notifications** | `flutter_local_notifications` |
| **HTTP** | Dart `http` — Open Food Facts, USDA, Open-Meteo |
| **Code Generation** | `drift_dev` + `build_runner` |

---

## 🚀 Getting Started

### Prerequisites

- **Flutter SDK** `>=3.2.0`
- **Dart SDK** `>=3.2.0 <4.0.0`
- **Android Studio** or **VS Code** with the Flutter extension
- **Android device** — minSdk 26+, optimised for modern NPU/APU chipsets

### Installation

```bash
# 1. Clone the repository
git clone https://github.com/your-username/vitalis.git
cd vitalis

# 2. Install Flutter dependencies
flutter pub get

# 3. Run Drift code generator
#    (required after any database schema change)
dart run build_runner build --delete-conflicting-outputs

# 4. Run on a connected device
flutter run
```

> **Note:** The app is optimised for physical Android devices. An emulator will work but NPU/NNAPI acceleration will not be available and the TFLite model will fall back to CPU inference.

---

## 📁 Project Structure

```
lib/
├── data/
│   ├── export/                   # JSON backup & restore service
│   ├── food/                     # Food repository: USDA, OpenFoodFacts, INDB
│   ├── health/                   # Android Health Connect client
│   └── local/                    # Drift SQLite database, tables & DAOs
├── domain/
│   ├── food/                     # Food search providers & state
│   ├── insights/                 # NPU narrator, balance scorer, rule engine
│   └── profile/                  # User profile state & BMR/TDEE calculations
├── services/
│   ├── notification_service.dart # Scheduled wind-down & hydration alerts
│   └── weather_hydration_service.dart  # Open-Meteo dynamic hydration
└── ui/
    ├── common/                   # Glassmorphism cards, progress rings, tokens
    ├── food/                     # Food search sheet, custom logger, meal cards
    ├── insights/                 # AI vitality score card & contextual insights
    ├── sleep/                    # Sleep screen, fl_chart trends, log sheet
    └── today/                    # Main dashboard & quick log actions

assets/
├── data/
│   └── indb_kerala_foods.json    # Bundled ICMR-NIN offline food dataset
├── icon/
│   └── app_icon.jpg              # App launcher icon
└── models/
    └── health_narrator.tflite    # On-device TFLite AI model
```

---

## 🤖 On-Device AI Engine

The AI insights module operates on a **3-tier capability cascade**:

### Tier A — Deterministic Rules *(Always Available)*
Pure Dart logic with no ML dependencies. Generates structured health tips based on threshold comparisons (e.g., calories vs. TDEE, sleep duration vs. target).

### Tier B — Balance Scorer *(CPU/GPU)*
A multi-factor scoring model that produces a **0–100 Vitality Score** combining:
- Calorie adherence (vs. personalised TDEE)
- Hydration rate (vs. weather-adjusted target)
- Sleep quality (duration, consistency, and timing)

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

---

## 🧪 Testing

Run the full automated test suite covering BMR/TDEE math, multi-source food queries, dynamic hydration scaling, sleep timestamp edge cases, database export/import, and AI insights:

```bash
# Run all unit & widget tests
flutter test

# Run a specific test file
flutter test test/bmr_calculator_test.dart

# Run tests with verbose output
flutter test --reporter=expanded
```

The test suite covers:
- `BMRCalculator` — Mifflin-St Jeor equation accuracy
- `FoodRepository` — Tiered resolution and fallback logic
- `WeatherHydrationService` — Dynamic target scaling
- `SleepTimestampCalculator` — Midnight-boundary edge cases
- `DatabaseExportService` — JSON serialisation and restore integrity
- `InsightEngine` — Tier A rule outputs and Tier B scoring accuracy

---

## 🤝 Contributing

Contributions, bug reports, and feature requests are welcome.

1. Fork the repository
2. Create a feature branch: `git checkout -b feat/your-feature-name`
3. Commit your changes: `git commit -m 'feat: add your feature'`
4. Push to your branch: `git push origin feat/your-feature-name`
5. Open a Pull Request

Please follow the [Conventional Commits](https://www.conventionalcommits.org/) specification for commit messages.

---

## 📄 License

This project is licensed under the **MIT License** — see the [LICENSE](LICENSE) file for details.

---

<div align="center">

Built with ❤️ using Flutter &nbsp;·&nbsp; Powered by on-device intelligence &nbsp;·&nbsp; Zero cloud, zero compromise

</div>
