# Fidelis — Google Play Store Listing

## App Details

| Field | Value |
|---|---|
| **App name** | Fidelis |
| **Package name** | com.fidelis.fidelis |
| **Version** | 1.0.0 (versionCode 1) |
| **AAB file** | `build/app/outputs/bundle/release/app-release.aab` (52.8 MB) |
| **Keystore** | `android/fidelis-release.keystore` |
| **Keystore password** | `F1d3l1sPlay2026!` |
| **Key alias** | `fidelis` |
| **Key password** | `F1d3l1sPlay2026!` |
| **Contact email** | fidelis.app.contact@gmail.com |

---

## Store Listing

### Short description (80 char max)

Traditional Catholic prayer companion. Rosary, daily readings, chaplets — no ads, ever.

### Full description (4000 char max)

Fidelis is a traditional Catholic prayer companion built for faithful Catholics who want a reverent, ad-free prayer experience.

♰ HOLY ROSARY ♰
Pray the Rosary in English, Latin, or Spanish. All four mystery sets (Joyful, Sorrowful, Glorious, Luminous) with toggle for traditional vs. luminous. Includes the Rosary for the Dead and the Litany of the Blessed Virgin Mary.

♰ DAILY MASS READINGS ♰
Get daily Mass readings from the 1962 Traditional Latin Missal (Divinum Officium) AND the Novus Ordo (USCCB). Includes daily Gospel, Epistle, Saint of the Day, and reflections.

♰ STATIONS OF THE CROSS ♰
Two traditional methods: St. Francis of Assisi and the Pre-1955 Traditional form with Stabat Mater hymn in Latin and English. Station-by-station navigation with progress indicator.

♰ CHAPLETS ♰
Chaplet of Divine Mercy, Chaplet of St. Michael, Chaplet of the Holy Spirit, and more.

♰ NOVENAS ♰
Novena to the Sacred Heart, Our Lady of Fatima, and other traditional devotions with day-by-day tracking.

♰ COMMON PRAYERS ♰
Sign of the Cross, Our Father, Hail Mary, Glory Be, Act of Contrition, Angelus, Prayer to St. Michael, and more — all available in Latin, English, and Spanish.

♰ WHY FIDELIS? ♰
• No ads. Ever. Prayer is sacred.
• Latin + English side by side
• 1962 Traditional Latin Mass calendar
• Offline-first — works without internet
• Dark mode with reverent design
• Push notifications for prayer reminders
• Free core features forever

Built by traditional Catholics, for traditional Catholics.

---

## Graphics

| Asset | File | Size |
|---|---|---|
| Feature graphic | `play_store_assets/feature_graphic.png` | 1024×500 |
| Screenshot 1 - Rosary | `play_store_assets/screenshot_1_rosary.png` | 1080×1920 |
| Screenshot 2 - Readings | `play_store_assets/screenshot_2_readings.png` | 1080×1920 |
| Screenshot 3 - Stations | `play_store_assets/screenshot_3_stations.png` | 1080×1920 |
| Screenshot 4 - Chaplets | `play_store_assets/screenshot_4_chaplets.png` | 1080×1920 |
| Screenshot 5 - Prayers | `play_store_assets/screenshot_5_prayers.png` | 1080×1920 |
| Screenshot 6 - Design | `play_store_assets/screenshot_6_design.png` | 1080×1920 |

---

## Content Rating (IARC)

### Questionnaire Answers

| Question | Answer |
|---|---|
| Violence | None |
| Sexual content | None |
| Profanity | None |
| Controlled substances | None |
| User interaction | No (no chat, social, or user-generated content) |
| Information sharing | No (no personal data collected) |
| Purchases | No in-app purchases (yet — future premium tier planned) |
| Gambling | None |
| Ads | None |
| Age rating expected | **E (Everyone)** / **I (Infant)** — suitable for all ages |

---

## Store Category & Tags

| Field | Value |
|---|---|
| **Category** | Lifestyle |
| **Tags** | Catholic, Prayer, Rosary, Traditional, Latin Mass |
| **Content rating** | Everyone |

---

## Privacy Policy

- **URL:** Needs hosting (see Hosting Options below)
- **HTML file ready:** `play_store_assets/privacy_policy.html`
- **Markdown file:** `privacy_policy.md`

### Hosting Options for Privacy Policy

You need a public URL for the privacy policy. Options:

1. **GitHub Pages (Recommended — Free)**
   - Create a GitHub repo like `fidelis-app/fidelis-app.github.io`
   - Push the privacy_policy.html there
   - URL will be: `https://fidelis-app.github.io/`

2. **Google Sites (Free)**
   - Create a simple Google Sites page
   - Paste the privacy policy content

3. **Any web host**
   - Upload privacy_policy.html to any hosting you already have

---

## Pre-Upload Checklist

- [x] Release AAB built and signed ✅
- [x] Overlay code stripped ✅
- [x] Broken font files fixed (Cinzel Regular & Bold replaced) ✅
- [x] Privacy policy drafted ✅
- [x] Feature graphic created ✅
- [x] 6 screenshots created ✅
- [x] Keystore password saved ✅
- [ ] Create `fidelis.app.contact@gmail.com` (DONE — Chris confirmed)
- [ ] Host privacy policy at a public URL
- [ ] Create Google Play Console app listing
- [ ] Upload AAB
- [ ] Fill in store listing (copy from this doc)
- [ ] Upload feature graphic + screenshots
- [ ] Complete content rating questionnaire
- [ ] Set up internal testing track
- [ ] Add testers (can use your own Google accounts)

---

## Play Console Walkthrough

1. Go to https://play.google.com/console
2. Click **Create app**
3. Fill in: App name = "Fidelis", Language = English, Free, Category = Lifestyle
4. Accept the terms
5. In **Dashboard**, work through each section:
   - **Privacy policy** — paste the hosted URL
   - **App access** — all features available without login
   - **Ads** — no, this app does not contain ads
   - **Content rating** — complete IARC questionnaire (use answers above)
   - **Target audience** — 18+, not specifically for children
   - **Store listings** — upload graphics and paste descriptions from this doc
6. Go to **Production → Internal testing**
7. Upload the AAB file
8. Add tester email addresses
9. Review and release to internal testing track