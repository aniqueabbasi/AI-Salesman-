#!/bin/bash

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check if Python is installed
if ! command_exists python; then
    echo "Error: Python is not installed. Please install Python 3.8+ and try again."
    exit 1
fi

# Check if Flutter is installed
if ! command_exists flutter; then
    echo "Error: Flutter is not installed. Please install Flutter SDK and try again."
    exit 1
fi

# Start the backend
echo "Starting the backend..."
cd ecom_FYP-main || { echo "Error: ecom_FYP-main directory not found"; exit 1; }

# Check if requirements are installed
if [ ! -d ".venv" ]; then
    echo "Creating virtual environment..."
    python -m venv .venv
    
    # Activate virtual environment
    if [ -f ".venv/Scripts/activate" ]; then
        # Windows
        source .venv/Scripts/activate
    else
        # macOS/Linux
        source .venv/bin/activate
    fi
    
    echo "Installing dependencies..."
    pip install -r requirements.txt
else
    # Activate virtual environment
    if [ -f ".venv/Scripts/activate" ]; then
        # Windows
        source .venv/Scripts/activate
    else
        # macOS/Linux
        source .venv/bin/activate
    fi
fi

# Start the backend server
python -m app.main &
BACKEND_PID=$!

# Wait for the backend to start
echo "Waiting for backend to start..."
sleep 5

# Start the frontend
echo "Starting the frontend..."
cd ../Anique-Shah-Saleem-master || { echo "Error: Anique-Shah-Saleem-master directory not found"; exit 1; }

# Check if dependencies are installed
if [ ! -d "build" ]; then
    echo "Installing Flutter dependencies..."
    flutter pub get
fi

# Check if we need to start an emulator
cd ..
./start_emulator.sh

# Go back to the frontend directory
cd Anique-Shah-Saleem-master || { echo "Error: Anique-Shah-Saleem-master directory not found"; exit 1; }

# Check available devices
echo "Checking available devices..."
DEVICES=$(flutter devices)
echo "$DEVICES"

# Ask user which device to use
echo ""
echo "Please select a device to run the app on:"
echo "1. Android emulator"
echo "2. iOS simulator"
echo "3. Chrome browser"
echo "4. Use first available device"
read -p "Enter your choice (1-4): " DEVICE_CHOICE

case $DEVICE_CHOICE in
    1)
        # Check if Android emulator is available
        if [[ "$DEVICES" == *"android"* ]] || [[ "$DEVICES" == *"Android"* ]]; then
            echo "Starting app on Android emulator..."
            flutter run -d android &
        else
            echo "No Android emulator found. Using first available device..."
            flutter run &
        fi
        ;;
    2)
        # Check if iOS simulator is available
        if [[ "$DEVICES" == *"ios"* ]] || [[ "$DEVICES" == *"iOS"* ]]; then
            echo "Starting app on iOS simulator..."
            flutter run -d ios &
        else
            echo "No iOS simulator found. Using first available device..."
            flutter run &
        fi
        ;;
    3)
        # Check if Chrome is available
        if [[ "$DEVICES" == *"chrome"* ]] || [[ "$DEVICES" == *"Chrome"* ]]; then
            echo "Starting app on Chrome..."
            flutter run -d chrome &
        else
            echo "Chrome not available. Using first available device..."
            flutter run &
        fi
        ;;
    4)
        # Use first available device
        echo "Using first available device..."
        flutter run &
        ;;
    *)
        echo "Invalid choice. Using first available device..."
        flutter run &
        ;;
esac

FRONTEND_PID=$!

# Function to handle script termination
cleanup() {
    echo "Stopping the backend and frontend..."
    kill $BACKEND_PID
    kill $FRONTEND_PID
    exit
}

# Trap SIGINT (Ctrl+C) and call cleanup
trap cleanup SIGINT

# Wait for user to press Ctrl+C
echo "Press Ctrl+C to stop both servers"
wait 