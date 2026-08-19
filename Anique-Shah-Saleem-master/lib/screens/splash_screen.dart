import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:prac/AppScreens/Seller/SellerDashboard.dart';
import 'package:prac/AppScreens/ShopMenu/ShopMenue .dart';
import 'package:prac/res/app_theme.dart';
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
      backgroundColor: AppTheme.darkBg,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(34, 40, 34, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Build/boot status, mono as per the system label rule.
                Text('v1.0 · loading .env',
                    style: AppTheme.mono(13,
                        color: AppTheme.darkTextMuted,
                        weight: FontWeight.w500,
                        tracking: 0)),

                // Wordmark block
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: AppTheme.accent,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      alignment: Alignment.center,
                      child: Text('AI',
                          style: AppTheme.mono(20,
                              color: Colors.white, tracking: 0)),
                    ),
                    const SizedBox(height: 28),
                    Text('AI Salesman',
                        style: AppTheme.display(52,
                            color: AppTheme.darkTextBright, height: 0.98)),
                    const SizedBox(height: 16),
                    Text('Shop by conversation.',
                        style: AppTheme.ui(18,
                            color: AppTheme.darkTextSecondary, height: 1.5)),
                    // Keep the existing brand animation, scaled to sit under
                    // the wordmark rather than dominating the screen.
                    const SizedBox(height: 8),
                    Lottie.asset(
                      'assets/animations/ai_assistant.json',
                      width: 150,
                      height: 150,
                      fit: BoxFit.contain,
                    ),
                  ],
                ),

                // Determinate-looking boot bar + the services being warmed up
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: AnimatedBuilder(
                        animation: _controller,
                        builder: (context, _) => LinearProgressIndicator(
                          value: 0.15 + (_controller.value * 0.85),
                          minHeight: 4,
                          backgroundColor: AppTheme.darkBorder,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                              AppTheme.accent),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text('firebase · chatbot · notifications',
                        style: AppTheme.mono(12,
                            color: AppTheme.darkTextMuted,
                            weight: FontWeight.w500,
                            tracking: 0)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
