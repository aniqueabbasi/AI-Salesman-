import 'package:flutter/material.dart';
import 'package:prac/AppScreens/Seller/AddProductScreen.dart';
import 'package:prac/models/Product.dart';
import 'package:prac/screens/splash_screen.dart';
import 'package:prac/services/api_service.dart';
import 'package:prac/services/auth_service.dart';

/// Home screen for seller accounts: shows their listings and lets them add or
/// remove products. Customers never reach this screen.
class SellerDashboard extends StatefulWidget {
  const SellerDashboard({super.key});

  @override
  State<SellerDashboard> createState() => _SellerDashboardState();
}

class _SellerDashboardState extends State<SellerDashboard> {
  static const Color _accent = Color(0xFF6C63FF);

  List<Product> _products = [];
  bool _isLoading = true;
  String? _error;
  String _shopName = 'My Shop';
  String _email = '';

  @override
  void initState() {
    super.initState();
    _loadSeller();
    _loadProducts();
  }

  Future<void> _loadSeller() async {
    final shop = await AuthService.getShopName();
    final email = await AuthService.getEmail();
    if (!mounted) return;
    setState(() {
      if (shop != null && shop.isNotEmpty) _shopName = shop;
      _email = email ?? '';
    });
  }

  Future<void> _loadProducts() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final products = await ApiService.getMyProducts();
      if (!mounted) return;
      setState(() {
        _products = products;
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

  Future<void> _openAddProduct() async {
    final created = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const AddProductScreen()),
    );
    if (created == true) {
      await _loadProducts();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Product published to the storefront'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _confirmDelete(Product product) async {
    final messenger = ScaffoldMessenger.of(context);
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete product?'),
        content: Text(
            '"${product.name}" will be removed from the storefront for everyone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (shouldDelete != true) return;

    try {
      await ApiService.deleteProduct(product.id);
      await _loadProducts();
      messenger.showSnackBar(
        const SnackBar(content: Text('Product deleted')),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _logout() async {
    final navigator = Navigator.of(context);
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Log out'),
        content: const Text('Sign out of your seller account?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Log out', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (shouldLogout != true) return;

    await AuthService.clearToken();
    navigator.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const SplashScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_shopName,
                style: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 18)),
            if (_email.isNotEmpty)
              Text(_email,
                  style:
                      const TextStyle(color: Colors.black54, fontSize: 12)),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh, color: Colors.black87),
            onPressed: _loadProducts,
          ),
          IconButton(
            tooltip: 'Log out',
            icon: const Icon(Icons.logout, color: Colors.red),
            onPressed: _logout,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddProduct,
        backgroundColor: _accent,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Add Product',
            style:
                TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: RefreshIndicator(
        onRefresh: _loadProducts,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: _accent));
    }

    if (_error != null) {
      return ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 80),
          const Icon(Icons.cloud_off, size: 60, color: Colors.black26),
          const SizedBox(height: 16),
          Text(_error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.black54)),
          const SizedBox(height: 20),
          Center(
            child: ElevatedButton.icon(
              onPressed: _loadProducts,
              style: ElevatedButton.styleFrom(backgroundColor: _accent),
              icon: const Icon(Icons.refresh, color: Colors.white),
              label: const Text('Try again',
                  style: TextStyle(color: Colors.white)),
            ),
          ),
        ],
      );
    }

    return Column(
      children: [
        _buildSummary(),
        Expanded(
          child: _products.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 90),
                  itemCount: _products.length,
                  itemBuilder: (context, index) =>
                      _buildProductTile(_products[index]),
                ),
        ),
      ],
    );
  }

  Widget _buildSummary() {
    final totalStock = _products.fold<int>(0, (sum, p) => sum + (p.stock ?? 0));
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(vertical: 18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_accent, Color(0xFF8F87FF)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          _summaryCell('${_products.length}', 'Products'),
          Container(width: 1, height: 34, color: Colors.white24),
          _summaryCell('$totalStock', 'Items in stock'),
        ],
      ),
    );
  }

  Widget _summaryCell(String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Text(value,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(color: Colors.white70, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return ListView(
      children: const [
        SizedBox(height: 60),
        Icon(Icons.storefront_outlined, size: 72, color: Colors.black26),
        SizedBox(height: 16),
        Text('No products yet',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black54)),
        SizedBox(height: 8),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 40),
          child: Text(
            'Tap "Add Product" to publish your first listing. It will show up in the customer storefront right away.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.black45),
          ),
        ),
      ],
    );
  }

  Widget _buildProductTile(Product product) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: 72,
                height: 72,
                child: _buildThumbnail(product),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(product.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 4),
                  Text('PKR ${product.price.toStringAsFixed(0)}',
                      style: const TextStyle(
                          color: _accent, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _chip(product.category ?? 'Uncategorised'),
                      const SizedBox(width: 6),
                      _chip('Stock ${product.stock ?? 0}'),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Delete',
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: () => _confirmDelete(product),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label,
          style: const TextStyle(fontSize: 11, color: Colors.black54)),
    );
  }

  /// Seller uploads come back as http URLs; the seeded catalogue uses bundled
  /// asset paths. Handle both so every tile shows something.
  Widget _buildThumbnail(Product product) {
    const fallback = Icon(Icons.image_not_supported_outlined,
        color: Colors.black26, size: 28);

    if (product.images.isEmpty || product.images.first.trim().isEmpty) {
      return Container(color: Colors.grey.shade100, child: fallback);
    }

    final source = product.images.first.trim();
    if (source.startsWith('http')) {
      return Image.network(
        source,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) =>
            Container(color: Colors.grey.shade100, child: fallback),
      );
    }
    return Image.asset(
      source,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) =>
          Container(color: Colors.grey.shade100, child: fallback),
    );
  }
}
