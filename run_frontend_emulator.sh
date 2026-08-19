#!/bin/bash

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check if Flutter is installed
if ! command_exists flutter; then
    echo "Error: Flutter is not installed. Please install Flutter SDK and try again."
    exit 1
fi

# Check if we need to start an emulator
./start_emulator.sh

# Navigate to the frontend directory
cd Anique-Shah-Saleem-master || { echo "Error: Anique-Shah-Saleem-master directory not found"; exit 1; }

# Install dependencies if needed
if [ ! -d "build" ]; then
    echo "Installing Flutter dependencies..."
    flutter pub get
fi

# Check available devices
echo "Checking available devices..."
DEVICES=$(flutter devices)
echo "$DEVICES"

# Ask user which device to use
echo ""
echo "Please select a device to run the app on:"
echo "1. Android emulator"
echo "2. iOS simulator"
echo "3. Use first available device"
read -p "Enter your choice (1-3): " DEVICE_CHOICE

case $DEVICE_CHOICE in
    1)
        # Check if Android emulator is available
        if [[ "$DEVICES" == *"android"* ]] || [[ "$DEVICES" == *"Android"* ]]; then
            echo "Starting app on Android emulator..."
            flutter run -d android
        else
            echo "No Android emulator found. Using first available device..."
            flutter run
        fi
        ;;
    2)
        # Check if iOS simulator is available
        if [[ "$DEVICES" == *"ios"* ]] || [[ "$DEVICES" == *"iOS"* ]]; then
            echo "Starting app on iOS simulator..."
            flutter run -d ios
        else
            echo "No iOS simulator found. Using first available device..."
            flutter run
        fi
        ;;
    3)
        # Use first available device
        echo "Using first available device..."
        flutter run
        ;;
    *)
        echo "Invalid choice. Using first available device..."
        flutter run
        ;;
esac 