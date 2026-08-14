# E-commerce AI Chatbot

An AI-powered chatbot for e-commerce product queries using FastAPI, MongoDB, and multiple AI providers (OpenAI and Groq).

## Features

- Natural language product queries
- Support for both OpenAI and Groq AI models
- MongoDB Atlas integration for product data
- Modern web interface
- Product comparison capabilities
- Real-time responses

## Setup

1. Clone the repository
2. Install dependencies:
```bash
pip install -r requirements.txt
```

3. Create a `.env` file with the following variables:
```
MONGODB_URI=your_mongodb_atlas_uri
OPENAI_API_KEY=your_openai_api_key
GROQ_API_KEY=your_groq_api_key
DATABASE_NAME=ecommerce
COLLECTION_NAME=products
AI_PROVIDER=openai  # or 'groq' to use Groq AI
```

4. Start the server:
```bash
python main.py
```

5. Open your browser and navigate to `http://localhost:8000`

## Sample Queries

Try these example queries:
- "Show me all red shirts"
- "I want to see track pants under 1000 rupees"
- "Compare York and Nike track pants"
- "Show me clothing items with high ratings"

## MongoDB Document Structure

Products in MongoDB should follow this structure:
```json
{
  "_id": "unique_id",
  "actual_price": 2999,
  "average_rating": "3.9",
  "brand": "Brand Name",
  "category": "Category Name",
  "description": "Product description...",
  "discount": "69% off",
  "images": ["image_url1", "image_url2"],
  "out_of_stock": false,
  "product_details": [
    {"key": "value"},
    {"key": "value"}
  ],
  "selling_price": 921,
  "sub_category": "Sub Category",
  "title": "Product Title",
  "url": "product_url"
}
```

## API Endpoints

- `GET /`: Web interface
- `POST /chat`: Chat endpoint
  - Request body:
    ```json
    {
      "message": "user query"
    }
    ```
  - Response:
    ```json
    {
      "message": "AI response",
      "products": [...],
      "is_comparison": false
    }
    ```

## Technologies Used

- FastAPI
- MongoDB Atlas
- OpenAI API
- Groq API
- HTML/CSS/JavaScript 