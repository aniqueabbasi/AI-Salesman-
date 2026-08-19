import 'package:flutter/material.dart';
import 'package:prac/res/app_theme.dart';
import 'package:prac/res/ui_kit.dart';
import 'package:prac/services/api_service.dart';

import 'Login.dart';

/// Screen 04 — Create account. The account-type choice here decides which home
/// screen the user lands on after signing in.
class SignUp extends StatefulWidget {
  const SignUp({super.key});

  @override
  State<SignUp> createState() => _SignUpState();
}

class _SignUpState extends State<SignUp> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _shopNameController = TextEditingController();

  bool _isLoading = false;
  bool _agreed = true;
  String _errorMessage = '';

  /// 'customer' browses and buys; 'seller' gets the product-management screens.
  String _role = 'customer';

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _shopNameController.dispose();
    super.dispose();
  }

  /// 0 = empty, 1 = weak, 2 = fair, 3 = good.
  int get _passwordStrength {
    final value = _passwordController.text;
    if (value.isEmpty) return 0;
    var score = 0;
    if (value.length >= 8) score++;
    if (RegExp(r'\d').hasMatch(value)) score++;
    if (RegExp(r'[^A-Za-z0-9]').hasMatch(value)) score++;
    return score;
  }

  Future<void> _register() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || !email.contains('@')) {
      setState(() => _errorMessage = 'Please enter a valid email address');
      return;
    }
    if (password.length < 6) {
      setState(() => _errorMessage = 'Password must be at least 6 characters');
      return;
    }
    if (_role == 'seller' && _shopNameController.text.trim().isEmpty) {
      setState(() => _errorMessage = 'Please enter your shop name');
      return;
    }
    if (!_agreed) {
      setState(() => _errorMessage = 'Please accept the terms to continue');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    try {
      await ApiService.register(
        email,
        password,
        role: _role,
        shopName: _role == 'seller' ? _shopNameController.text : null,
      );
      messenger.showSnackBar(
        SnackBar(
          content: Text(_role == 'seller'
              ? 'Seller account created. Please sign in.'
              : 'Account created. Please sign in.'),
        ),
      );
      navigator.pushReplacement(
        MaterialPageRoute(builder: (context) => const Login()),
      );
    } catch (e) {
      if (mounted) {
        setState(() =>
            _errorMessage = e.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(30, 48, 30, 34),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Create account', style: AppTheme.display(44)),
              const SizedBox(height: 26),

              const Eyebrow('I want to join as'),
              const SizedBox(height: 12),
              Row(
                children: [
                  _roleCard(
                    value: 'customer',
                    title: 'Customer',
                    subtitle: 'Browse & buy',
                    icon: Icons.shopping_bag_outlined,
                  ),
                  const SizedBox(width: 12),
                  _roleCard(
                    value: 'seller',
                    title: 'Seller',
                    subtitle: 'Sell products',
                    icon: Icons.storefront_outlined,
                  ),
                ],
              ),
              const SizedBox(height: 28),

              const Eyebrow('Full name'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                style: AppTheme.ui(17),
                decoration: const InputDecoration(hintText: 'Your name'),
              ),
              const SizedBox(height: 22),

              const Eyebrow('Email'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                autocorrect: false,
                style: AppTheme.ui(17),
                decoration: const InputDecoration(hintText: 'you@example.com'),
              ),
              const SizedBox(height: 22),

              const Eyebrow('Password'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                style: AppTheme.ui(17),
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(hintText: '••••••••'),
              ),
              const SizedBox(height: 10),
              _strengthMeter(),

              if (_role == 'seller') ...[
                const SizedBox(height: 22),
                const Eyebrow('Shop name'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _shopNameController,
                  textCapitalization: TextCapitalization.words,
                  style: AppTheme.ui(17),
                  decoration: const InputDecoration(
                    hintText: 'Shown next to your listings',
                  ),
                ),
              ],

              const SizedBox(height: 24),
              GestureDetector(
                onTap: () => setState(() => _agreed = !_agreed),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: _agreed ? AppTheme.accent : Colors.transparent,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: _agreed
                              ? AppTheme.accent
                              : AppTheme.borderStrong,
                          width: 1.5,
                        ),
                      ),
                      child: _agreed
                          ? const Icon(Icons.check,
                              size: 15, color: Colors.white)
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'I agree to the terms and the privacy policy.',
                        style: AppTheme.ui(14, color: AppTheme.textSecondary),
                      ),
                    ),
                  ],
                ),
              ),

              if (_errorMessage.isNotEmpty) ...[
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.accentWash,
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
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

              const SizedBox(height: 28),
              PrimaryButton('Create account',
                  onPressed: _register, isBusy: _isLoading),
              const SizedBox(height: 22),
              Center(
                child: GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const Login()),
                  ),
                  child: RichText(
                    text: TextSpan(
                      style: AppTheme.ui(15, color: AppTheme.textSecondary),
                      children: [
                        const TextSpan(text: 'Already have an account? '),
                        TextSpan(
                          text: 'Sign in',
                          style: AppTheme.ui(15,
                              color: AppTheme.accent, weight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _strengthMeter() {
    final score = _passwordStrength;
    const labels = ['', 'Weak', 'Fair', 'Good'];
    Color barColor(int index) {
      if (index >= score) return AppTheme.borderMedium;
      return score >= 3 ? AppTheme.positive : AppTheme.accent;
    }

    return Row(
      children: [
        for (var i = 0; i < 3; i++) ...[
          Expanded(
            child: Container(
              height: 4,
              decoration: BoxDecoration(
                color: barColor(i),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          if (i < 2) const SizedBox(width: 6),
        ],
        const SizedBox(width: 10),
        SizedBox(
          width: 44,
          child: Text(
            labels[score],
            style: AppTheme.ui(13,
                color: score >= 3 ? AppTheme.positive : AppTheme.textMuted),
          ),
        ),
      ],
    );
  }

  /// One of the two account-type cards.
  Widget _roleCard({
    required String value,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    final bool selected = _role == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _role = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
          decoration: BoxDecoration(
            color: selected ? AppTheme.ink : AppTheme.surfaceRaised,
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            border: Border.all(
              color: selected ? AppTheme.ink : AppTheme.borderStrong,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon,
                  size: 26,
                  color: selected ? AppTheme.surface : AppTheme.textMuted),
              const SizedBox(height: 8),
              Text(title,
                  style: AppTheme.ui(15,
                      color: selected ? AppTheme.surface : AppTheme.textPrimary,
                      weight: FontWeight.w600,
                      height: 1.1)),
              const SizedBox(height: 3),
              Text(subtitle,
                  textAlign: TextAlign.center,
                  style: AppTheme.ui(12,
                      color: selected
                          ? AppTheme.darkTextSecondary
                          : AppTheme.textMuted,
                      height: 1.1)),
            ],
          ),
        ),
      ),
    );
  }
}
