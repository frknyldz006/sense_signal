<div align="center">
  <h1>📡 Sense Signal</h1>
  <p><strong>Advanced Network & Device Radar Application</strong></p>
  
  <p>
    <a href="https://flutter.dev/"><img src="https://img.shields.io/badge/Flutter-%2302569B.svg?style=for-the-badge&logo=Flutter&logoColor=white" alt="Flutter"></a>
    <a href="https://dart.dev/"><img src="https://img.shields.io/badge/Dart-%230175C2.svg?style=for-the-badge&logo=dart&logoColor=white" alt="Dart"></a>
    <a href="https://riverpod.dev/"><img src="https://img.shields.io/badge/Riverpod-blue?style=for-the-badge&logo=flutter" alt="Riverpod"></a>
  </p>
</div>

<br/>

## 📖 About The Project

**Sense Signal** is an advanced mobile application built with Flutter that detects and analyzes surrounding Bluetooth Low Energy (BLE) and Wi-Fi devices. It presents the collected network and device data on a beautiful, interactive radar interface, allowing you to visualize your local digital environment.

With its sleek "Glassmorphism" UI, dynamic filtering, and real-time signal strength (RSSI) readings, Sense Signal is designed to give you a clear and engaging view of the invisible signals around you.

---

## ✨ Key Features

* 🎯 **Live Device Radar:** Continuously scans for and displays nearby Wi-Fi networks and Bluetooth BLE devices on an interactive map.
* 🎛️ **Advanced Filtering:** Easily filter devices based on distance to find exactly what you are looking for in your vicinity.
* 🧭 **Sensor & Location Integration:** Uses device sensors (`sensors_plus`) and location data (`geolocator`) to enhance radar accuracy and calculate heading/orientation.
* 🖌 **Modern Glass UI:** Features a premium, minimalist design with custom glass panel widgets and smooth animations.
* 📊 **Signal Analysis:** Reads and interprets real-time RSSI data to estimate the relative distance of detected devices.

---

## 🛠 Tech Stack & Packages

Sense Signal is developed using modern Flutter development practices and powerful community packages:

- **State Management:** [`flutter_riverpod`](https://pub.dev/packages/flutter_riverpod)
- **Bluetooth (BLE) Scanner:** [`flutter_blue_plus`](https://pub.dev/packages/flutter_blue_plus)
- **Wi-Fi Scanner:** [`wifi_scan`](https://pub.dev/packages/wifi_scan)
- **Location Services:** [`geolocator`](https://pub.dev/packages/geolocator)
- **Device Sensors:** [`sensors_plus`](https://pub.dev/packages/sensors_plus), [`vector_math`](https://pub.dev/packages/vector_math)
- **Permissions:** [`permission_handler`](https://pub.dev/packages/permission_handler)
- **Typography:** [`google_fonts`](https://pub.dev/packages/google_fonts)

---

## 🚀 Getting Started

Follow these instructions to get a copy of the project up and running on your local machine for development and testing purposes.

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (Requires SDK `>=3.10.8`)
- Android Studio, VS Code, or Xcode installed.
- **Physical Device Strongly Recommended:** Testing on a physical Android or iOS device is required as emulators do not reliably support hardware BLE and Wi-Fi scanning.

### Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/frknyldz006/sense_signal.git
   ```

2. Navigate to the project directory:
   ```bash
   cd sense_signal
   ```

3. Install all necessary dependencies:
   ```bash
   flutter pub get
   ```

4. Run the application on your connected physical device:
   ```bash
   flutter run
   ```

> **Note:** Upon launching the app for the first time, you will be prompted to grant Location and Nearby Devices (Bluetooth) permissions. These are strictly required for the radar to function properly.

---

## 📂 Project Structure

The project is structured to keep UI, business logic, and services cleanly separated, strictly following Riverpod best practices:

```text
lib/
├── core/             # Core configurations and utilities
├── models/           # Data models (e.g., DeviceModel, SignalModel)
├── providers/        # Riverpod State Notifiers and Providers controlling the logic
├── services/         # Handlers for BLE, Wi-Fi, and Location services
├── ui/               # Visualization layer
│   ├── screens/      # Main application screens (e.g., RadarScreen)
│   └── widgets/      # Reusable UI components (Control panels, Glass overlays)
└── main.dart         # The entry point of the app
```

---

<div align="center">
  <sub>Built with ❤️ using Flutter.</sub>
</div>
