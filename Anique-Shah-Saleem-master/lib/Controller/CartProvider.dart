import 'package:flutter/cupertino.dart';
import 'package:prac/models/order_model.dart';
// Using our new Product model
import 'package:prac/models/Product.dart';
import 'package:prac/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CartProvider extends ChangeNotifier {
  List<dynamic> _recommendations = [];

  List<dynamic> get recommendations => _recommendations;
  final List<Map<String, dynamic>> cart = [];
  bool _isLoading = false;
  String _error = '';

  bool get isLoading => _isLoading;
  String get error => _error;

  // Add a product to the cart
  void addProduct(Map<String, dynamic> product) {
    // Check if the product with the same id and size is already in the cart
    final existingProductIndex = cart.indexWhere((item) =>
        item['id'] == product['id'] && item['size'] == product['size']);
    if (existingProductIndex >= 0) {
      cart[existingProductIndex]['quantity'] += product['quantity'];
    } else {
      cart.add(product);
    }
    notifyListeners();
  }

  // New method to add a Product object to the cart
  void addToCart(Product product, BuildContext context, {String? selectedSize}) {
    // Debug log the product details
    debugPrint('Adding product to cart:');
    debugPrint('  ID: ${product.id}');
    debugPrint('  Name: ${product.name}');
    debugPrint('  Images: ${product.images}');
    
    // Ensure we have a valid image URL
    String imageUrl = '';
    
    // Handle the case where images might be null or empty
    final images = product.images;
    if (images.isNotEmpty) {
      // Get the first image
      String firstImage = images.first.trim();
      debugPrint('  First image path: $firstImage');
      
      // Handle different image path formats
      if (firstImage.startsWith('http')) {
        imageUrl = firstImage; // Network image
        debugPrint('  Using as network image');
      } else if (firstImage.startsWith('assets/')) {
        imageUrl = firstImage; // Full asset path
        debugPrint('  Using as full asset path');
      } else if (firstImage.isNotEmpty) {
        // Clean up the path
        firstImage = firstImage.replaceAll('\\', '/');
        
        // Try different possible asset paths
        if (firstImage.startsWith('images/')) {
          imageUrl = 'assets/$firstImage';
          debugPrint('  Added assets/ prefix: $imageUrl');
        } else if (!firstImage.startsWith('assets/')) {
          // Try with assets/images/ prefix
          imageUrl = 'assets/images/$firstImage';
          debugPrint('  Trying assets/images/ path: $imageUrl');
          
          // Also try with just the filename in assets/images/
          if (firstImage.contains('/')) {
            final filename = firstImage.split('/').last;
            final altPath = 'assets/images/$filename';
            debugPrint('  Also trying direct filename: $altPath');
            imageUrl = altPath; // Try this path first
          }
        } else {
          imageUrl = firstImage;
          debugPrint('  Using original path: $imageUrl');
        }
      }
    } else {
      debugPrint('  No images found for product');
    }
    
    // Fallback to a placeholder if no valid image was found
    if (imageUrl.isEmpty) {
      imageUrl = 'assets/images/placeholder.jpg';
    }

    // Final check - if imageUrl is still empty or doesn't exist, use a placeholder
    if (imageUrl.isEmpty) {
      imageUrl = 'assets/images/placeholder.jpg';
      debugPrint('  Using fallback placeholder image');
    }
    
    debugPrint('  Final image path: $imageUrl');
    
    // Convert Product to a cart item
    Map<String, dynamic> cartItem = {
      'id': product.id,
      'name': product.name,
      'price': product.price,
      'image': imageUrl,
      'category': product.category ?? '',
      'quantity': 1,
      'size': selectedSize ?? (product.sizes?.isNotEmpty == true ? product.sizes!.first : 'Default'),
    };
    
    addProduct(cartItem);
    
    // Debug log the final cart item
    debugPrint('Added to cart: ${cartItem['name']}');
    debugPrint('  Image: ${cartItem['image']}');
  }

  // Check if a product is already in the cart
  bool isProductInCart(String productId) {
    return cart.any((item) => item['id'] == productId);
  }

  // Remove a product from the cart
  void removeProduct(Map<String, dynamic> product) {
    cart.removeWhere((item) =>
        item['id'] == product['id'] && item['size'] == product['size']);
    notifyListeners();
  }
  
  // Remove a product by ID from the cart
  void removeFromCart(String productId) {
    cart.removeWhere((item) => item['id'] == productId);
    notifyListeners();
  }

  // Update the quantity of a product in the cart
  void updateQuantity(Map<String, dynamic> product, int change) {
    // Find the product in the cart
    final cartItemIndex = cart.indexWhere((item) =>
        item['id'] == product['id'] && item['size'] == product['size']);

    // If the product is found, update its quantity
    if (cartItemIndex != -1) {
      cart[cartItemIndex]['quantity'] += change;
      // Ensure quantity doesn't go below 1
      if (cart[cartItemIndex]['quantity'] < 1) {
        cart[cartItemIndex]['quantity'] = 1;
      }
      notifyListeners();
    }
  }

  double getTotalPrice() {
    double totalPrice = 0;
    for (var item in cart) {
      totalPrice += item['price'] * item['quantity'];
    }
    return totalPrice;
  }

  // Create an order from the cart
  Future<String?> createOrder({
    required String shippingAddress,
    required String paymentMethod,
  }) async {
    if (cart.isEmpty) {
      _error = 'Cart is empty';
      notifyListeners();
      return null;
    }

    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      // Get the user ID from shared preferences
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');

      if (userId == null) {
        _error = 'User not logged in';
        notifyListeners();
        return null;
      }

      // Convert cart items to order items
      final items = cart
          .map((item) => OrderItem(
                productId: item['id'],
                quantity: item['quantity'],
                price: item['price'].toDouble(),
              ))
          .toList();

      // Create the order data
      final orderData = {
        'user_id': userId,
        'items': items.map((item) => item.toJson()).toList(),
        'total_amount': getTotalPrice(),
        'status': 'pending',
        'shipping_address': shippingAddress,
        'payment_method': paymentMethod,
      };

      // Send the order to the API
      final orderId = await ApiService.createOrder(orderData);

      // Fetch recommendations based on the first product's category (simple heuristic)
      if (cart.isNotEmpty && cart.first.containsKey('category')) {
        try {
          _recommendations = await ApiService.getRecommendations(cart.first['category']);
        } catch (e) {
          // Ignore recommendation errors for now – they are non-critical
        }
      }

      // Clear the cart after successful order
      cart.clear();
      notifyListeners();

      return orderId;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
