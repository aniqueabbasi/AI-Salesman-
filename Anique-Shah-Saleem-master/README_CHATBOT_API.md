# Integrating Gemini AI with the E-commerce Chatbot

This guide explains how to set up the Gemini AI API for the e-commerce chatbot.

## Prerequisites

- Flutter development environment
- Google account for accessing Google AI Studio

## Steps to Set Up the Gemini API

1. **Get a Gemini API key**
   - Visit [Google AI Studio](https://makersuite.google.com/app/apikey)
   - Sign in with your Google account
   - Click on "Create API Key"
   - Copy the generated API key

2. **Update the API key in the config file**
   - Open `lib/config/api_config.dart`
   - Replace `YOUR_GEMINI_API_KEY` with your actual API key:
     ```dart
     static const String geminiApiKey = "YOUR_ACTUAL_API_KEY";
     ```

3. **Security Considerations**
   - In a production environment, never hardcode your API key in the source code
   - Consider using environment variables, secure storage solutions, or backend proxy services
   - The current implementation is for demonstration purposes only

## How the Chatbot Works

The chatbot implements a hybrid approach:

1. **Online Mode (Gemini AI)**
   - When a valid API key is provided, the chatbot will use Gemini's generative AI capabilities
   - This provides dynamic, contextual responses to customer queries

2. **Offline Mode (Fallback)**
   - If the API key is invalid, network issues occur, or the API returns errors
   - The chatbot automatically switches to an offline mode using predefined responses
   - This ensures the chatbot remains functional even without internet access

## Customizing the Chatbot

- To add more offline responses, update the `_getSmartResponse` method in `ChatbotService` class
- To change the model (e.g., to use a different Gemini model), modify the `model` parameter in the `GenerativeModel` constructor

## Testing

- Test the chatbot with your API key to ensure it functions correctly
- Test the offline mode by temporarily replacing the API key with an invalid value
- Verify both online and offline responses are appropriate for your e-commerce context

## Rate Limits and Usage

- Be aware that Gemini API has usage limits based on your Google AI plan
- Monitor your usage in the Google AI Studio dashboard
- Consider implementing rate limiting in production to prevent excessive API calls 