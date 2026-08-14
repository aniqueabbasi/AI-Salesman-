# Product Recommendation System

A FastAPI service for product recommendations using association rule mining (Apriori algorithm) from mlxtend.

## Features

- Preprocess products to extract useful features for transaction-style data
- Use `mlxtend.frequent_patterns.apriori` and `association_rules` to mine association rules
- Recommend products based on matching association rules
- **Automatic model persistence** - trained models are saved to disk and loaded automatically on startup
- **Model status checking** - easy way to check if the model is trained and ready
- Web-based frontend for easy interaction with the API

## Requirements

- Python 3.8+
- MongoDB
- Dependencies listed in `requirements.txt`

## Installation

1. Clone the repository
2. Create a virtual environment:
   ```
   python -m venv venv
   ```
3. Activate the virtual environment:
   - Windows: `venv\Scripts\activate`
   - Linux/Mac: `source venv/bin/activate`
4. Install dependencies:
   ```
   pip install -r requirements.txt
   ```
5. Configure MongoDB connection in `.env` file:
   ```
   MONGO_URI=mongodb://localhost:27017
   DB_NAME=recommendation_system
   LOG_LEVEL=INFO
   ```

## Loading Sample Data

Load the sample data into MongoDB:

```
python -m app.utils.data_loader
```

## Running the Application

### Option 1: Using the batch file (Windows)

For Windows users, simply run the batch file to start both servers:

```
start_servers.bat
```

This will start both the backend API and the frontend server, and open the frontend in your default browser.

### Option 2: Manual startup

1. Start the FastAPI server:
   ```
   uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
   ```

2. Start the frontend server:
   ```
   python frontend/server.py
   ```

3. Open your browser and navigate to:
   - Frontend: http://localhost:8080
   - API documentation: http://localhost:8000/docs

## Model Persistence

**NEW: No more repeated training!** The system now automatically saves trained models to disk and loads them on startup.

### How it works:
1. **First time**: Train the model using `POST /api/train`
2. **Subsequent starts**: The model is automatically loaded from disk - no training needed!
3. **Model files**: Stored in the `models/` directory
   - `recommendation_model.pkl` - The trained model data
   - `model_metadata.txt` - Training parameters and statistics

### Check Model Status

Use the provided script to check if your model is ready:

```bash
python check_model_status.py
```

Or check via API:

```bash
curl "http://localhost:8000/api/model/status"
```

### Benefits:
- ✅ **No repeated training** - Train once, use forever
- ✅ **Faster startup** - Model loads instantly on server restart
- ✅ **Persistent across restarts** - Your trained model survives server restarts
- ✅ **Easy status checking** - Know immediately if model is ready

## Frontend

The application includes a web-based frontend for easy interaction with the API. The frontend allows you to:

- Train the recommendation model with custom parameters
- Get product recommendations based on selected attributes
- View and filter association rules

For more details about the frontend, see [frontend/README.md](frontend/README.md).

## API Endpoints

### Check Model Status

```
GET /api/model/status
```

Returns the current status of the recommendation model and detailed information.

### Train the Recommendation Model

```
POST /api/train
```

Query Parameters:
- `min_support`: Minimum support for Apriori (default: 0.01)
- `min_confidence`: Minimum confidence for association rules (default: 0.5)
- `min_lift`: Minimum lift for association rules (default: 1.0)

**Note**: The model is automatically saved to disk after training.

### Get Recommendations

```
POST /api/recommend
```

Request Body:
```json
{
  "attributes": [
    {
      "attribute_type": "brand",
      "attribute_value": "Nike"
    },
    {
      "attribute_type": "Color",
      "attribute_value": "Black"
    }
  ],
  "min_confidence": 0.5,
  "min_lift": 1.0,
  "max_results": 10
}
```

### Get Association Rules

```
GET /api/rules
```

Query Parameters:
- `min_confidence`: Minimum confidence for filtering rules (default: 0.5)
- `min_lift`: Minimum lift for filtering rules (default: 1.0)
- `antecedent_contains`: Filter rules by antecedent containing this string (optional)

## Example Usage (API)

### First Time Setup

1. Check if model is trained:
   ```bash
   curl "http://localhost:8000/api/model/status"
   ```

2. If not trained, train the model (only needed once):
   ```bash
   curl -X POST "http://localhost:8000/api/train?min_support=0.01&min_confidence=0.5&min_lift=1.0"
   ```

### Regular Usage

3. Get recommendations (no training needed):
   ```bash
   curl -X POST "http://localhost:8000/api/recommend" \
     -H "Content-Type: application/json" \
     -d '{"attributes": [{"attribute_type": "brand", "attribute_value": "Nike"}], "min_confidence": 0.5, "min_lift": 1.0, "max_results": 5}'
   ```

4. View all rules:
   ```bash
   curl "http://localhost:8000/api/rules?min_confidence=0.5&min_lift=1.0"
   ```

## Quick Start Guide

1. **Start the server**: `python run.py` or `start_servers.bat`
2. **Check model status**: `python check_model_status.py`
3. **Train model** (if needed): `curl -X POST "http://localhost:8000/api/train"`
4. **Use the system**: The model is now ready for recommendations!

**That's it!** Once trained, the model will automatically load on every server restart. 