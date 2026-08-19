import 'package:flutter/material.dart';

import 'package:prac/res/app_theme.dart';
import 'package:prac/res/ui_kit.dart';
import 'package:prac/screens/splash_screen.dart';
import 'package:prac/services/api_service.dart';
import 'package:prac/services/auth_service.dart';

/// The seller's own account: who they are, how buyers reach them, and the way
/// out. Loaded from `/auth/me` rather than cached prefs so it reflects what
/// the server actually holds.
class SellerProfile extends StatefulWidget {
  const SellerProfile({super.key});

  @override
  State<SellerProfile> createState() => _SellerProfileState();
}

class _SellerProfileState extends State<SellerProfile> {
  final _nameController = TextEditingController();
  final _shopController = TextEditingController();
  final _phoneController = TextEditingController();

  Map<String, dynamic> _profile = const {};
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isEditing = false;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _shopController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });
    try {
      final profile = await ApiService.getMyProfile();
      if (!mounted) return;
      setState(() {
        _profile = profile;
        _nameController.text = (profile['full_name'] ?? '').toString();
        _shopController.text = (profile['shop_name'] ?? '').toString();
        _phoneController.text = (profile['phone'] ?? '').toString();
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final updated = await ApiService.updateMyProfile(
        fullName: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        shopName: _shopController.text.trim(),
      );
      // Keep the cached shop name in step so the dashboard header matches.
      final shop = (updated['shop_name'] ?? '').toString();
      if (shop.isNotEmpty) {
        final token = await AuthService.getToken();
        if (token != null) {
          await AuthService.saveSession(
            token: token,
            role: (updated['role'] ?? 'seller').toString(),
            email: updated['email']?.toString(),
            shopName: shop,
          );
        }
      }
      if (!mounted) return;
      setState(() {
        _profile = updated;
        _isEditing = false;
        _isSaving = false;
      });
      messenger.showSnackBar(const SnackBar(content: Text('Profile saved')));
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      messenger.showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  Future<void> _confirmLogout() async {
    final navigator = Navigator.of(context);
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusLg)),
        title: Text('Log out', style: AppTheme.display(22)),
        content: Text('Sign out of this shop?',
            style: AppTheme.ui(15, color: AppTheme.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text('Cancel',
                style: AppTheme.ui(15, color: AppTheme.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text('Log out',
                style: AppTheme.ui(15,
                    color: AppTheme.accentPressed, weight: FontWeight.w600)),
          ),
        ],
      ),
    );

    if (shouldLogout == true) {
      await AuthService.clearToken();
      navigator.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const SplashScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            ScreenHeader(
              'Profile',
              trailing: _isLoading || _error.isNotEmpty
                  ? null
                  : GestureDetector(
                      onTap: () => setState(() => _isEditing = !_isEditing),
                      child: Text(_isEditing ? 'Cancel' : 'Edit',
                          style: AppTheme.ui(14,
                              color: AppTheme.accent,
                              weight: FontWeight.w600)),
                    ),
            ),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_error,
                  textAlign: TextAlign.center,
                  style: AppTheme.ui(14, color: AppTheme.textSecondary)),
              const SizedBox(height: 18),
              SizedBox(
                  width: 170,
                  child: PrimaryButton('Retry', onPressed: _load)),
            ],
          ),
        ),
      );
    }

    final shop = (_profile['shop_name'] ?? '').toString();
    final name = (_profile['full_name'] ?? '').toString();
    final email = (_profile['email'] ?? '').toString();
    final phone = (_profile['phone'] ?? '').toString();

    return ListView(
      padding: const EdgeInsets.fromLTRB(22, 18, 22, 28),
      physics: const BouncingScrollPhysics(),
      children: [
        Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: const BoxDecoration(
                color: AppTheme.ink,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                _initials(shop.isNotEmpty ? shop : (name.isNotEmpty ? name : '?')),
                style: AppTheme.display(20, color: AppTheme.surface),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(shop.isEmpty ? 'Unnamed shop' : shop,
                      style: AppTheme.display(24),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 3),
                  Text((_profile['role'] ?? 'seller').toString().toUpperCase(),
                      style: AppTheme.mono(11, color: AppTheme.accent)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 26),
        if (_isEditing) ...[
          _EditField(label: 'Seller name', controller: _nameController),
          const SizedBox(height: 18),
          _EditField(label: 'Brand name', controller: _shopController),
          const SizedBox(height: 18),
          _EditField(
            label: 'Phone',
            controller: _phoneController,
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 26),
          PrimaryButton('Save changes', isBusy: _isSaving, onPressed: _save),
        ] else ...[
          _InfoRow(label: 'Seller name', value: name),
          _InfoRow(label: 'Brand name', value: shop),
          _InfoRow(label: 'Phone', value: phone),
          // Email identifies the account, so it is shown but never editable.
          _InfoRow(label: 'Email', value: email, editable: false),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: OutlinedButton(
              onPressed: _confirmLogout,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.accentPressed,
                side: const BorderSide(color: AppTheme.accentWashBorder, width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                ),
              ),
              child: Text('Log out',
                  style: AppTheme.ui(16,
                      color: AppTheme.accentPressed,
                      weight: FontWeight.w600,
                      height: 1.0)),
            ),
          ),
        ],
      ],
    );
  }

  static String _initials(String value) {
    final parts =
        value.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool editable;

  const _InfoRow({
    required this.label,
    required this.value,
    this.editable = true,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Eyebrow(label),
              if (!editable) ...[
                const SizedBox(width: 8),
                Text('READ ONLY',
                    style: AppTheme.mono(9, color: AppTheme.textDisabled)),
              ],
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value.isEmpty ? 'Not set' : value,
            style: AppTheme.ui(16,
                color: value.isEmpty ? AppTheme.textDisabled : AppTheme.ink,
                weight: FontWeight.w500),
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
        ],
      ),
    );
  }
}

class _EditField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final TextInputType? keyboardType;

  const _EditField({
    required this.label,
    required this.controller,
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
          keyboardType: keyboardType,
          style: AppTheme.ui(16),
          cursorColor: AppTheme.accent,
          decoration: const InputDecoration(
            isDense: true,
            contentPadding: EdgeInsets.symmetric(vertical: 10),
          ),
        ),
      ],
    );
  }
}
