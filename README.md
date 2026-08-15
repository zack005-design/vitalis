# Calorie, Water & Sleep Tracker

A personal, privacy-first, local-first health and wellness tracker built with Flutter, Riverpod, and Drift SQLite. Designed with iOS-inspired glassmorphic aesthetics and optimized for on-device hardware acceleration (NPU/APU) with zero cloud rate limits.

---

## 🌟 Key Features

### 1. 🍽️ Smart Tiered Nutrition Tracking
* **4-Tier Food Resolution**:
  1. **User History & Custom Recipes**: Instant retrieval from local Drift SQLite database.
  2. **Bundled ICMR-NIN Indian Food DB**: Offline dataset covering South Indian & Kerala traditional dishes.
  3. **Open Food Facts API**: Barcode scanning and global packaged foods directory.
  4. **USDA FoodData Central API**: Scientific macro/micronutrient breakdown for raw ingredients, grains, fruits, vegetables, and meats.
* **Macro Adherence**: Live tracking of Calories, Protein, Carbohydrates, and Fat with visual distribution rings.

### 2. 💧 Weather-Aware Dynamic Hydration
* **Open-Meteo Integration** (Free, Zero Auth):
  * Automatically fetches ambient temperature and humidity.
  * Dynamically scales daily water targets (e.g., $+300\text{ ml}$ to $+500\text{ ml}$ on hot/humid days) to sustain metabolic hydration.
* **Quick Log Controls**: Rapid $+250\text{ ml}$, $+500\text{ ml}$, and custom logging.

### 3. 🌙 Circadian Sleep Analytics
* **Intelligent Timestamp Calculator**: Handles overnight sessions crossing midnight without boundary bugs.
* **Interactive Visual Analytics**: 7-day and 30-day trend charts built with `fl_chart`.
* **Android Health Connect**: Direct on-device sync with smartwatches and wearable sleep records.

### 4. 🧠 On-Device NPU AI Health Engine
* **Hardware-Accelerated on Phone NPU/GPU**: Configured for Android NNAPI and MediaTek APU hardware.
* **Zero Cloud API Rate Limits**: Completely offline, eliminating external API keys and network latency.
* **Tiered AI Coordination**:
  * **Tier A**: Pure Dart deterministic rule templates (100% offline baseline).
  * **Tier B**: Multi-factor vitality and recovery balance scoring ($0 - 100$).
  * **Tier C**: Contextual on-device health narration and evening wind-down recommendations.

### 5. 🔒 Local-First & 100% Private
* **Drift SQLite Storage**: All personal health records stay strictly on your device.
* **Full JSON Backup & Restore**: One-tap database export/import via OS Share Sheet.

---

## 🛠️ Architecture & Tech Stack

```
lib/
├── data/
│   ├── export/               # JSON backup & restore service
│   ├── food/                 # Food search repository, USDA client, OpenFoodFacts, INDB
│   ├── health/               # Android Health Connect client
│   └── local/                # Drift SQLite database, tables, and DAOs
├── domain/
│   ├── food/                 # Food providers & search state
│   ├── insights/             # On-device NPU narrator, balance scorer, rule engine
│   └── profile/              # User profile state & BMR/TDEE calculations
├── services/
│   ├── notification_service.dart     # Local scheduled wind-down & hydration alerts
│   └── weather_hydration_service.dart # Open-Meteo dynamic hydration service
└── ui/
    ├── common/               # Glassmorphism cards, progress rings, design tokens
    ├── food/                 # Food search sheet, custom food logger, meal cards
    ├── insights/             # AI vitality score card & contextual insights
    ├── sleep/                # Sleep screen, interactive fl_chart trends, log sheet
    └── today/                # Main dashboard & quick log actions
```

---

## 🚀 Getting Started

### Prerequisites
* Flutter SDK: `>=3.2.0`
* Android Studio / VS Code with Flutter extension
* Android device (minSdk 26+, optimized for modern NPU/APU chipsets)

### Setup & Run
```bash
# 1. Clone repository and install dependencies
flutter pub get

# 2. Run Drift code generator (if database tables change)
dart run build_runner build --delete-conflicting-outputs

# 3. Run all unit & widget tests
flutter test

# 4. Run app on connected device
flutter run
```

---

## 🧪 Test Suite

Run the full automated test suite covering BMR math, multi-source food queries, dynamic hydration, sleep timestamps, database export/import, and on-device NPU insights:

```bash
flutter test
```
