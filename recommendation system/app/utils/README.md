# Utilities Documentation

This document explains the utility modules used in the recommendation system, focusing on database connectivity, data loading, and logging configuration.

## Overview

The `utils` folder contains several utility modules that provide essential functionality to the recommendation system:

1. `database.py`: Handles MongoDB connections and provides access to collections
2. `data_loader.py`: Loads and transforms product data from JSON files to MongoDB
3. `logging_config.py`: Configures logging for the application

These utilities support the core functionality of the recommendation system by providing the necessary infrastructure.

## 1. Database Utilities (`database.py`)

The `database.py` module provides functions for connecting to MongoDB and accessing collections.

### Key Functions

#### `init_db()`
- **Purpose**: Initializes the database connection
- **Input**: None (uses environment variables for configuration)
- **Output**: Database instance
- **Process**:
  1. Creates an AsyncIOMotorClient using the MongoDB URI from environment variables
  2. Sets up the database connection
  3. Verifies the connection with a ping command
  4. Returns the database instance

#### `get_db()`
- **Purpose**: Gets the database instance
- **Input**: None
- **Output**: Database instance
- **Process**: 
  1. Checks if the database has been initialized
  2. Returns the database instance if available
  3. Raises an exception if the database hasn't been initialized

#### `get_collection(collection_name)`
- **Purpose**: Gets a specific collection from the database
- **Input**: Collection name (string)
- **Output**: Collection instance
- **Process**: 
  1. Gets the database instance
  2. Returns the specified collection

### Configuration

The module uses the following environment variables:
- `MONGO_URI`: The MongoDB connection URI (default: "mongodb://localhost:27017")
- `DB_NAME`: The database name (default: "recommendation_system")

## 2. Data Loader (`data_loader.py`)

The `data_loader.py` module provides functions for loading product data from JSON files into MongoDB.

### Key Functions

#### `load_json_data(file_path)`
- **Purpose**: Loads data from a JSON file
- **Input**: File path (string)
- **Output**: List of product dictionaries
- **Process**:
  1. Opens the JSON file
  2. Parses the JSON content
  3. Returns the parsed data as a list of dictionaries

#### `transform_data(data)`
- **Purpose**: Transforms raw product data to match the application's schema
- **Input**: List of raw product dictionaries
- **Output**: List of transformed product dictionaries
- **Process**:
  1. Extracts relevant fields from each product
  2. Converts product details to the required format
  3. Creates a new dictionary with the transformed data
  4. Returns the list of transformed products

#### `insert_data_to_mongodb(data)`
- **Purpose**: Inserts transformed data into MongoDB
- **Input**: List of product dictionaries
- **Output**: None
- **Process**:
  1. Connects to MongoDB
  2. Drops the existing products collection (if any)
  3. Inserts the new data into the collection

#### `load_sample_data(file_path)`
- **Purpose**: Orchestrates the entire data loading process
- **Input**: File path (string)
- **Output**: None
- **Process**:
  1. Loads data from the JSON file
  2. Transforms the data
  3. Inserts the transformed data into MongoDB

### Data Transformation

The data transformation process converts raw product data from the JSON file into a format suitable for the recommendation system:

| Raw Data Field | Transformed Field | Description |
|---------------|------------------|-------------|
| `product_name` | `title` | The name/title of the product |
| `brand` | `brand` | The brand of the product |
| `category` | `category` | The main category of the product |
| `sub_category` | `sub_category` | The subcategory of the product |
| `product_details` (object) | `product_details` (array) | Product details converted to an array of key-value pairs |
| `images` | `images` | Array of image URLs for the product |

## 3. Logging Configuration (`logging_config.py`)

The `logging_config.py` module configures logging for the application.

### Key Functions

#### `configure_logging()`
- **Purpose**: Sets up logging for the application
- **Input**: None (uses environment variables for configuration)
- **Output**: None
- **Process**:
  1. Gets the log level from environment variables
  2. Configures the root logger with the specified level and format
  3. Sets specific log levels for different components
  4. Reduces logging from third-party libraries

### Configuration

The module uses the following environment variables:
- `LOG_LEVEL`: The logging level (default: "INFO")

Available log levels (in increasing order of severity):
- DEBUG: Detailed information, typically useful for diagnosing problems
- INFO: Confirmation that things are working as expected
- WARNING: Indication that something unexpected happened, but the application is still working
- ERROR: Due to a more serious problem, the application has not been able to perform a function
- CRITICAL: A serious error, indicating that the application may be unable to continue running

## How These Utilities Support Association Rule Mining

While these utilities don't directly implement association rule mining algorithms, they provide essential support:

1. **Data Access**: The database utilities provide access to product data, which is the foundation for mining association rules.

2. **Data Preparation**: The data loader transforms raw product data into a format suitable for association rule mining by extracting and structuring product attributes.

3. **Monitoring**: The logging configuration helps monitor the association rule mining process, providing insights into performance and potential issues.

## Using These Utilities

These utilities are primarily used by other components of the system:

1. **Database Utilities**: Used by the recommendation service to access product data and by the API routes to retrieve recommendations.

2. **Data Loader**: Used during system setup or when new data needs to be loaded.

3. **Logging Configuration**: Used throughout the application to provide consistent logging.

As a developer, you typically won't need to call these utilities directly, but understanding how they work will help you understand the overall system architecture and troubleshoot issues if they arise. 