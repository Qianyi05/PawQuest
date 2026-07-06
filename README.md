<div align="center">

# 🐾 PawQuest

### Walk Italy, one step at a time.

**PawQuest turns everyday walking into an exploration game.** Every real-world step moves
you across a stylised map of Italy — unlocking cities, collecting regional food stickers,
and completing weather-aware daily quests, with a friendly community and a data-rich iPad
edition to review your progress.

[![Flutter](https://img.shields.io/badge/Flutter-%E2%89%A53.3.0-02569B?logo=flutter)](https://flutter.dev)
[![Firebase](https://img.shields.io/badge/Backend-Firebase-FFCA28?logo=firebase&logoColor=black)](https://firebase.google.com)
[![Platform](https://img.shields.io/badge/Platform-iOS%20%7C%20Android%20%7C%20iPad-4CAF50)](#)
[![watchOS](https://img.shields.io/badge/Companion-Apple%20Watch-000000?logo=apple)](#)
[![Course](https://img.shields.io/badge/DIMA-2025%2F2026-E0A93A)](#)

<em>Design and Implementation of Mobile Applications — Politecnico di Milano.</em>

</div>

---

## ✨ Features

- **👟 Step tracking that never drifts** — reads the device pedometer and, on iOS,
  reconciles with **Apple Health (HealthKit)**, adding only the positive difference so
  steps are never double-counted. Keeps a lifetime total and a per-day history.
- **🌤️ Weather-aware daily quests** — each day's step goal and advice adapt to your local
  weather.
- **🗺️ Explore Italy** — cross step thresholds to unlock Italian cities on an interactive
  map, each with a **live Wikipedia summary**.
- **🍝 Food sticker album** — every city unlocks a signature regional dish.
- **👥 Community** — posts with images, comments, likes, follow/unfollow, and **real-time
  notifications**, all backed by atomic Firestore transactions.
- **📊 iPad edition** — a navigation-rail dashboard experience, including a **dedicated
  step-statistics dashboard** (range selector, trends, weekday pattern, goal achievement,
  activity heatmap, records and insights) computed by a pure, unit-tested analytics layer.
- **⌚ Apple Watch companion (PawWatch)** — a **standalone** watchOS app that reads
  HealthKit on the wrist and shows a step ring, city and temperature, even without the
  phone.
- **🐱 Personalisation** — pick a companion cat and switch the colour palette at runtime.
- **☁️ Real-time cross-device sync** — sign in anywhere; your data follows you.

---

## 🏗️ Architecture

PawQuest uses a **layered, MVVM-flavoured** architecture with `provider` for reactive
state. Screens depend on providers; providers delegate to **stateless services**; only
services talk to Firebase, REST APIs and native platform channels. Domain and analytics
logic is kept free of Flutter and Firebase so it can be unit-tested in isolation.

```
Presentation (screens + screens/tablet + widgets)
        │  watches
State   (StepProvider · DailyQuestProvider · ThemeProvider)
        │  delegates to
Domain  (services + models + stats + utils — pure, testable)
        │  talks to
Data    (Firebase Auth/Firestore/Storage · OpenWeatherMap · Wikipedia · HealthKit · Watch)
```

The tablet edition is an **adaptive presentation of the same account and domain state**,
not a separate app: `ResponsiveMainScreen` switches to `TabletDashboardScreen` when the
device's shortest side is ≥ 600 dp.

---

## 📂 Repository Structure

```
lib/
├── main.dart                     # Bootstrap: Firebase init, MultiProvider, routing
├── models/                       # DailyQuestModel · WeatherModel
├── providers/                    # StepProvider · DailyQuestProvider · ThemeProvider
├── services/                     # Business logic & integrations
│   ├── auth_service.dart             # Email/password auth (FirebaseAuth)
│   ├── health_service.dart           # HealthKit   (channel: pawquest/health)
│   ├── watch_service.dart            # Apple Watch (channel: pawquest/watch)
│   ├── weather_service.dart          # OpenWeatherMap
│   ├── wiki_city_service.dart        # Wikipedia REST
│   ├── forum_service.dart            # Posts / likes / notifications (transactional)
│   ├── follow_service.dart           # Follow / follower graph
│   ├── daily_quest_service.dart      # Daily quest generation & progress
│   └── route_manager.dart            # City unlock orchestration
├── stats/                        # Pure step-analytics for the tablet dashboard
│   ├── daily_step.dart               # One day, parsed from step_history
│   ├── step_stats.dart               # Aggregation: totals, streaks, records, heatmap…
│   ├── stats_repository.dart         # Firestore loader (the only Firebase touch-point)
│   └── stats_config.dart             # Tunable goal / stride / calorie constants
├── screens/                      # Phone screens
│   └── tablet/                       # iPad pages: dashboard, overview, stats, badge,
│                                     # community, weather, profile
├── widgets/                      # CustomBottomBar · PageTitle · UserAvatar · UserName
├── theme/  ·  utils/             # AppPalette · Unlock · StepMath · MapCoordinates · Responsive
assets/config/                    # cities.json · food_details.json
ios/PawWatch Watch App/           # Standalone watchOS companion (SwiftUI)
test/  ·  integration_test/       # 14 unit + 2 widget + 1 end-to-end
```

---

## 🔥 Firestore Data Model

```
users/{uid}                       email · username · bio · currentStep · catId · palette
  ├── step_history/{date}         daily · total · timestamp
  ├── dailyQuests/{date}          goalSteps · currentSteps · completed · weatherMain
  ├── following/{targetUid}       · followers/{uid}
  └── notifications/{id}          type · actorId · postId · read
posts/{postId}                    authorId · text · imageUrl · likes · likedBy[]
  └── comments/{id}               authorId · text · createdAt
cities/{cityId}   (read-only)     name · order · stepRequired · badge · coordinates
```

Security rules restrict every user to their own subtree, keep `cities` read-only, and
prevent forged likes, comments or notifications. See [`firestore.rules`](./firestore.rules).

---

## 🛠️ Tech Stack

| Area | Choice |
|---|---|
| Framework | Flutter (Dart, SDK `>=3.3.0 <4.0.0`) |
| State | `provider` |
| Backend | Firebase Auth · Cloud Firestore · Firebase Storage |
| Charts | `fl_chart` (statistics dashboard & history) |
| Sensors | `pedometer`, `geolocator` |
| Native (iOS) | HealthKit + Apple Watch via `MethodChannel`; standalone watchOS app |
| External APIs | OpenWeatherMap, Wikipedia REST · *(watch)* Nominatim, Open-Meteo |
| UI | `google_fonts` (Fredoka / Nunito), cream/yellow palette, `audioplayers` |
| Config | `flutter_dotenv` (secrets kept out of git) |

---

## 🚀 Getting Started

**Prerequisites:** Flutter `>=3.3.0`, a configured Firebase project, an OpenWeatherMap key.

```bash
# 1. Dependencies
flutter pub get

# 2. Secrets — create a .env file at the project root
#    OPENWEATHER_API_KEY=your_key_here

# 3. Firebase config
#    Add google-services.json (Android) / GoogleService-Info.plist (iOS),
#    or run:  flutterfire configure

# 4. (once) deploy rules
firebase deploy --only firestore:rules,storage

# 5. Run
flutter run
```

> **iOS note:** HealthKit and the Apple Watch app require a **real device**; HealthKit
> authorisation does not resolve reliably on the watchOS simulator.

---

## 🧪 Testing

Four layers — model, domain/service, widget, and an end-to-end flow — plus native watch
tests.

```bash
flutter test                     # 14 unit + 2 widget tests
flutter test integration_test    # end-to-end weather/location flow
```

Covered: `Unlock` thresholds, daily-quest model/rules/refresh, weather model & service,
Wikipedia service, forum like/notification logic, map coordinates, logout coordination,
and the **`StepStats` analytics** (range totals, streaks, trends, records, weekday
pattern, heatmap). A requirement-to-test traceability matrix is in the design document.

---

## 🗺️ Roadmap

- [x] iPad edition — navigation-rail dashboards + step-statistics analytics
- [ ] iPad Split View / Slide Over polish
- [ ] Apple Watch complications (step ring on the watch face)
- [ ] Android Health Connect (parity with the iOS HealthKit path)
- [ ] Richer social graph and seasonal content

---

## 👥 Team
Anchen Peng -- 11031608

Built for **DIMA 2025/2026**, Politecnico di Milano — supervised by Prof. Luciano Baresi.
