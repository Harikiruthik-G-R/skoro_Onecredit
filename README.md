# skoro

# Skoro - Ride Sharing App

A comprehensive ride-sharing application built with Flutter, similar to Uber, featuring Firebase backend integration and Google Maps.

## Features

### For Riders
- **User Authentication**: Sign up and login with email/password
- **Location Services**: Real-time location tracking and address detection
- **Ride Booking**: Select pickup and drop locations on an interactive map
- **Vehicle Selection**: Choose from different vehicle types (Car, Auto, Van)
- **Fare Estimation**: Real-time fare calculation based on distance and vehicle type
- **Ride Tracking**: Track ride status from request to completion
- **Ride History**: View past rides and details

### For Drivers
- **Driver Dashboard**: Dedicated interface for drivers
- **Online/Offline Toggle**: Control availability for receiving ride requests
- **Real-time Ride Requests**: Receive and accept ride requests
- **Navigation**: Integrated map for navigation to pickup and drop locations
- **Ride Management**: Update ride status (Accepted, In Progress, Completed)
- **Earnings Tracking**: View ride history and earnings

### Technical Features
- **Real-time Database**: Firebase Firestore for live data synchronization
- **Authentication**: Firebase Auth with secure user management
- **Maps Integration**: Google Maps with custom markers and polylines
- **State Management**: Provider pattern for efficient state management
- **Responsive UI**: Adaptive design with flutter_screenutil
- **Navigation**: GoRouter for clean navigation flow

## Tech Stack

- **Framework**: Flutter 3.8.1+
- **Backend**: Firebase (Auth, Firestore, Storage)
- **Maps**: Google Maps API
- **State Management**: Provider
- **Navigation**: GoRouter
- **UI**: Material Design with custom components

## Dependencies

```yaml
dependencies:
  flutter:
    sdk: flutter
  firebase_core: ^2.24.2
  firebase_auth: ^4.15.3
  cloud_firestore: ^4.13.6
  firebase_storage: ^11.5.6
  google_maps_flutter: ^2.5.0
  geolocator: ^10.1.0
  geocoding: ^2.1.1
  provider: ^6.1.1
  flutter_screenutil: ^5.9.0
  go_router: ^12.1.3
  dio: ^5.4.0
  intl: ^0.19.0
  uuid: ^4.2.1
```

## Setup Instructions

### Prerequisites
1. Flutter SDK (3.8.1 or higher)
2. Android Studio / VS Code
3. Firebase project
4. Google Maps API key

### Firebase Setup
1. Create a new Firebase project at [Firebase Console](https://console.firebase.google.com/)
2. Enable Authentication (Email/Password)
3. Create Firestore Database
4. Download `google-services.json` and place it in `android/app/`
5. Configure Firebase for your package name: `com.harikiruthik.skoro`

### Google Maps Setup
1. Get Google Maps API key from [Google Cloud Console](https://console.cloud.google.com/)
2. Enable Maps SDK for Android
3. Add the API key to `android/app/src/main/AndroidManifest.xml`:
```xml
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="YOUR_API_KEY_HERE" />
```

### Installation
1. Clone the repository
2. Install dependencies:
```bash
flutter pub get
```
3. Configure Firebase and Google Maps as above
4. Run the app:
```bash
flutter run
```

## Project Structure

```
lib/
├── main.dart                 # App entry point
├── models/                   # Data models
│   ├── user_model.dart
│   └── ride_model.dart
├── providers/                # State management
│   ├── auth_provider.dart
│   ├── location_provider.dart
│   └── ride_provider.dart
├── screens/                  # UI screens
│   ├── auth/
│   │   ├── login_screen.dart
│   │   ├── signup_screen.dart
│   │   └── user_type_selection_screen.dart
│   ├── rider/
│   │   ├── rider_home_screen.dart
│   │   └── book_ride_screen.dart
│   └── driver/
│       └── driver_home_screen.dart
├── widgets/                  # Reusable widgets
│   ├── custom_button.dart
│   └── custom_text_field.dart
└── utils/                    # Utilities
    └── app_colors.dart
```

## Configuration

### Android Permissions
The app requires the following permissions (already configured):
- `ACCESS_FINE_LOCATION`
- `ACCESS_COARSE_LOCATION`
- `INTERNET`

### Firebase Collections
The app uses these Firestore collections:
- `users`: User profiles and authentication data
- `rides`: Ride requests and history

## Vehicle Types & Pricing

| Vehicle Type | Base Fare | Per KM Rate |
|--------------|-----------|-------------|
| Auto         | ₹30       | ₹12/km      |
| Car          | ₹50       | ₹15/km      |
| Van          | ₹80       | ₹20/km      |

## Ride Flow

### For Riders
1. Select user type (Rider)
2. Sign up/Login
3. Allow location permissions
4. Select pickup and drop locations
5. Choose vehicle type
6. Confirm booking
7. Track ride status
8. Complete ride and rate driver

### For Drivers
1. Select user type (Driver)
2. Sign up/Login
3. Toggle online status
4. Receive ride requests
5. Accept rides
6. Navigate to pickup location
7. Start trip after pickup
8. Complete trip at destination

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if needed
5. Submit a pull request

## License

This project is for educational purposes. Please ensure you have proper licensing for production use.

## Support

For issues and questions, please create an issue in the repository.

---

**Note**: Make sure to replace placeholder values like API keys and Firebase configuration with your actual credentials before running the app.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
