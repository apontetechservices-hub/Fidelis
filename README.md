# Fidelis — Traditional Catholic Prayer App

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-3.41-blue" alt="Flutter">
  <img src="https://img.shields.io/badge/License-Proprietary-red" alt="License">
</p>

## Features

- 📿 **Interactive Rosary** — Bead-by-bead prayer flow with all 20 mysteries
- 📖 **Daily Mass Readings** — 1962 Roman Missal propers (English + Latin)
- 📅 **1962 Liturgical Calendar** — Full year of saints, feasts, and liturgical colors
- 🙏 **Traditional Prayers** — 30+ Catholic prayers with Latin titles
- ✝️ **Rosary for the Dead** — Including De Profundis and Eternal Rest
- 🇻🇦 **Latin/English/Spanish** — Full trilingual support for the rosary
- 📱 **Offline-First** — Cached data works without internet

## Architecture

```
lib/
├── main.dart                    # App entry point
├── app.dart                     # MaterialApp configuration
├── home_screen.dart             # Dashboard with live feast data
├── config/
│   ├── constants.dart           # App constants
│   ├── routes.dart              # Navigation routes
│   └── theme.dart               # Sacred art theme (Cinzel, Lora, etc.)
├── features/
│   ├── rosary/
│   │   ├── rosary_screen.dart       # Mystery selection
│   │   ├── rosary_prayer_screen.dart # Interactive bead-by-bead flow
│   │   ├── rosary_controller.dart    # Step builder & logic
│   │   ├── rosary_prayers.dart       # Core prayers (EN/LA/ES)
│   │   ├── mystery_data.dart         # 20 mysteries + meditations
│   │   └── litany_of_loreto.dart     # 58 invocations (EN/LA/ES)
│   ├── readings/
│   │   ├── readings_screen.dart      # Daily Mass propers
│   │   ├── missal_service.dart       # Missale Meum API client
│   │   ├── missal_cache.dart         # SQLite offline cache
│   │   └── bible_books.dart          # Scripture reference parser
│   ├── saints/
│   │   └── saints_screen.dart        # 1962 calendar browser
│   ├── prayers/
│   │   └── prayers_screen.dart       # 30+ traditional prayers
│   └── settings/
│       └── settings_screen.dart      # Preferences & notifications
└── services/
    └── notification_service.dart     # Push notification stubs
```

## Data Sources

- **Missale Meum API** — 1962 Roman Missal calendar & propers (MIT License)
- **Divinum Officium** — Traditional breviary & missal texts
- **Douay-Rheims Bible** — Scripture text (public domain)
- **RSV-CE** — Scripture text (copyright, used by permission pending)

## Getting Started

```bash
# Install dependencies
flutter pub get

# Run on device/emulator
flutter run

# Build APK
flutter build apk --release

# Build iOS
flutter build ios --release
```

## No Ads. Ever.

Prayer is sacred. Fidelis will never show advertisements.

## License

Proprietary. All rights reserved.