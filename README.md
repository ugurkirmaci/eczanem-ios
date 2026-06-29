<p align="center">
  <img src="docs/screenshots/list.png" width="120" alt="Eczanem App" />
</p>

<h1 align="center">Eczanem 💊</h1>

<p align="center">
  Find on-duty pharmacies across Turkey instantly — GPS-powered, fast and reliable.
</p>

<p align="center">
  <img src="https://img.shields.io/badge/iOS-16.0%2B-blue?logo=apple" />
  <img src="https://img.shields.io/badge/Swift-5.9-orange?logo=swift" />
  <img src="https://img.shields.io/badge/SwiftUI-✓-green" />
  <img src="https://img.shields.io/badge/Firebase-10.29-orange?logo=firebase" />
  <img src="https://img.shields.io/badge/License-MIT-lightgrey" />
</p>

---

## 📱 Screenshots

<p align="center">
  <img src="docs/screenshots/login.png" width="180" alt="Login" />
  <img src="docs/screenshots/list.png" width="180" alt="Pharmacy List" />
  <img src="docs/screenshots/map.png" width="180" alt="Map" />
  <img src="docs/screenshots/quick-access.png" width="180" alt="Quick Access" />
  <img src="docs/screenshots/profile.png" width="180" alt="Profile" />
</p>

---

## ✨ Features

| Feature | Description |
|---|---|
| 📍 **GPS Auto-Location** | Detects your province and district automatically |
| 🏥 **Nearest Pharmacy** | Sorts by distance when GPS is active, badges the closest with "NEAREST" |
| 🗺️ **Map View** | All on-duty pharmacies shown as pins on a live map |
| 📞 **One-tap Call** | Call a pharmacy with a confirmation dialog |
| 🧭 **Directions** | Turn-by-turn driving directions via Apple Maps |
| ⚡ **Quick Access** | Save favourite cities, load their pharmacies in one tap |
| 🔍 **Search & Filter** | Filter by name, address or district |
| 🔐 **Secure Auth** | Email, Apple Sign In and Google Sign In via Firebase |
| 🌙 **Dark Mode** | Full iOS Dark Mode support |
| 📤 **Share** | Share pharmacy details with friends |

---

## 🏗️ Architecture

```
Eczanem/
├── App/
│   └── EczanemApp.swift              # @main entry, AppDelegate, Firebase init
├── Models/
│   ├── Pharmacy.swift                # Pharmacy data model + province list
│   └── AppErrors.swift               # Typed error enums
├── Services/
│   ├── PharmacyService.swift         # CollectAPI HTTP layer
│   ├── LocationService.swift         # CoreLocation async/await wrapper
│   └── QuickLocationsService.swift   # UserDefaults-backed saved locations
├── ViewModels/
│   ├── PharmacyViewModel.swift       # List state, cache, distance sorting
│   └── AuthViewModel.swift           # Firebase Auth (Email / Apple / Google)
├── Views/
│   ├── Auth/                         # Login, Register, ForgotPassword, Splash
│   ├── Pharmacy/                     # List, Map, Row card
│   ├── QuickLocationsView.swift      # Quick Access tab
│   └── MainTabView.swift             # Tab bar + ProfileView
└── Core/
    └── Persistence/                  # Core Data stack (ready for expansion)
```

**Pattern:** MVVM + Service Layer  
**Async:** Swift Concurrency — `async/await`, `CheckedContinuation`  
**State:** `ObservableObject` + `@Published` + Combine  

---

## 🛠️ Tech Stack

| Library | Purpose |
|---|---|
| **SwiftUI** | Declarative UI — iOS 16+ |
| **Firebase Auth 10.29** | Email, Apple and Google Sign In |
| **CollectAPI** | On-duty pharmacy data for Turkey |
| **CoreLocation** | GPS fix + reverse geocoding |
| **MapKit** | Interactive map view |
| **Core Data** | Local persistence (ready for expansion) |
| **XcodeGen** | Code-based Xcode project generation |

---

## ⚙️ Setup

### Prerequisites

- Xcode 15+
- iOS 16+ device or simulator
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) — `brew install xcodegen`
- CollectAPI account — [collectapi.com](https://collectapi.com)
- Firebase project — [console.firebase.google.com](https://console.firebase.google.com)

---

### 1. Clone the repo

```bash
git clone https://github.com/ugurkirmaci/eczanem-ios.git
cd eczanem-ios
```

### 2. Add secret configuration

**CollectAPI key:**

```bash
cp Configurations/Secrets.xcconfig.example Configurations/Secrets.xcconfig
```

Open `Configurations/Secrets.xcconfig` and fill in your key:

```
COLLECT_API_KEY = YOUR_COLLECTAPI_KEY_HERE
```

**Firebase configuration:**

```bash
cp Eczanem/GoogleService-Info.plist.example Eczanem/GoogleService-Info.plist
```

Replace the file with the real `GoogleService-Info.plist` downloaded from your Firebase project.

> Firebase Console → Project Settings → iOS app → Download GoogleService-Info.plist

### 3. Enable Firebase Auth providers

In Firebase Console → Authentication → Sign-in method, enable:
- **Email / Password** ✓
- **Apple** ✓
- **Google** ✓

### 4. Generate the Xcode project

```bash
xcodegen generate
```

### 5. Open and run

```bash
open Eczanem.xcodeproj
```

Select a target device in Xcode → **Cmd+R**

---

## 🔐 Security

This repository contains **no real credentials**.

| File | Status | Why |
|---|---|---|
| `GoogleService-Info.plist` | Gitignored | Contains Firebase API key and project IDs |
| `Configurations/Secrets.xcconfig` | Gitignored | Contains CollectAPI key |
| `Info.plist` | Committed ✓ | Only holds `$(COLLECT_API_KEY)` placeholder |

Before making your own fork public, run `git log -p` to verify no real keys were accidentally committed.

---

## 📡 API

Pharmacy data is sourced from [CollectAPI](https://collectapi.com/api/health/pharmaciesApi).

```
GET https://api.collectapi.com/health/dutyPharmacy?il=Ankara&ilce=Cankaya
Authorization: apikey YOUR_KEY
```

**Rate limiting:** CollectAPI enforces request limits on free plans. The app uses a 5-minute cache per city/district to avoid hitting the limit on tab switches.

---

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/my-feature`
3. Commit your changes: `git commit -m 'feat: add my feature'`
4. Push: `git push origin feature/my-feature`
5. Open a Pull Request

---

## 📄 License

MIT License — see [LICENSE](LICENSE) for details.

---

<p align="center">
  Made with ❤️ for patients across Turkey
</p>
