import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:prac/Controller/CartProvider.dart';
import 'package:prac/res/app_theme.dart';
import 'package:prac/res/ui_kit.dart';
import 'PaymentMethodScreen.dart';

class UserInformation {
  final String email;
  final String phone;
  final String address;

  UserInformation({
    required this.email,
    required this.phone,
    required this.address,
  });

  Map<String, dynamic> toJson() => {
    'email': email,
    'phone': phone,
    'address': address,
  };

  factory UserInformation.fromJson(Map<String, dynamic> json) {
    return UserInformation(
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      address: json['address'] ?? '',
    );
  }
}

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  // Controllers for editable fields
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _voucherController = TextEditingController();
  
  bool _isEditingAddress = false;
  bool _isEditingContact = false;
  bool _showVoucherField = false;
  bool _isLoading = true;

  // Keys for shared preferences
  static const String _userInfoKey = 'user_information';

  @override
  void initState() {
    super.initState();
    _loadUserInformation();
  }

  @override
  void dispose() {
    _addressController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _voucherController.dispose();
    super.dispose();
  }

  // Load saved user information
  Future<void> _loadUserInformation() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final userInfoJson = prefs.getString(_userInfoKey);
      
      if (userInfoJson != null) {
        final userInfo = UserInformation.fromJson(json.decode(userInfoJson));
        setState(() {
          _emailController.text = userInfo.email;
          _phoneController.text = userInfo.phone;
          _addressController.text = userInfo.address;
        });
      } else {
        // Set default values if no saved data
        _addressController.text = 'Enter your address';
        _emailController.text = '';
        _phoneController.text = '';
      }
    } catch (e) {
      debugPrint('Error loading user information: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Save user information
  Future<void> _saveUserInformation() async {
    if (_emailController.text.isEmpty || _phoneController.text.isEmpty || _addressController.text.isEmpty) {
      return; // Don't save empty information
    }

    final userInfo = UserInformation(
      email: _emailController.text.trim(),
      phone: _phoneController.text.trim(),
      address: _addressController.text.trim(),
    );

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userInfoKey, json.encode(userInfo.toJson()));
    } catch (e) {
      debugPrint('Error saving user information: $e');
    }
  }

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // Validate all fields before proceeding
  bool _validateForm() {
    if (_emailController.text.isEmpty ||
        _phoneController.text.isEmpty ||
        _addressController.text.isEmpty) {
      _showValidationDialog('Please fill in all required fields');
      return false;
    }
    
    // Email validation
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(_emailController.text)) {
      _showValidationDialog('Please enter a valid email address');
      return false;
    }
    
    // Phone number validation (basic check for at least 10 digits)
    final phoneRegex = RegExp(r'^[0-9]{10,}$');
    final digitsOnly = _phoneController.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (!phoneRegex.hasMatch(digitsOnly)) {
      _showValidationDialog('Please enter a valid phone number (at least 10 digits)');
      return false;
    }
    
    return true;
  }

  void _showValidationDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Validation Error'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppTheme.surface,
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final cartProvider = Provider.of<CartProvider>(context);
    final totalItems = cartProvider.cart.length;
    final subtotal = cartProvider.cart.fold<double>(
      0,
      (sum, item) => sum + (item['price'] as double) * (item['quantity'] as int),
    );
    const shipping = 0.0; // Free shipping as per design
    final total = subtotal + shipping;

    return Scaffold(
      backgroundColor: AppTheme.surface,
      bottomNavigationBar: _buildBottomBar(total, totalItems),
      body: SafeArea(
        child: Column(
          children: [
            const ScreenHeader('Checkout'),
            Expanded(
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(22, 18, 22, 24),
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _CheckoutSteps(current: 0),
                      const SizedBox(height: 24),

                      // Shipping Address Section
                      _buildSectionHeader('Deliver to'),
                      const SizedBox(height: 10),
                      _buildAddressCard(),
                      const SizedBox(height: 22),

                      // Contact Information Section
                      _buildSectionHeader('Contact'),
                      const SizedBox(height: 10),
                      _buildContactInfo(),
                      const SizedBox(height: 22),

                      // Voucher Section
                      _buildVoucherSection(),
                      const SizedBox(height: 22),

                      // Order Summary Section
                      _buildSectionHeader('Order summary'),
                      const SizedBox(height: 10),
                      _buildOrderSummary(subtotal, shipping, total, totalItems),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Total plus the forward action, pinned above the system inset.
  Widget _buildBottomBar(double total, int totalItems) {
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 12, 22, 16),
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        border: Border(top: BorderSide(color: AppTheme.borderSoft)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Eyebrow('Total'),
                const SizedBox(height: 2),
                Text(formatPkr(total), style: AppTheme.display(22)),
              ],
            ),
            const SizedBox(width: 18),
            Expanded(
              child: PrimaryButton(
                'Continue to pay',
                onPressed: () {
                  if (!_validateForm()) return;
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PaymentMethodScreen(
                        totalAmount: total,
                        totalItems: totalItems,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) => Eyebrow(title);

  Widget _buildAddressCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceRaised,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppTheme.ink.withValues(alpha: 0.04),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Home',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              if (!_isEditingAddress)
                IconButton(
                  icon: const Icon(Icons.edit, size: 20, color: AppTheme.accent),
                  onPressed: () {
                    setState(() {
                      _isEditingAddress = true;
                    });
                  },
                ),
            ],
          ),
          const SizedBox(height: 8),
          _isEditingAddress
              ? TextFormField(
                  controller: _addressController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.all(12),
                  ),
                )
              : Text(
                  _addressController.text,
                  style: const TextStyle(color: AppTheme.textMuted, height: 1.5),
                ),
          if (_isEditingAddress) const SizedBox(height: 12),
          if (_isEditingAddress)
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () {
                    setState(() {
                      _isEditingAddress = false;
                    });
                  },
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () async {
                    await _saveUserInformation();
                    setState(() {
                      _isEditingAddress = false;
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accent,
                    // Undo the theme's full-width default: inside a Row the
                    // infinite minimum width has nothing to bound it.
                    minimumSize: Size.zero,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  ),
                  child: const Text('Save', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildContactInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceRaised,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppTheme.ink.withValues(alpha: 0.04),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Contact Information',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              if (!_isEditingContact)
                IconButton(
                  icon: const Icon(Icons.edit, size: 20, color: AppTheme.accent),
                  onPressed: () {
                    setState(() {
                      _isEditingContact = true;
                    });
                  },
                ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Email Field
          const Text(
            'Email',
            style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14, color: AppTheme.textPrimary),
          ),
          const SizedBox(height: 4),
          _isEditingContact
              ? TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.all(12),
                  ),
                )
              : Text(
                  _emailController.text,
                  style: const TextStyle(color: AppTheme.textMuted),
                ),
          
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),
          
          // Phone Field
          const Text(
            'Phone',
            style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14, color: AppTheme.textPrimary),
          ),
          const SizedBox(height: 4),
          _isEditingContact
              ? TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.all(12),
                  ),
                )
              : Text(
                  _phoneController.text,
                  style: const TextStyle(color: AppTheme.textMuted),
                ),
          
          if (_isEditingContact) const SizedBox(height: 16),
          if (_isEditingContact)
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () {
                    setState(() {
                      _isEditingContact = false;
                    });
                  },
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () async {
                    await _saveUserInformation();
                    setState(() {
                      _isEditingContact = false;
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accent,
                    // Undo the theme's full-width default: inside a Row the
                    // infinite minimum width has nothing to bound it.
                    minimumSize: Size.zero,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  ),
                  child: const Text('Save', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildVoucherSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceRaised,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppTheme.ink.withValues(alpha: 0.04),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.local_offer_outlined, color: AppTheme.textMuted),
              const SizedBox(width: 12),
              if (!_showVoucherField)
                const Text(
                  'Add Voucher',
                  style: TextStyle(fontSize: 16, color: AppTheme.textMuted),
                ),
              const Spacer(),
              if (!_showVoucherField)
                TextButton(
                  onPressed: () {
                    setState(() {
                      _showVoucherField = true;
                    });
                  },
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(50, 30),
                  ),
                  child: const Text(
                    'Apply',
                    style: TextStyle(color: AppTheme.accent),
                  ),
                ),
            ],
          ),
          if (_showVoucherField) const SizedBox(height: 12),
          if (_showVoucherField)
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _voucherController,
                    decoration: InputDecoration(
                      hintText: 'Enter voucher code',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () {
                    // Handle voucher application
                    setState(() {
                      _showVoucherField = false;
                      _voucherController.clear();
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Voucher applied successfully')),
                    );
                  },
                  child: const Text('Apply', style: TextStyle(color: AppTheme.accent)),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () {
                    setState(() {
                      _showVoucherField = false;
                      _voucherController.clear();
                    });
                  },
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildOrderSummary(double subtotal, double shipping, double total, int totalItems) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceRaised,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppTheme.ink.withValues(alpha: 0.04),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildOrderRow('Subtotal', _formatCurrency(subtotal)),
          const SizedBox(height: 8),
          _buildOrderRow('Shipping', shipping == 0 ? 'Free' : _formatCurrency(shipping)),
          const Divider(height: 32),
          _buildOrderRow(
            'Total',
            _formatCurrency(total),
            isBold: true,
            isAccent: true,
          ),
          const SizedBox(height: 8),
          Text(
            '$totalItems items',
            style: const TextStyle(color: AppTheme.textMuted, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderRow(String label, String value, {bool isBold = false, bool isAccent = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: isAccent ? AppTheme.accent : AppTheme.textPrimary,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: isAccent ? AppTheme.accent : AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  String _formatCurrency(double amount) => formatPkr(amount);
}

/// The three-stage progress rail across the top of checkout.
class _CheckoutSteps extends StatelessWidget {
  /// Zero-based index of the stage the shopper is on.
  final int current;

  const _CheckoutSteps({required this.current});

  static const List<String> _labels = ['Address', 'Pay', 'Done'];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < _labels.length; i++) ...[
          if (i > 0)
            Expanded(
              child: Container(
                height: 1,
                margin: const EdgeInsets.symmetric(horizontal: 8),
                color: i <= current
                    ? AppTheme.ink
                    : AppTheme.borderStrong,
              ),
            ),
          Text(
            '${i + 1} ${_labels[i].toUpperCase()}',
            style: AppTheme.mono(
              11,
              color: i == current
                  ? AppTheme.ink
                  : (i < current ? AppTheme.textSecondary : AppTheme.textMuted),
            ),
          ),
        ],
      ],
    );
  }
}

