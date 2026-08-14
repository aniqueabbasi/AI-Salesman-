import 'package:prac/models/Product.dart';

/// Mock product source. This class currently serves in-memory data only; the
/// MongoDB Atlas Data API connection settings and headers were removed because
/// nothing referenced them. Restore them alongside a real HTTP call if this is
/// ever wired to Atlas.
class MongoService {
  // Cache to store products
  static List<Product> _cachedProducts = [];
  static DateTime? _lastFetch;
  
  // Fetch all products with real-time updates
  static Future<List<Product>> getProducts() async {
    // If we have cached products and they're less than 5 minutes old, return them
    if (_cachedProducts.isNotEmpty && _lastFetch != null) {
      final difference = DateTime.now().difference(_lastFetch!);
      if (difference.inMinutes < 5) {
        return _cachedProducts;
      }
    }
    
    // For demo purposes, just return mock data
    _cachedProducts = _getMockProducts();
    _lastFetch = DateTime.now();
    return _cachedProducts;
  }
  
  // Get a specific product by ID with real-time data
  static Future<Product> getProductById(String id) async {
    // First check if it's in the cache
    if (_cachedProducts.isNotEmpty) {
      final product = _cachedProducts.firstWhere(
        (p) => p.id == id, 
        orElse: () => Product(
          id: '', 
          name: '', 
          price: 0, 
          images: []
        )
      );
      
      if (product.id.isNotEmpty) return product;
    }
    
    // For demo purposes, return from mock data
    final products = _getMockProducts();
    final product = products.firstWhere(
      (p) => p.id == id,
      orElse: () => Product(
        id: '', 
        name: '', 
        price: 0, 
        images: []
      )
    );
    
    if (product.id.isEmpty) {
      throw Exception('Product not found');
    }
    
    return product;
  }
  
  // Mock data for testing
  static List<Product> _getMockProducts() {
    return [
      Product(
        id: '1',
        name: 'Premium Denim Jacket',
        description: 'A stylish denim jacket perfect for any casual outfit.',
        price: 79.99,
        originalPrice: 99.99,
        images: ['assets/images/jacket1.jpg', 'assets/images/jacket2.jpg'],
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
        images: ['assets/images/jean1.jpg', 'assets/images/jean2.jpg'],
        category: 'Jean',
        sizes: ['28', '30', '32', '34', '36'],
      ),
      Product(
        id: '3',
        name: 'Runner Sports Shoes',
        description: 'Comfortable sports shoes for your daily workout.',
        price: 89.99,
        originalPrice: 109.99,
        images: ['assets/images/shoe1.jpg', 'assets/images/shoe2.jpg'],
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
        images: ['assets/images/shirt6.jpg'],
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
        images: ['assets/images/jean3.jpg', 'assets/images/jean4.jpg'],
        category: 'Jean',
        isNew: true,
        sizes: ['28', '30', '32', '34'],
        colors: ['Blue', 'Dark Blue'],
      ),
    ];
  }
} 