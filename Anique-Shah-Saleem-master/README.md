# E-commerce Flutter App with AI Chatbot

This Flutter e-commerce application features a smart AI-powered shopping assistant chatbot.

## Features

- **E-commerce Platform**: Complete shopping experience with product listings, cart functionality, and checkout
- **AI Shopping Assistant**: Smart chatbot using Google's Gemini AI API to help users with their shopping experience
- **Offline Mode**: Fallback to keyword-based responses when API isn't available
- **Responsive UI**: Clean and intuitive interface that works across mobile devices

## Setup Instructions

### Prerequisites
- Flutter SDK installed and set up
- An API key from Google AI Studio (for Gemini AI integration)

### Installation Steps

1. Clone the repository:
   ```
   git clone <repository-url>
   ```

2. Navigate to the project directory:
   ```
   cd <project-directory>
   ```

3. Install dependencies:
   ```
   flutter pub get
   ```

4. Configure the AI Chatbot:
   - Get your API key from [Google AI Studio](https://makersuite.google.com/app/apikey)
   - Open `lib/config/api_config.dart`
   - Replace `YOUR_GEMINI_API_KEY` with your actual API key

5. Run the app:
   ```
   flutter run
   ```

## How the Chatbot Works

The chatbot uses a hybrid approach:

1. When online with a valid API key, it utilizes Google's Gemini generative AI model for natural, contextual conversations
2. When offline or if API issues occur, it falls back to a smart keyword-based system for reliable functionality

For detailed chatbot integration instructions, see [Chatbot API Integration Guide](README_CHATBOT_API.md).

## Troubleshooting

If you experience issues with the chatbot:

1. Verify your API key is correct in `lib/config/api_config.dart`
2. Check your internet connection
3. Review Flutter console logs for error messages
4. If API-related problems persist, the app will automatically fall back to offline mode

## License

[Your License Information]
