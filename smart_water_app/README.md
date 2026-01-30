# Smart Water Conservation App

A Flutter application for the Smart Water Conservation System. Features real-time water monitoring, animated dashboards, analytics charts, and alert management.

## 🎨 Features

- **Animated Dashboard** - Live water tank indicator with smooth fill animations
- **Analytics Charts** - Daily/weekly water usage with fl_chart
- **Alert Management** - Priority-based alert system with filtering
- **Dark/Light Theme** - User-selectable theme with persistent settings
- **Cross-Platform** - Runs on Android, Web, and Windows Desktop

## 📱 Screens

| Screen | Description |
|--------|-------------|
| Dashboard | Live water level, flow rate, status indicators |
| Analytics | Line charts, bar charts, period selection |
| Alerts | Filterable alert list with priority badges |
| Settings | Theme toggle, threshold controls |

## 🚀 Quick Start

### Prerequisites

- Flutter SDK 3.0+ ([Install Flutter](https://flutter.dev/docs/get-started/install))
- Android Studio / VS Code with Flutter extensions
- Chrome (for web development)

### Setup

1. **Navigate to the app directory:**
   ```bash
   cd smart_water_app
   ```

2. **Install dependencies:**
   ```bash
   flutter pub get
   ```

3. **Start the Flask backend** (in another terminal):
   ```bash
   cd ../smart-water-iot-api
   python run.py
   ```

4. **Run the app:**

   **Web:**
   ```bash
   flutter run -d chrome
   ```

   **Windows Desktop:**
   ```bash
   flutter run -d windows
   ```

   **Android (with emulator running):**
   ```bash
   flutter run
   ```

## 🔧 Configuration

### API Base URL

Update the API URL in `lib/core/constants/app_constants.dart`:

```dart
static const String baseUrl = 'http://localhost:5000';
```

For production or different environments:
- **Local machine:** `http://localhost:5000`
- **Android emulator:** `http://10.0.2.2:5000`
- **Physical device:** Use your machine's IP address

## 📁 Project Structure

```
lib/
├── core/
│   ├── constants/      # App constants, colors
│   └── theme/          # Light/dark themes
├── data/
│   ├── models/         # Data models
│   └── services/       # API service layer
├── features/
│   ├── dashboard/      # Dashboard screen
│   ├── analytics/      # Charts screen
│   ├── alerts/         # Alerts screen
│   └── settings/       # Settings screen
├── shared/
│   └── widgets/        # Reusable components
└── main.dart           # App entry point
```

## 🎯 Key Components

### Animated Water Tank
Custom `WaterTankIndicator` widget with smooth fill animations and wave effects.

### Shimmer Loading
Loading placeholders with shimmer effect for better UX.

### Charts
- Line chart for water level trends
- Bar chart for daily consumption

## 🧪 Testing

```bash
flutter test
```

## 📦 Building

**APK (Android):**
```bash
flutter build apk --release
```

**Web:**
```bash
flutter build web
```

**Windows:**
```bash
flutter build windows
```

## 📄 License

MIT License
