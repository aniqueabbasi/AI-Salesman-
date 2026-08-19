# E-Commerce Application

This is an e-commerce application with a Flutter frontend and FastAPI backend. The application allows users to browse products, add them to a cart, and place orders.

## Prerequisites

- Python 3.8+
- Flutter SDK
- MongoDB (or use the mock database for development)
- Git Bash (for Windows users)
- Android Studio or Xcode (for emulators/simulators)

## Setup

### Backend Setup

1. Navigate to the backend directory:
   ```
   cd ecom_FYP-main
   ```

2. Create a virtual environment:
   ```
   python -m venv .venv
   ```

3. Activate the virtual environment:
   - On Windows:
     ```
     .venv\Scripts\activate
     ```
   - On macOS/Linux:
     ```
     source .venv/bin/activate
     ```

4. Install dependencies:
   ```
   pip install -r requirements.txt
   ```

5. Run the backend:
   ```
   python -m app.main
   ```

The backend will be available at http://127.0.0.1:8001.

### Frontend Setup

1. Navigate to the frontend directory:
   ```
   cd Anique-Shah-Saleem-master
   ```

2. Install dependencies:
   ```
   flutter pub get
   ```

3. Run the frontend:
   - On Chrome:
     ```
     flutter run -d chrome
     ```
   - On Android Emulator:
     ```
     flutter run -d android
     ```
   - On iOS Simulator:
     ```
     flutter run -d ios
     ```

## Running with Scripts

We've provided several scripts to make running the application easier:

1. Run both frontend and backend together:
   ```
   ./run_app.sh
   ```

2. Run just the backend:
   ```
   ./run_backend.sh
   ```

3. Run the frontend on an emulator:
   ```
   ./run_frontend_emulator.sh
   ```

## Running on Emulators

When running on emulators, the API base URL needs to be different:

- For Android emulators, use `10.0.2.2` instead of `127.0.0.1` to access the host machine
- For iOS simulators, use `127.0.0.1` as usual

The application is configured to automatically detect the platform and use the correct URL.

## API Documentation

The API documentation is available at http://127.0.0.1:8001/docs when the backend is running.

## Features

- User authentication (login/signup)
- Product browsing
- Shopping cart
- Order placement
- Order tracking
- User profile management

## Integration Details

The frontend and backend are integrated through a RESTful API. The frontend uses the following services to communicate with the backend:

- `ApiService`: Handles all API requests to the backend
- `ProductProvider`: Manages product state and fetches products from the API
- `CartProvider`: Manages cart state and creates orders through the API

## Troubleshooting

If you encounter any issues:

1. Make sure both the frontend and backend are running
2. Check the console for any error messages
3. Verify that the MongoDB connection is working (or the mock database is being used)
4. Ensure that the CORS middleware is properly set up in the backend
5. For emulator issues:
   - Make sure the emulator is running before starting the app
   - Check that the API base URL is correct for your platform
   - For Android, use `10.0.2.2` instead of `127.0.0.1`
   - For iOS, use `127.0.0.1`

## License

This project is licensed under the MIT License. 