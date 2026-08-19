import 'package:flutter/material.dart';
import 'package:prac/AppScreens/Seller/SellerDashboard.dart';
import 'package:prac/Authentication/SignUp.dart';
import 'package:prac/res/app_theme.dart';
import 'package:prac/res/ui_kit.dart';
import 'package:prac/services/api_service.dart';
import 'package:prac/services/auth_service.dart';
import 'ResetPassword.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  String _errorMessage = '';

  Future<void> _login() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    final navigator = Navigator.of(context);

    try {
      // ApiService.login stores the token and role for us.
      await ApiService.login(
          _emailController.text.trim(), _passwordController.text);

      if (await AuthService.isSeller()) {
        // Sellers get their own home screen instead of the storefront.
        navigator.pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const SellerDashboard()),
          (route) => false,
        );
      } else {
        // Customers return to whatever sent them here (e.g. checkout).
        navigator.pop(true);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(30, 56, 30, 34),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height - 90,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Welcome back', style: AppTheme.display(44)),
                const SizedBox(height: 10),
                Text(
                  'Signing in returns a 12-hour token.',
                  style: AppTheme.ui(16, color: AppTheme.textMuted),
                ),
                const SizedBox(height: 36),

                const Eyebrow('Email'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  autocorrect: false,
                  style: AppTheme.ui(17),
                  decoration: const InputDecoration(hintText: 'you@example.com'),
                ),
                const SizedBox(height: 24),

                const Eyebrow('Password'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  style: AppTheme.ui(17),
                  decoration: InputDecoration(
                    hintText: '••••••••',
                    suffixIcon: GestureDetector(
                      onTap: () => setState(
                          () => _obscurePassword = !_obscurePassword),
                      child: Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: Text(
                          _obscurePassword ? 'Show' : 'Hide',
                          style: AppTheme.ui(14, color: AppTheme.textMuted),
                        ),
                      ),
                    ),
                    suffixIconConstraints:
                        const BoxConstraints(minWidth: 54, minHeight: 24),
                  ),
                ),

                const SizedBox(height: 18),
                Row(
                  children: [
                    Text('Remember me',
                        style: AppTheme.ui(15, color: AppTheme.textSecondary)),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const ResetPassword()),
                      ),
                      child: Text('Forgot password?',
                          style: AppTheme.ui(15,
                              color: AppTheme.accent,
                              weight: FontWeight.w500)),
                    ),
                  ],
                ),

                if (_errorMessage.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppTheme.accentWash,
                      borderRadius:
                          BorderRadius.circular(AppTheme.radiusMd),
                      border: Border.all(color: AppTheme.accentWashBorder),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.error_outline,
                            color: AppTheme.accentPressed, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(_errorMessage,
                              style: AppTheme.ui(14,
                                  color: AppTheme.accentPressed)),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 32),
                PrimaryButton('Sign in',
                    onPressed: _login, isBusy: _isLoading),
                const SizedBox(height: 16),
                SecondaryButton(
                  'Create an account',
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SignUp()),
                  ),
                ),

                const SizedBox(height: 40),
                Center(
                  child: Text(
                    'Sellers sign in here too — you land on your dashboard.',
                    textAlign: TextAlign.center,
                    style: AppTheme.ui(14, color: AppTheme.textMuted),
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
