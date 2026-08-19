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
echo "Starting the backend server at http://127.0.0.1:8001"
echo "Press Ctrl+C to stop the server"
python -m app.main 