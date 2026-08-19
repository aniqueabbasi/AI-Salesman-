# Running the E-Commerce App on Emulators

This guide explains how to run the e-commerce application on Android emulators or iOS simulators.

## Prerequisites

- Flutter SDK installed
- Android Studio (for Android emulators)
- Xcode (for iOS simulators)
- At least one emulator/simulator created

## Using the Scripts

We've provided several scripts to make running the application on emulators easier:

### 1. Start an Emulator

```bash
./start_emulator.sh
```

This script will:
- Check if any device is already running
- If not, ask you which type of emulator to start (Android or iOS)
- List available emulators/simulators
- Start the selected emulator/simulator

### 2. Run the Frontend on an Emulator

```bash
./run_frontend_emulator.sh
```

This script will:
- Check if an emulator is running (and start one if needed)
- Install dependencies if needed
- Ask you which device to use
- Run the app on the selected device

### 3. Run Both Frontend and Backend

```bash
./run_app.sh
```

This script will:
- Start the backend server
- Check if an emulator is running (and start one if needed)
- Ask you which device to use
- Run the app on the selected device

## Manual Setup

If you prefer to run the app manually:

1. Start the backend:
   ```bash
   cd ecom_FYP-main
   python -m app.main
   ```

2. Start an emulator using Android Studio or Xcode

3. Run the frontend:
   ```bash
   cd Anique-Shah-Saleem-master
   flutter run -d android  # For Android
   # OR
   flutter run -d ios      # For iOS
   ```

## API Base URL Configuration

The app is configured to automatically use the correct base URL for the API:
- For Android emulators: `http://10.0.2.2:8001`
- For iOS simulators: `http://127.0.0.1:8001`
- For web browsers: `http://127.0.0.1:8001`

This is handled in the `ApiService` class in `lib/services/api_service.dart`.

## Troubleshooting

If you encounter issues:

1. Make sure the backend is running
2. Check that the emulator is properly started
3. Verify that the app can connect to the backend
4. If you're using an Android emulator, make sure it's using API level 28 or higher
5. For iOS simulators, make sure you're using iOS 13 or higher 