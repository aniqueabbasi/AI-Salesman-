import 'package:flutter/material.dart';

import 'package:prac/AppScreens/Seller/SellerDashboard.dart';
import 'package:prac/res/app_theme.dart';
import 'package:prac/res/ui_kit.dart';
import 'package:prac/services/api_service.dart';
import 'package:prac/services/auth_service.dart';

/// Sign in to, or register, a seller account. Both paths land on the
/// dashboard; the only difference is whether the shop is created first.
class SellerSignIn extends StatefulWidget {
  const SellerSignIn({super.key});

  @override
  State<SellerSignIn> createState() => _SellerSignInState();
}

class _SellerSignInState extends State<SellerSignIn> {
  final _shopController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isRegistering = false;
  bool _isBusy = false;
  String _error = '';

  @override
  void dispose() {
    _shopController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final shop = _shopController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      setState(() => _error = 'Enter your email and password.');
      return;
    }
    if (_isRegistering && shop.isEmpty) {
      setState(() => _error = 'Give your shop a name.');
      return;
    }

    setState(() {
      _isBusy = true;
      _error = '';
    });

    try {
      if (_isRegistering) {
        await ApiService.register(
          email,
          password,
          role: 'seller',
          shopName: shop,
        );
      }

      await ApiService.login(email, password);

      // The API decides the role; a customer account cannot write listings, so
      // stop here rather than opening a dashboard every action would reject.
      if (!await AuthService.isSeller()) {
        await AuthService.clearToken();
        if (!mounted) return;
        setState(() {
          _isBusy = false;
          _error = 'That account is a customer, not a seller. '
              'Register a shop to sell.';
        });
        return;
      }

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const SellerDashboard()),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isBusy = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.canvas,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(22),
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 26, 24, 24),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(AppTheme.radiusXl),
                border: Border.all(color: AppTheme.borderSoft),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Seller access',
                      style: AppTheme.mono(12, color: AppTheme.accent)),
                  const SizedBox(height: 12),
                  Text(_isRegistering ? 'Register a shop' : 'Shop sign-in',
                      style: AppTheme.display(32)),
                  const SizedBox(height: 8),
                  Text(
                    'Role must be seller — the token is checked on every write.',
                    style: AppTheme.ui(13,
                        color: AppTheme.textSecondary, height: 1.45),
                  ),
                  const SizedBox(height: 26),
                  if (_isRegistering) ...[
                    _Field(
                      label: 'Shop name',
                      controller: _shopController,
                      hint: 'Kashif Fabrics',
                    ),
                    const SizedBox(height: 18),
                  ],
                  _Field(
                    label: 'Email',
                    controller: _emailController,
                    hint: 'kashif@fabrics.pk',
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 18),
                  _Field(
                    label: 'Password',
                    controller: _passwordController,
                    obscure: true,
                  ),
                  if (_error.isNotEmpty) ...[
                    const SizedBox(height: 18),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.accentWash,
                        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                        border: Border.all(color: AppTheme.accentWashBorder),
                      ),
                      child: Text(_error,
                          style: AppTheme.ui(13,
                              color: AppTheme.accentPressed, height: 1.4)),
                    ),
                  ],
                  const SizedBox(height: 26),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: _isBusy ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.ink,
                        disabledBackgroundColor:
                            AppTheme.ink.withValues(alpha: 0.5),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusMd),
                        ),
                      ),
                      child: _isBusy
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white),
                              ),
                            )
                          : Text(
                              _isRegistering
                                  ? 'Create shop'
                                  : 'Enter dashboard',
                              style: AppTheme.ui(16,
                                  color: Colors.white,
                                  weight: FontWeight.w600,
                                  height: 1.0),
                            ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceSunken,
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isRegistering
                              ? 'Already registered? Sign in and your listings load from /products/mine.'
                              : 'Not a seller yet? Register a shop and your listings appear under /products/mine.',
                          style: AppTheme.ui(12,
                              color: AppTheme.textSecondary, height: 1.45),
                        ),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: _isBusy
                              ? null
                              : () => setState(() {
                                    _isRegistering = !_isRegistering;
                                    _error = '';
                                  }),
                          child: Text(
                            _isRegistering
                                ? 'Sign in instead'
                                : 'Register a shop',
                            style: AppTheme.ui(13,
                                color: AppTheme.accent,
                                weight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Underlined field matching the sign-in design.
class _Field extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String? hint;
  final bool obscure;
  final TextInputType? keyboardType;

  const _Field({
    required this.label,
    required this.controller,
    this.hint,
    this.obscure = false,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Eyebrow(label),
        TextField(
          controller: controller,
          obscureText: obscure,
          keyboardType: keyboardType,
          style: AppTheme.ui(16),
          cursorColor: AppTheme.accent,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppTheme.ui(16, color: AppTheme.textDisabled),
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(vertical: 10),
          ),
        ),
      ],
    );
  }
}
