#!/bin/bash

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check if curl is installed
if ! command_exists curl; then
    echo "Error: curl is not installed. Please install curl and try again."
    exit 1
fi

# Start the backend
echo "Starting the backend for testing..."
cd ecom_FYP-main || { echo "Error: ecom_FYP-main directory not found"; exit 1; }

# Activate virtual environment if it exists
if [ -d ".venv" ]; then
    if [ -f ".venv/Scripts/activate" ]; then
        # Windows
        source .venv/Scripts/activate
    else
        # macOS/Linux
        source .venv/bin/activate
    fi
fi

# Start the backend server in the background
python -m app.main &
BACKEND_PID=$!

# Wait for the backend to start
echo "Waiting for backend to start..."
sleep 5

# Test the API endpoints
echo "Testing API endpoints..."

# Test the root endpoint
echo "Testing root endpoint..."
ROOT_RESPONSE=$(curl -s http://127.0.0.1:8001/)
if [[ $ROOT_RESPONSE == *"Welcome to the E-Commerce API"* ]]; then
    echo "Root endpoint test: PASSED"
else
    echo "Root endpoint test: FAILED"
    echo "Response: $ROOT_RESPONSE"
fi

# Test the products endpoint
echo "Testing products endpoint..."
PRODUCTS_RESPONSE=$(curl -s http://127.0.0.1:8001/products)
if [[ $PRODUCTS_RESPONSE == *"["* ]]; then
    echo "Products endpoint test: PASSED"
else
    echo "Products endpoint test: FAILED"
    echo "Response: $PRODUCTS_RESPONSE"
fi

# Test the auth endpoint
echo "Testing auth endpoint..."
AUTH_RESPONSE=$(curl -s -X POST http://127.0.0.1:8001/auth/signup -H "Content-Type: application/json" -d '{"email":"test@example.com","password":"password123","is_admin":false}')
if [[ $AUTH_RESPONSE == *"User created"* ]]; then
    echo "Auth endpoint test: PASSED"
else
    echo "Auth endpoint test: FAILED"
    echo "Response: $AUTH_RESPONSE"
fi

# Stop the backend
echo "Stopping the backend..."
kill $BACKEND_PID

echo "Integration test completed." 