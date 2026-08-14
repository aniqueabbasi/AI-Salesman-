import "package:flutter/material.dart";
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:prac/AppScreens/ShopMenu/Setting/AdminPanel.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'Controller/CartProvider.dart';
import 'Controller/ProductProvider.dart';
import 'Controller/ChatbotProvider.dart';
import 'services/chatbot_service.dart';
import 'services/notification_service.dart';
import 'res/app_theme.dart';
import 'screens/splash_screen.dart';

void main() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load(fileName: ".env");

  // Initialize Firebase & services
  await Firebase.initializeApp();
  // Set background handler before any other Firebase Messaging usage
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  // Initialize the chatbot and notification services
  await ChatbotService.initialize();
  await NotificationService.initialize();

  runApp(const MyApp());
}

/// Lets the root [PopScope] reach the [MaterialApp]'s navigator. `MyApp`'s own
/// context sits above [MaterialApp], so `Navigator.of(context)` cannot find it.
final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => CartProvider()),
        ChangeNotifierProvider(create: (context) => ProductProvider()),
        ChangeNotifierProvider(create: (context) => ChatbotProvider()),
      ],
      child: PopScope(
        // Never let a back gesture close the app; pop a route instead if one exists.
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          if (didPop) return;
          final navigator = _navigatorKey.currentState;
          if (navigator != null && navigator.canPop()) {
            navigator.pop();
          }
        },
        child: MaterialApp(
          navigatorKey: _navigatorKey,
          debugShowCheckedModeBanner: false,
          title: 'AI Salesman',
          theme: AppTheme.lightTheme,
          home: const SplashScreen(),
          routes: {
            '/admin': (context) => const AdminPanel(),
          },
        ),
      ),
    );
  }
}
