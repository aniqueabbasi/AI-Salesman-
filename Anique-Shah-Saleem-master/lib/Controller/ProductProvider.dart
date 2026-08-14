import 'package:flutter/material.dart';
import 'package:prac/models/Product.dart';

import '../services/api_service.dart';
import 'package:prac/AppScreens/ShopMenu/dummy_products.dart' show dummyJeans, dummyShoes, dummyShirts, dummyJackets;


class ProductProvider extends ChangeNotifier {
  List<Product> _products = [];
  bool _isLoading = false;
  String _error = '';

  List<Product> get products => _products;
  bool get isLoading => _isLoading;
  String get error => _error;

  Future<void> fetchProducts() async {
    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      // Try to fetch products from backend REST API first
      try {
        // Ask for a large page so newly added seller listings are not cut off
        // by the default 20-item limit.
        final productsJson = await ApiService.getProducts(limit: 200);
        _products = productsJson.map<Product>((json) {
          // Ensure we have an `images` list as expected by the model
          final map = Map<String, dynamic>.from(json);
          if (!map.containsKey('images')) {
            if (map.containsKey('image')) {
              map['images'] = [map['image']];
            } else {
              map['images'] = <String>[];
            }
          }
          // Debug print for image URLs
          debugPrint('Product: \\${map['name']}\\ Images: \\${map['images']}');
          return Product.fromJson(map);
        }).toList();
        // Previously this dropped every Jean-category product. That also hid
        // seller-listed jeans from the storefront, so the filter is gone and
        // the backend is the single source of truth.
        debugPrint('📦 [ProductProvider] fetched ${_products.length} products');
        for (var p in _products) {
          debugPrint('  - \$${p.price} ${p.id} ${p.name} (category: ${p.category})');
        }
      } catch (_) {
        // Re-throw to propagate the error to the outer handler once logging is done
        rethrow;
      }
    } catch (e) {
      _error = e.toString();
      // The backend is unreachable. Fall back to the bundled catalogue so the
      // UI still has something to render instead of an empty screen.
      _products = _getDummyProducts();
      debugPrint(
          '⚠️ [ProductProvider] API failed ($e); using ${_products.length} bundled products');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Helper method to generate dummy products for UI demonstration
  List<Product> _getDummyProducts() {
    return [
      Product(
        id: '1',
        name: 'Premium Denim Jacket',
        description: 'A stylish denim jacket perfect for any casual outfit.',
        price: 7900.99,
        originalPrice: 7900.99,
        images: ['assets/images/i1.jpg', 'assets/images/i1.jpg'],
        category: 'Jacket',
        isNew: true,
        discount: 20,
        sizes: ['S', 'M', 'L', 'XL'],
        colors: ['Blue', 'Black'],
      ),
      Product(
        id: '2',
        name: 'Classic Black Jeans',
        description: 'Timeless black jeans that go with everything.',
        price: 59.99,
        images: ['assets/images/i1.jpg', 'assets/images/i1.jpg'],
        category: 'Jean',
        sizes: ['28', '30', '32', '34', '36'],
      ),
      Product(
        id: '3',
        name: 'Runner Sports Shoes',
        description: 'Comfortable sports shoes for your daily workout.',
        price: 89.99,
        originalPrice: 109.99,
        images: ['assets/images/a1.jpg', 'assets/images/shoe2.jpg'],
        category: 'Shoes',
        discount: 18,
        sizes: ['40', '41', '42', '43', '44'],
        colors: ['White', 'Black', 'Blue'],
      ),
      Product(
        id: '4',
        name: 'Casual Cotton Shirt',
        description: 'Soft cotton shirt for a relaxed casual look.',
        price: 45.99,
        images: ['assets/images/a11.jpg'],
        category: 'Shirt',
        isNew: true,
        sizes: ['S', 'M', 'L', 'XL'],
        colors: ['White', 'Blue', 'Grey'],
      ),
      Product(
        id: '5',
        name: 'Winter Jacket',
        description: 'Warm winter jacket to keep you cozy during cold days.',
        price: 129.99,
        originalPrice: 149.99,
        images: ['assets/images/jacket4.jpg', 'assets/images/jacket5.jpg'],
        category: 'Jacket',
        discount: 13,
        sizes: ['S', 'M', 'L', 'XL', 'XXL'],
        colors: ['Green', 'Black', 'Brown'],
      ),
      Product(
        id: '6',
        name: 'Slim Fit Jeans',
        description: 'Modern slim fit jeans for a trendy look.',
        price: 64.99,
        images: ['assets/images/a2.jpg', 'assets/images/a3.jpg'],
        category: 'Jean',
        isNew: true,
        sizes: ['28', '30', '32', '34'],
        colors: ['Blue', 'Dark Blue'],
      ),
      // New products added below
      Product(
        id: '7',
        name: 'Leather High-Top Shoes',
        description: 'Premium leather high-top shoes with superior comfort.',
        price: 119.99,
        originalPrice: 139.99,
        images: ['assets/images/a4.jpg', 'assets/images/shoe2.jpg'],
        category: 'Shoes',
        discount: 15,
        sizes: ['39', '40', '41', '42', '43', '44'],
        colors: ['Black', 'Brown', 'Tan'],
      ),
      Product(
        id: '8',
        name: 'Lightweight Running Shoes',
        description: 'Ultra lightweight shoes perfect for daily running.',
        price: 99.99,
        images: ['assets/images/shoe2.jpg', 'assets/images/shoe1.jpg'],
        category: 'Shoes',
        isNew: true,
        sizes: ['40', '41', '42', '43', '44', '45'],
        colors: ['Red', 'Black', 'Blue'],
      ),
      Product(
        id: '9',
        name: 'Canvas Sneakers',
        description: 'Casual canvas sneakers for everyday wear.',
        price: 49.99,
        originalPrice: 59.99,
        images: ['assets/images/shoe1.jpg', 'assets/images/shoe2.jpg'],
        category: 'Shoes',
        discount: 17,
        sizes: ['38', '39', '40', '41', '42', '43'],
        colors: ['White', 'Black', 'Blue', 'Red'],
      ),
      Product(
        id: '10',
        name: 'Formal Oxford Shoes',
        description: 'Classic formal oxford shoes for business occasions.',
        price: 129.99,
        images: ['assets/images/shoe2.jpg', 'assets/images/shoe1.jpg'],
        category: 'Shoes',
        sizes: ['40', '41', '42', '43', '44'],
        colors: ['Black', 'Brown'],
      ),
      Product(
        id: '11',
        name: 'Designer Graphic Shirt',
        description: 'Bold graphic print shirt with modern design.',
        price: 55.99,
        originalPrice: 65.99,
        images: ['assets/images/shirt6.jpg'],
        category: 'Shirt',
        discount: 15,
        sizes: ['S', 'M', 'L', 'XL'],
        colors: ['White', 'Black'],
      ),
      Product(
        id: '12',
        name: 'Business Formal Shirt',
        description: 'Professional formal shirt with wrinkle-resistant fabric.',
        price: 59.99,
        images: ['assets/images/shirt6.jpg'],
        category: 'Shirt',
        sizes: ['S', 'M', 'L', 'XL', 'XXL'],
        colors: ['White', 'Blue', 'Light Blue', 'Pink'],
      ),
      Product(
        id: '13',
        name: 'Linen Summer Shirt',
        description: 'Breathable linen shirt perfect for hot summer days.',
        price: 49.99,
        originalPrice: 59.99,
        images: ['assets/images/shirt6.jpg'],
        category: 'Shirt',
        discount: 17,
        sizes: ['S', 'M', 'L', 'XL'],
        colors: ['White', 'Beige', 'Light Blue'],
        isNew: true,
      ),
      Product(
        id: '14',
        name: 'Flannel Checkered Shirt',
        description: 'Warm flannel shirt with classic checkered pattern.',
        price: 47.99,
        images: ['assets/images/shirt6.jpg'],
        category: 'Shirt',
        sizes: ['S', 'M', 'L', 'XL', 'XXL'],
        colors: ['Red', 'Blue', 'Green'],
      ),
      Product(
        id: '15',
        name: 'Distressed Jeans',
        description: 'Trendy distressed jeans with modern fit.',
        price: 69.99,
        originalPrice: 79.99,
        images: ['assets/images/jean1.jpg', 'assets/images/jean2.jpg'],
        category: 'Jean',
        discount: 13,
        sizes: ['28', '30', '32', '34', '36'],
        colors: ['Blue', 'Light Blue'],
      ),
      Product(
        id: '16',
        name: 'High-Waisted Jeans',
        description: 'Fashionable high-waisted jeans with perfect fit.',
        price: 74.99,
        images: ['assets/images/jean3.jpg', 'assets/images/jean4.jpg'],
        category: 'Jean',
        isNew: true,
        sizes: ['26', '28', '30', '32', '34'],
        colors: ['Dark Blue', 'Black'],
      ),
      Product(
        id: '17',
        name: 'Cargo Jeans',
        description: 'Functional cargo jeans with multiple pockets.',
        price: 79.99,
        images: ['assets/images/jean2.jpg', 'assets/images/jean1.jpg'],
        category: 'Jean',
        sizes: ['30', '32', '34', '36', '38'],
        colors: ['Olive', 'Black', 'Khaki'],
      ),
      Product(
        id: '18',
        name: 'Leather Biker Jacket',
        description: 'Classic leather biker jacket with metal details.',
        price: 189.99,
        originalPrice: 219.99,
        images: ['assets/images/jacket2.jpg', 'assets/images/jacket1.jpg'],
        category: 'Jacket',
        discount: 14,
        sizes: ['S', 'M', 'L', 'XL'],
        colors: ['Black', 'Brown'],
        isNew: true,
      ),
      Product(
        id: '19',
        name: 'Puffer Jacket',
        description: 'Warm puffer jacket with water-resistant outer layer.',
        price: 145.99,
        images: ['assets/images/jacket5.jpg', 'assets/images/jacket4.jpg'],
        category: 'Jacket',
        sizes: ['S', 'M', 'L', 'XL', 'XXL'],
        colors: ['Red', 'Black', 'Navy'],
      ),
      Product(
        id: '20',
        name: 'Waterproof Hiking Jacket',
        description: 'Durable waterproof jacket designed for outdoor adventures.',
        price: 159.99,
        originalPrice: 179.99,
        images: ['assets/images/jacket4.jpg', 'assets/images/jacket5.jpg'],
        category: 'Jacket',
        discount: 11,
        sizes: ['S', 'M', 'L', 'XL'],
        colors: ['Green', 'Blue', 'Black'],
      ),
      Product(
        id: '21',
        name: 'Summer Denim Jacket',
        description: 'Lightweight denim jacket perfect for cool summer evenings.',
        price: 69.99,
        images: ['assets/images/jacket1.jpg', 'assets/images/jacket2.jpg'],
        category: 'Jacket',
        isNew: true,
        sizes: ['S', 'M', 'L', 'XL'],
        colors: ['Light Blue', 'White'],
      ),
      Product(
        id: '22',
        name: 'Vintage Washed Jeans',
        description: 'Retro-style jeans with vintage wash effect.',
        price: 84.99,
        originalPrice: 94.99,
        images: ['assets/images/jean4.jpg', 'assets/images/jean3.jpg'],
        category: 'Jean',
        discount: 11,
        sizes: ['28', '30', '32', '34'],
        colors: ['Blue', 'Grey'],
      ),
      Product(
        id: '23',
        name: 'Casual Oxford Button-Down',
        description: 'Versatile oxford button-down shirt for any occasion.',
        price: 52.99,
        images: ['assets/images/shirt6.jpg'],
        category: 'Shirt',
        sizes: ['S', 'M', 'L', 'XL', 'XXL'],
        colors: ['Light Blue', 'White', 'Pink', 'Grey'],
      ),
      Product(
        id: '24',
        name: 'Trail Running Shoes',
        description: 'Rugged trail running shoes with excellent grip.',
        price: 114.99,
        originalPrice: 129.99,
        images: ['assets/images/i1.jpg', 'assets/images/i1.jpg'],
        category: 'Shoes',
        discount: 12,
        sizes: ['40', '41', '42', '43', '44', '45'],
        colors: ['Grey/Orange', 'Black/Green', 'Blue/Yellow'],
      ),
    ];
  }

  Future<Product?> fetchProductById(String id) async {
    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      // First check if product is in the local list
      final localProduct = _products.firstWhere(
        (p) => p.id == id,
        orElse: () => Product(
          id: '', name: '', price: 0, images: [],
        ),
      );
      
      if (localProduct.id.isNotEmpty) {
        _isLoading = false;
        notifyListeners();
        return localProduct;
      }
      
      // If product not found locally, try to fetch it from backend
      try {
        final productJson = await ApiService.getProductById(id);
        final map = Map<String, dynamic>.from(productJson);
        if (!map.containsKey('images')) {
          if (map.containsKey('image')) {
            map['images'] = [map['image']];
          } else {
            map['images'] = <String>[];
          }
        }
        final fetchedProduct = Product.fromJson(map);
        // Optionally add to local list/cache
        _products.add(fetchedProduct);
        _isLoading = false;
        notifyListeners();
        return fetchedProduct;
      } catch (_) {
        _isLoading = false;
        notifyListeners();
        return null;
      }
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  List<Product> getProductsByCategory(String category) {
    final cat = category.trim().toLowerCase();
    if (cat == 'all') {
      debugPrint('[ProductProvider] Returning all products: ${_products.length}');
      return _products;
    }
    // For Jean category, always return local dummyJeans list so we can customize images
    if (cat == 'jean' || cat == 'jeans') {
      return dummyJeans;
    }
    if (cat == 'shoes' || cat == 'shoe') {
      return dummyShoes;
    }
    if (cat == 'shirt' || cat == 'shirts') {
      return dummyShirts;
    }
    if (cat == 'jacket' || cat == 'jackets') {
      return dummyJackets;
    }

    var filtered = _products.where((product) =>
      (product.category ?? '').toLowerCase().trim() == cat).toList();

    debugPrint('[ProductProvider] Filtered by "$category": ${filtered.length} products');
    return filtered;
  }
  
  // Refresh products to get real-time data
  Future<void> refreshProducts() async {
    // Simply re-fetch products from the backend and notify listeners
    await fetchProducts();
  }
}
