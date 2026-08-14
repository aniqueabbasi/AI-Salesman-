import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:prac/AppScreens/Seller/SellerDashboard.dart';
import 'package:prac/AppScreens/ShopMenu/ShopMenue .dart';
import 'package:prac/services/auth_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeIn,
      ),
    );

    _controller.forward();
    
    // Navigate onwards after 3 seconds, to whichever home the account uses.
    Future.delayed(const Duration(seconds: 3), () async {
      // The screen may already be gone when the timer fires.
      if (!mounted) return;
      final navigator = Navigator.of(context);

      final isSeller =
          await AuthService.isLoggedIn() && await AuthService.isSeller();
      if (!mounted) return;

      navigator.pushReplacement(
        MaterialPageRoute(
          builder: (_) =>
              isSeller ? const SellerDashboard() : const ShopMenue(),
        ),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color.fromARGB(255, 22, 22, 23),
              Color(0xFF2575FC),
            ],
          ),
        ),
        child: Center(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // AI Assistant Animation
                Lottie.asset(
                  'assets/animations/ai_assistant.json',
                  width: 200,
                  height: 200,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 20),
                // AI Salesman Text
                const Text(
                  'AI Salesman',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 10),
                // Loading Indicator
                const SizedBox(
                  width: 50,
                  height: 50,
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    strokeWidth: 2.0,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
