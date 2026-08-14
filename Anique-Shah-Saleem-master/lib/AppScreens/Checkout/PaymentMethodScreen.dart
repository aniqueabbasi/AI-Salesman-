import 'package:flutter/material.dart';

class PaymentMethodScreen extends StatefulWidget {
  final double totalAmount;
  final int totalItems;

  const PaymentMethodScreen({
    super.key,
    required this.totalAmount,
    required this.totalItems,
  });

  @override
  State<PaymentMethodScreen> createState() => _PaymentMethodScreenState();
}

class _PaymentMethodScreenState extends State<PaymentMethodScreen> {
  String _selectedMethod = 'credit_card';
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _cardNumberController = TextEditingController();
  final TextEditingController _expiryController = TextEditingController();
  final TextEditingController _cvvController = TextEditingController();
  final TextEditingController _cardNameController = TextEditingController();
  
  bool _isProcessing = false;

  @override
  void dispose() {
    _cardNumberController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    _cardNameController.dispose();
    super.dispose();
  }

  bool _validateForm() {
    if (_selectedMethod == 'credit_card') {
      if (_cardNumberController.text.isEmpty ||
          _expiryController.text.isEmpty ||
          _cvvController.text.isEmpty ||
          _cardNameController.text.isEmpty) {
        _showValidationDialog('Please fill in all payment details');
        return false;
      }
      
      // Card number validation (16 digits)
      final cardNumberRegex = RegExp(r'^[0-9]{16}$');
      final cardNumber = _cardNumberController.text.replaceAll(RegExp(r'\s+'), '');
      if (!cardNumberRegex.hasMatch(cardNumber)) {
        _showValidationDialog('Please enter a valid 16-digit card number');
        return false;
      }
      
      // Expiry date validation (MM/YY format)
      final expiryRegex = RegExp(r'^(0[1-9]|1[0-2])\/?([0-9]{2})');
      if (!expiryRegex.hasMatch(_expiryController.text)) {
        _showValidationDialog('Please enter a valid expiry date (MM/YY)');
        return false;
      }
      
      // CVV validation (3 or 4 digits)
      final cvvRegex = RegExp(r'^[0-9]{3,4}$');
      if (!cvvRegex.hasMatch(_cvvController.text)) {
        _showValidationDialog('Please enter a valid CVV (3 or 4 digits)');
        return false;
      }
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
  
  void _processPayment() async {
    // The card fields carry no per-field validators, so Form.validate() alone
    // always passes. _validateForm() holds the actual card checks.
    if (_formKey.currentState?.validate() != true) {
      return;
    }
    if (!_validateForm()) {
      return;
    }

    setState(() {
      _isProcessing = true;
    });
    
    // Simulate API call
    await Future.delayed(const Duration(seconds: 2));
    
    setState(() {
      _isProcessing = false;
    });
    
    if (_selectedMethod == 'cash_on_delivery') {
      _showCashOnDeliveryConfirmation();
    } else {
      _showOrderConfirmation();
    }
  }
  
  void _showCashOnDeliveryConfirmation() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Order Placed!'),
          content: const Text('Your order has been placed successfully with Cash on Delivery. You will pay when you receive the items.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
              child: const Text('Continue Shopping', style: TextStyle(color: Color(0xFF6C63FF))),
            ),
          ],
        );
      },
    );
  }
  
  void _showOrderConfirmation() {
    showDialog(
      context: context,
      barrierDismissible: false, // Prevent dismissing by tapping outside
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Order Confirmed!'),
          content: const Text('Your order has been confirmed. Continue shopping!'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
              child: const Text('Continue Shopping', style: TextStyle(color: Color(0xFF6C63FF))),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Payment Method',
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
              // A single RadioGroup owns the selection for all payment tiles.
              RadioGroup<String>(
                groupValue: _selectedMethod,
                onChanged: (value) {
                  if (value == null) return;
                  setState(() {
                    _selectedMethod = value;
                  });
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Matches the default _selectedMethod and makes the card
                    // form below reachable from the UI.
                    _buildPaymentMethodTile(
                      title: 'Credit / Debit Card',
                      icon: Icons.credit_card,
                      value: 'credit_card',
                    ),
                    _buildPaymentMethodTile(
                      title: 'JazzCash',
                      icon: Icons.phone_android,
                      value: 'jazzcash',
                    ),
                    _buildPaymentMethodTile(
                      title: 'EasyPaisa',
                      icon: Icons.phone_android,
                      value: 'easypaisa',
                    ),
                    _buildPaymentMethodTile(
                      title: 'Cash on Delivery',
                      icon: Icons.money,
                      value: 'cash_on_delivery',
                    ),
                  ],
                ),
              ),
              if (_selectedMethod == 'credit_card') ..._buildCreditCardForm(),
              const SizedBox(height: 24),
              _buildOrderSummary(),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  // Blocks double submissions while the payment is in flight.
                  onPressed: _isProcessing ? null : _processPayment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6C63FF),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isProcessing
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Confirm Order',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
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

  List<Widget> _buildCreditCardForm() {
    return [
      const SizedBox(height: 24),
      _buildSectionHeader('Card Details'),
      const SizedBox(height: 16),
      TextFormField(
        controller: _cardNumberController,
        decoration: InputDecoration(
          labelText: 'Card Number',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          prefixIcon: const Icon(Icons.credit_card),
        ),
        keyboardType: TextInputType.number,
      ),
      const SizedBox(height: 16),
      Row(
        children: [
          Expanded(
            child: TextFormField(
              controller: _expiryController,
              decoration: InputDecoration(
                labelText: 'MM/YY',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              keyboardType: TextInputType.datetime,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: TextFormField(
              controller: _cvvController,
              decoration: InputDecoration(
                labelText: 'CVV',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              keyboardType: TextInputType.number,
              obscureText: true,
            ),
          ),
        ],
      ),
      const SizedBox(height: 16),
      TextFormField(
        controller: _cardNameController,
        decoration: InputDecoration(
          labelText: 'Cardholder Name',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          prefixIcon: const Icon(Icons.person_outline),
        ),
      ),
    ];
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

  /// Selection state comes from the enclosing [RadioGroup]; this only needs to
  /// know whether it is the selected one so it can style itself.
  Widget _buildPaymentMethodTile({
    required String title,
    required IconData icon,
    required String value,
  }) {
    final bool isSelected = _selectedMethod == value;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected
                ? const Color(0xFF6C63FF)
                : Colors.grey.shade300,
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: RadioListTile<String>(
          title: Row(
            children: [
              Icon(icon, color: isSelected ? const Color(0xFF6C63FF) : Colors.grey),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  color: isSelected ? const Color(0xFF6C63FF) : Colors.black87,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
          value: value,
          activeColor: const Color(0xFF6C63FF),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        ),
      ),
    );
  }

  Widget _buildOrderSummary() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Order Summary',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildOrderRow('Subtotal', 'RS ${widget.totalAmount.toStringAsFixed(2)}'),
          const SizedBox(height: 8),
          _buildOrderRow('Shipping', 'Free'),
          const Divider(height: 32),
          _buildOrderRow(
            'Total',
            'RS ${widget.totalAmount.toStringAsFixed(2)}',
            isBold: true,
            isAccent: true,
          ),
          const SizedBox(height: 8),
          Text(
            '${widget.totalItems} items',
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

}
