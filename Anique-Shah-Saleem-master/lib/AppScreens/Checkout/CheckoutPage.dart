import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:prac/Controller/CartProvider.dart';
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
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Checkout',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Shipping Address Section
              _buildSectionHeader('Shipping Address'),
              const SizedBox(height: 12),
              _buildAddressCard(),
              const SizedBox(height: 24),

              // Contact Information Section
              _buildSectionHeader('Contact Information'),
              const SizedBox(height: 12),
              _buildContactInfo(),
              const SizedBox(height: 24),

              // Voucher Section
              _buildVoucherSection(),
              const SizedBox(height: 24),

              // Order Summary Section
              _buildSectionHeader('Order Summary'),
              const SizedBox(height: 12),
              _buildOrderSummary(subtotal, shipping, total, totalItems),
              const SizedBox(height: 24),

              // Continue to Payment Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (_validateForm()) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PaymentMethodScreen(
                            totalAmount: total,
                            totalItems: totalItems,
                          ),
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6C63FF),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Continue to Payment',
                    style: TextStyle(
                      color: Colors.white,
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

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildAddressCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
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
                  icon: const Icon(Icons.edit, size: 20, color: Color(0xFF6C63FF)),
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
                  style: const TextStyle(color: Colors.grey, height: 1.5),
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
                    backgroundColor: const Color(0xFF6C63FF),
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
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
                  icon: const Icon(Icons.edit, size: 20, color: Color(0xFF6C63FF)),
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
            style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14, color: Colors.black87),
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
                  style: const TextStyle(color: Colors.grey),
                ),
          
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),
          
          // Phone Field
          const Text(
            'Phone',
            style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14, color: Colors.black87),
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
                  style: const TextStyle(color: Colors.grey),
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
                    backgroundColor: const Color(0xFF6C63FF),
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
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
              const Icon(Icons.local_offer_outlined, color: Colors.grey),
              const SizedBox(width: 12),
              if (!_showVoucherField)
                const Text(
                  'Add Voucher',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
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
                    style: TextStyle(color: Color(0xFF6C63FF)),
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
                  child: const Text('Apply', style: TextStyle(color: Color(0xFF6C63FF))),
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
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
            style: const TextStyle(color: Colors.grey, fontSize: 14),
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
              color: isAccent ? const Color(0xFF6C63FF) : Colors.black87,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: isAccent ? const Color(0xFF6C63FF) : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  String _formatCurrency(double amount) {
    return 'RS ${amount.toStringAsFixed(2)}';
  }
}

