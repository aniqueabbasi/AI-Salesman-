# Product Recommendation System Frontend

This is a simple web interface for the Product Recommendation System API.

## Features

- Train the recommendation model with custom parameters
- Get product recommendations based on selected attributes
- View association rules with filtering options

## Running the Frontend

### Option 1: Using the included Python server

1. Make sure Python is installed on your system
2. Run the server:
   ```
   python server.py
   ```
3. Open your browser and navigate to http://localhost:8080

### Option 2: Using any web server

You can serve these static files using any web server of your choice, such as:

- Python's built-in HTTP server: `python -m http.server 8080`
- Node.js http-server: `npx http-server -p 8080`
- Apache, Nginx, etc.

## Usage

1. First, make sure the backend API is running at http://localhost:8000
2. Use the "Train Recommendation Model" section to train the model with your desired parameters
3. Use the "Get Recommendations" section to get product recommendations based on attributes
4. Use the "Association Rules" section to view and filter the mined rules

## API Endpoints Used

The frontend interacts with the following API endpoints:

- `POST /api/train` - Train the recommendation model
- `POST /api/recommend` - Get recommendations based on attributes
- `GET /api/rules` - Get association rules with filtering

## Technologies Used

- HTML5
- CSS3
- JavaScript (ES6+)
- Bootstrap 5 for styling 