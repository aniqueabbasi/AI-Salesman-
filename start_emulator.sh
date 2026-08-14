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

# Check available devices
echo "Checking available devices..."
DEVICES=$(flutter devices)
echo "$DEVICES"

# Check if any device is available
if [[ "$DEVICES" == *"No devices available"* ]]; then
    echo "No devices available. Let's start an emulator."
    
    # Ask user which type of emulator to start
    echo ""
    echo "Which type of emulator would you like to start?"
    echo "1. Android emulator"
    echo "2. iOS simulator"
    read -p "Enter your choice (1-2): " EMULATOR_CHOICE
    
    case $EMULATOR_CHOICE in
        1)
            # Try to start an Android emulator
            if command_exists emulator; then
                # List available emulators
                echo "Listing available Android emulators..."
                EMULATORS=$(emulator -list-avds)
                
                if [ -z "$EMULATORS" ]; then
                    echo "No Android emulators found. Please create one using Android Studio."
                    exit 1
                else
                    echo "Available emulators:"
                    echo "$EMULATORS"
                    
                    # Ask user which emulator to start
                    echo ""
                    echo "Enter the name of the emulator to start (or press Enter to use the first one):"
                    read -p "> " SELECTED_EMULATOR
                    
                    if [ -z "$SELECTED_EMULATOR" ]; then
                        # Use the first emulator in the list
                        SELECTED_EMULATOR=$(echo "$EMULATORS" | head -n 1)
                    fi
                    
                    echo "Starting emulator: $SELECTED_EMULATOR"
                    emulator -avd "$SELECTED_EMULATOR" &
                    
                    echo "Waiting for emulator to start..."
                    sleep 20
                    
                    # Check if emulator started successfully
                    NEW_DEVICES=$(flutter devices)
                    if [[ "$NEW_DEVICES" == *"android"* ]] || [[ "$NEW_DEVICES" == *"Android"* ]]; then
                        echo "Emulator started successfully!"
                    else
                        echo "Failed to start emulator. Please start it manually."
                        exit 1
                    fi
                fi
            else
                echo "Android emulator command not found. Please start an emulator manually."
                exit 1
            fi
            ;;
        2)
            # Try to start an iOS simulator
            if command_exists xcrun; then
                echo "Starting iOS simulator..."
                xcrun simctl boot "iPhone 14" || xcrun simctl boot "iPhone 13" || xcrun simctl boot "iPhone 12" || {
                    echo "Failed to start iOS simulator. Please start it manually."
                    exit 1
                }
                
                echo "Waiting for simulator to start..."
                sleep 10
                
                # Check if simulator started successfully
                NEW_DEVICES=$(flutter devices)
                if [[ "$NEW_DEVICES" == *"ios"* ]] || [[ "$NEW_DEVICES" == *"iOS"* ]]; then
                    echo "Simulator started successfully!"
                else
                    echo "Failed to start simulator. Please start it manually."
                    exit 1
                fi
            else
                echo "iOS simulator command not found. Please start a simulator manually."
                exit 1
            fi
            ;;
        *)
            echo "Invalid choice. Please start an emulator manually."
            exit 1
            ;;
    esac
else
    echo "Device(s) already available. You can run the app using one of these devices."
fi

echo "Done!" 