import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart' show MediaType;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/Product.dart';
import 'package:prac/AppScreens/ShopMenu/Jeans/JeanGlobalVariable.dart' show JeanProducts;
import '../config/api_config.dart';
import 'auth_service.dart';

class ApiService {
  // Base URL for the API
  static String get baseUrl => ApiConfig.mainBaseUrl;
  
  // Get products by category with retry logic
  static Future<List<Product>> getProductsByCategory(String category, {int maxRetries = 3}) async {
    // Local fallback for Jean category
    if (category.toLowerCase() == 'jean' || category.toLowerCase() == 'jeans') {
      return JeanProducts.map((json) => Product.fromJson(json)).toList();
    }
    
    int attempt = 0;
    while (attempt < maxRetries) {
      try {
        final response = await http.get(
          Uri.parse('$baseUrl/products/category/$category'),
          headers: await _getHeaders(),
        ).timeout(const Duration(seconds: 10));

        if (response.statusCode == 200) {
          final List<dynamic> data = jsonDecode(response.body);
          return data.map((json) => Product.fromJson(json)).toList();
        } else {
          debugPrint('API Error (${response.statusCode}): ${response.body}');
          throw Exception('Failed to load products: ${response.statusCode}');
        }
      } catch (e) {
        attempt++;
        debugPrint('! [ApiService] Retry attempt #$attempt, error: $e');
        if (attempt >= maxRetries) {
          debugPrint('! [ApiService] Max retries reached for category: $category');
          rethrow;
        }
        // Exponential backoff before retry
        await Future.delayed(Duration(seconds: 1 * attempt));
      }
    }
    
    // If we get here, all retries failed
    throw Exception('Failed to load products after $maxRetries attempts');
  }

  // Flag to enable mock API behaviour (set USE_MOCK=true in .env to activate)
  static bool get _useMock {
    try {
      return dotenv.get('USE_MOCK', fallback: 'false').toLowerCase() == 'true';
    } catch (e) {
      debugPrint('Error reading USE_MOCK from .env: $e');
      return false;
    }
  }

  // Headers for API requests
  static Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    
    // Headers for ngrok
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'ngrok-skip-browser-warning': 'true',  // Add this to skip ngrok browser warning
      'Cache-Control': 'no-cache',
    };
    
    // Add authorization token if available
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    
    return headers;
  }

  // Authentication methods
  static Future<Map<String, dynamic>> login(
      String email, String password) async {
    // Return mock response only if explicitly enabled via USE_MOCK flag
    if (_useMock) {
      return await _mockLogin(email, password);
    }
    
    // For mobile platforms, try to connect to the backend
    final response = await http.post(
      Uri.parse('$baseUrl/auth/signin'),
      headers: await _getHeaders(),
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      debugPrint('✅ [ApiService] ${response.statusCode} OK, bytes=${response.contentLength}');
      final data = jsonDecode(response.body);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', data['access_token']);

      final token = data['access_token'];
      final parts = token.split('.');
      if (parts.length == 3) {
        final payload = parts[1];
        final normalized = base64Url.normalize(payload);
        final decoded = utf8.decode(base64Url.decode(normalized));
        final payloadMap = jsonDecode(decoded);
        if (payloadMap.containsKey('sub')) {
          await prefs.setString('user_id', payloadMap['sub']);
        }
      }

      // Remember the role so the app can open the right home screen.
      final user = data['user'] as Map<String, dynamic>?;
      await AuthService.saveSession(
        token: token,
        role: (data['role'] ?? user?['role'] ?? 'customer').toString(),
        email: (user?['email'] ?? email).toString(),
        shopName: user?['shop_name']?.toString(),
      );

      return data;
    } else {
      throw Exception('Failed to login: ${response.body}');
    }
  }

  // Mock login for web platform
  static Future<Map<String, dynamic>> _mockLogin(String email, String password) async {
    // Simple validation
    if (email.isEmpty || !email.contains('@')) {
      throw Exception('Invalid email format');
    }
    
    if (password.isEmpty || password.length < 6) {
      throw Exception('Password must be at least 6 characters');
    }
    
    // Create a mock JWT token
    final Map<String, dynamic> payload = {
      'sub': 'user123',
      'email': email,
      'exp': DateTime.now().add(const Duration(hours: 24)).millisecondsSinceEpoch ~/ 1000,
    };
    
    // Encode payload to base64
    final String encodedPayload = base64Url.encode(utf8.encode(jsonEncode(payload)));
    // Create a simple token (not a real JWT, just for testing)
    final String mockToken = 'header.$encodedPayload.signature';
    
    // Save token to SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', mockToken);
    await prefs.setString('user_id', payload['sub']);
    
    // Return mock response
    return {
      'access_token': mockToken,
      'user': {
        'id': payload['sub'],
        'email': email,
      }
    };
  }

  /// Create an account. [role] is either 'customer' or 'seller'; sellers may
  /// also supply a [shopName] shown next to their listings.
  static Future<Map<String, dynamic>> register(
    String email,
    String password, {
    String role = 'customer',
    String? shopName,
  }) async {
    // Return mock response only if explicitly enabled via USE_MOCK flag
    if (_useMock) {
      return await _mockRegister(email, password);
    }

    final response = await http.post(
      Uri.parse('$baseUrl/auth/signup'),
      headers: await _getHeaders(),
      body: jsonEncode({
        'email': email,
        'password': password,
        'role': role,
        'is_admin': false,
        if (shopName != null && shopName.trim().isNotEmpty)
          'shop_name': shopName.trim(),
      }),
    );

    if (response.statusCode == 200) {
      debugPrint('✅ [ApiService] ${response.statusCode} OK, bytes=${response.contentLength}');
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to register: ${_errorDetail(response.body)}');
    }
  }

  /// Pull a readable message out of FastAPI's `{"detail": ...}` error body.
  static String _errorDetail(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map && decoded['detail'] != null) {
        final detail = decoded['detail'];
        if (detail is String) return detail;
        if (detail is List && detail.isNotEmpty) {
          final first = detail.first;
          if (first is Map && first['msg'] != null) return first['msg'].toString();
        }
        return detail.toString();
      }
    } catch (_) {
      // fall through to the raw body
    }
    return body;
  }

  // ---------------------------------------------------------------------
  // Seller product management
  // ---------------------------------------------------------------------

  /// Products listed by the signed-in seller.
  static Future<List<Product>> getMyProducts() async {
    final response = await http.get(
      Uri.parse('$baseUrl/products/mine'),
      headers: await _getHeaders(),
    ).timeout(const Duration(seconds: 15));

    if (response.statusCode == 200) {
      final List<dynamic> items = jsonDecode(response.body);
      return items
          .map<Product>((json) => Product.fromJson(Map<String, dynamic>.from(json)))
          .toList();
    }
    throw Exception('Failed to load your products: ${_errorDetail(response.body)}');
  }

  /// Create a listing owned by the signed-in seller. Returns the new id.
  static Future<String> createProduct({
    required String name,
    required String description,
    required double price,
    required int stock,
    required String category,
    List<String> images = const [],
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/products/'),
      headers: await _getHeaders(),
      body: jsonEncode({
        'name': name,
        'description': description,
        'price': price,
        'stock': stock,
        'category': category,
        'images': images,
      }),
    ).timeout(const Duration(seconds: 20));

    if (response.statusCode == 200) {
      // The endpoint returns the raw id as a JSON string.
      return jsonDecode(response.body).toString();
    }
    throw Exception('Failed to add product: ${_errorDetail(response.body)}');
  }

  /// Remove one of the seller's own listings.
  static Future<void> deleteProduct(String productId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/products/$productId'),
      headers: await _getHeaders(),
    ).timeout(const Duration(seconds: 20));

    if (response.statusCode != 200) {
      throw Exception('Failed to delete product: ${_errorDetail(response.body)}');
    }
  }

  // ---------------------------------------------------------------
  // Seller-scoped reads. Each is filtered server-side to the signed-in
  // seller's own listings, so one shop never sees another's figures.
  // ---------------------------------------------------------------

  /// The signed-in account's own profile.
  static Future<Map<String, dynamic>> getMyProfile() async {
    final response = await http.get(
      Uri.parse('$baseUrl/auth/me'),
      headers: await _getHeaders(),
    ).timeout(const Duration(seconds: 20));

    if (response.statusCode != 200) {
      throw Exception('Failed to load profile: ${_errorDetail(response.body)}');
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  /// Update contact details. Omitted fields are left untouched server-side.
  static Future<Map<String, dynamic>> updateMyProfile({
    String? fullName,
    String? phone,
    String? shopName,
  }) async {
    final response = await http.put(
      Uri.parse('$baseUrl/auth/me'),
      headers: await _getHeaders(),
      body: jsonEncode({
        if (fullName != null) 'full_name': fullName,
        if (phone != null) 'phone': phone,
        if (shopName != null) 'shop_name': shopName,
      }),
    ).timeout(const Duration(seconds: 20));

    if (response.statusCode != 200) {
      throw Exception('Failed to save profile: ${_errorDetail(response.body)}');
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  /// Dashboard headline figures: 30-day revenue, order counts, dispatch queue.
  static Future<Map<String, dynamic>> getSellerSummary() async {
    final response = await http.get(
      Uri.parse('$baseUrl/analytics/seller/summary'),
      headers: await _getHeaders(),
    ).timeout(const Duration(seconds: 20));

    if (response.statusCode != 200) {
      throw Exception('Failed to load summary: ${_errorDetail(response.body)}');
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  /// Orders containing at least one of this seller's products.
  static Future<List<Map<String, dynamic>>> getSellerOrders() async {
    final response = await http.get(
      Uri.parse('$baseUrl/orders/seller'),
      headers: await _getHeaders(),
    ).timeout(const Duration(seconds: 20));

    if (response.statusCode != 200) {
      throw Exception('Failed to load orders: ${_errorDetail(response.body)}');
    }
    return (jsonDecode(response.body) as List)
        .cast<Map<String, dynamic>>();
  }

  /// Weekly sales series, AOV, return rate and best sellers.
  static Future<Map<String, dynamic>> getSellerReport() async {
    final response = await http.get(
      Uri.parse('$baseUrl/reports/seller/sales'),
      headers: await _getHeaders(),
    ).timeout(const Duration(seconds: 20));

    if (response.statusCode != 200) {
      throw Exception('Failed to load report: ${_errorDetail(response.body)}');
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  static Future<void> updateSellerOrderStatus(
      String orderId, String status) async {
    final response = await http.put(
      Uri.parse('$baseUrl/orders/seller/$orderId/status?status=$status'),
      headers: await _getHeaders(),
    ).timeout(const Duration(seconds: 20));

    if (response.statusCode != 200) {
      throw Exception('Failed to update order: ${_errorDetail(response.body)}');
    }
  }

  /// Set stock on a listing this seller owns.
  static Future<void> updateProductStock(String productId, int stock) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/products/$productId/stock?stock=$stock'),
      headers: await _getHeaders(),
    ).timeout(const Duration(seconds: 20));

    if (response.statusCode != 200) {
      throw Exception('Failed to update stock: ${_errorDetail(response.body)}');
    }
  }

  /// Upload a product photo and get back a URL to store on the product.
  /// Image formats the API accepts, keyed by file extension.
  static const Map<String, String> _imageSubtypes = {
    '.jpg': 'jpeg',
    '.jpeg': 'jpeg',
    '.png': 'png',
    '.webp': 'webp',
    '.gif': 'gif',
  };

  static Future<String> uploadProductImage(File image) async {
    // MultipartFile defaults to application/octet-stream, which the API
    // rejects, so the type has to be derived from the file itself.
    final dotIndex = image.path.lastIndexOf('.');
    final extension =
        dotIndex == -1 ? '' : image.path.substring(dotIndex).toLowerCase();
    final subtype = _imageSubtypes[extension];

    if (subtype == null) {
      throw Exception(
        'Unsupported image format "$extension". Use a JPEG, PNG, WEBP or GIF.',
      );
    }

    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/products/upload-image'),
    );

    final token = await AuthService.getToken();
    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }
    request.files.add(await http.MultipartFile.fromPath(
      'file',
      image.path,
      contentType: MediaType('image', subtype),
    ));

    final streamed = await request.send().timeout(const Duration(seconds: 60));
    final response = await http.Response.fromStream(streamed);

    if (response.statusCode == 200) {
      return jsonDecode(response.body)['url'].toString();
    }
    throw Exception('Image upload failed: ${_errorDetail(response.body)}');
  }
  
  // Mock register for web platform
  static Future<Map<String, dynamic>> _mockRegister(String email, String password) async {
    // Simple validation
    if (email.isEmpty || !email.contains('@')) {
      throw Exception('Invalid email format');
    }
    
    if (password.isEmpty || password.length < 6) {
      throw Exception('Password must be at least 6 characters');
    }
    
    // Return mock response
    return {
      'message': 'User registered successfully',
      'user': {
        'id': 'user123',
        'email': email,
      }
    };
  }

  // Product methods
//   static Future<List<dynamic>> getProducts() async {
//   int retries = 0;
//   while (true) {
//     // Return mock products only when explicitly enabled via USE_MOCK flag
//     if (_useMock) {
//       return _getMockProducts();
//     }
    
//     debugPrint('🔍 [ApiService] GET $baseUrl/products/');
//     final response = await http.get(
//       Uri.parse('$baseUrl/products/'),
//       headers: await _getHeaders(),
//     );

//     if (response.statusCode == 200) {
//       debugPrint('✅ [ApiService] ${response.statusCode} OK, bytes=${response.contentLength}');
//       return jsonDecode(response.body);
//     }
//     // transient network glitch
//     if (retries < 2) {
//       retries++;
//       await Future.delayed(const Duration(seconds: 1));
//       continue;
//     }
//     throw Exception('Failed to load products: ${response.statusCode} ${response.reasonPhrase}');
//   }
// }
  static Future<List<dynamic>> getProducts({
  int skip = 0,  // Default value if not provided
  int limit = 20, // Default value if not provided
}) async {
  int retries = 0;

  while (true) {
    try {
      debugPrint('🔍 [ApiService] GET $baseUrl/products/?skip=$skip&limit=$limit');

      final response = await http.get(
        Uri.parse('$baseUrl/products/?skip=$skip&limit=$limit'),
        headers: await _getHeaders(),
      ).timeout(const Duration(seconds: 10)); // Set timeout to avoid hanging forever

      if (response.statusCode == 200) {
        debugPrint('✅ [ApiService] ${response.statusCode} OK, bytes=${response.contentLength}');
        
        // Decode the JSON response body
        Map<String, dynamic> productsJson = jsonDecode(response.body);
        List<dynamic> products = productsJson['items'];

        // Return the product list (or map to models if needed)
        return products;
      }

      // Handle non-200 responses (errors)
      throw Exception('Failed to load products: ${response.statusCode} ${response.reasonPhrase}');
    } catch (e) {
      // Handle timeout, retries, and other exceptions
      if (retries < 2) {
        retries++;
        debugPrint('⚠️ [ApiService] Retry attempt #$retries, error: $e');
        await Future.delayed(const Duration(seconds: 1)); // Wait before retrying
        continue;
      }

      // After 2 retries, throw the final error
      throw Exception('Failed to load products after retries: $e');
    }
  }
}
  // Mock products
  static List<dynamic> _getMockProducts() {
    return [
      {
        'id': '1',
        'name': 'Classic Blue Jacket',
        'description': 'Classic blue jacket for men',
        'price': 79.99,
        'image': 'assets/images/jacket1.jpg',
        'image_url': 'assets/images/jacket1.jpg',
        'category': 'jacket',
        'stock': 10,
        'created_at': DateTime.now().toString(),
        'updated_at': DateTime.now().toString()
      },
      {
        'id': '2',
        'name': 'Casual Jeans',
        'description': 'Comfortable casual jeans',
        'price': 49.99,
        'image': 'assets/images/jean1.jpg',
        'image_url': 'assets/images/jean1.jpg',
        'category': 'jeans',
        'stock': 15,
        'created_at': DateTime.now().toString(),
        'updated_at': DateTime.now().toString()
      },
      {
        'id': '3',
        'name': 'Running Shoes',
        'description': 'Lightweight running shoes',
        'price': 99.99,
        'image': 'assets/images/shoe1.jpg',
        'image_url': 'assets/images/shoe1.jpg',
        'category': 'shoes',
        'stock': 8,
        'created_at': DateTime.now().toString(),
        'updated_at': DateTime.now().toString()
      },
      {
        'id': '4',
        'name': 'Leather Jacket',
        'description': 'Stylish leather jacket',
        'price': 129.99,
        'image': 'assets/images/jacket2.jpg',
        'image_url': 'assets/images/jacket2.jpg',
        'category': 'jacket',
        'stock': 5,
        'created_at': DateTime.now().toString(),
        'updated_at': DateTime.now().toString()
      },
      {
        'id': '5',
        'name': 'Diner Leather Jacket',
        'description': 'Premium leather jacket for casual outings',
        'price': 150.00,
        'image': 'assets/images/jacket3.jpg',
        'image_url': 'assets/images/jacket3.jpg',
        'category': 'jacket',
        'stock': 7,
        'created_at': DateTime.now().toString(),
        'updated_at': DateTime.now().toString()
      },
      {
        'id': '6',
        'name': 'Derby Shiny Shoe',
        'description': 'Elegant derby shoes for formal occasions',
        'price': 120.00,
        'image': 'assets/images/shoe2.jpg',
        'image_url': 'assets/images/shoe2.jpg',
        'category': 'shoes',
        'stock': 12,
        'created_at': DateTime.now().toString(),
        'updated_at': DateTime.now().toString()
      },
      {
        'id': '7',
        'name': 'Spread Collar Cotton Shirt',
        'description': 'Comfortable cotton shirt with spread collar',
        'price': 35.00,
        'image': 'assets/images/shirt6.jpg',
        'image_url': 'assets/images/shirt6.jpg',
        'category': 'shirt',
        'stock': 20,
        'created_at': DateTime.now().toString(),
        'updated_at': DateTime.now().toString()
      },
      {
        'id': '8',
        'name': 'Round Neck White Shirt',
        'description': 'Classic round neck white t-shirt',
        'price': 25.00,
        'image': 'assets/images/jacket4.jpg',
        'image_url': 'assets/images/jacket4.jpg',
        'category': 'shirt',
        'stock': 25,
        'created_at': DateTime.now().toString(),
        'updated_at': DateTime.now().toString()
      },
      {
        'id': '9',
        'name': 'Classic Fit Dress Shirt',
        'description': 'Formal classic fit dress shirt',
        'price': 45.00,
        'image': 'assets/images/jacket5.jpg',
        'image_url': 'assets/images/jacket5.jpg',
        'category': 'shirt',
        'stock': 18,
        'created_at': DateTime.now().toString(),
        'updated_at': DateTime.now().toString()
      },
      {
        'id': '10',
        'name': 'Slim Fit Jeans',
        'description': 'Modern slim fit jeans for men',
        'price': 65.00,
        'image': 'assets/images/jean2.jpg',
        'image_url': 'assets/images/jean2.jpg',
        'category': 'jeans',
        'stock': 14,
        'created_at': DateTime.now().toString(),
        'updated_at': DateTime.now().toString()
      },
      {
        'id': '11',
        'name': 'Distressed Jeans',
        'description': 'Trendy distressed jeans',
        'price': 75.00,
        'image': 'assets/images/jean3.jpg',
        'image_url': 'assets/images/jean3.jpg',
        'category': 'jeans',
        'stock': 10,
        'created_at': DateTime.now().toString(),
        'updated_at': DateTime.now().toString()
      },
      {
        'id': '12',
        'name': 'Athletic Sneakers',
        'description': 'Comfortable athletic sneakers',
        'price': 85.00,
        'image': 'assets/images/shoe3.jpg',
        'image_url': 'assets/images/shoe3.jpg',
        'category': 'shoes',
        'stock': 15,
        'created_at': DateTime.now().toString(),
        'updated_at': DateTime.now().toString()
      },
      {
        'id': '13',
        'name': 'Formal Oxford Shoes',
        'description': 'Classic Oxford shoes for formal wear',
        'price': 110.00,
        'image': 'assets/images/shoe4.jpg',
        'image_url': 'assets/images/shoe4.jpg',
        'category': 'shoes',
        'stock': 8,
        'created_at': DateTime.now().toString(),
        'updated_at': DateTime.now().toString()
      },
      {
        'id': '14',
        'name': 'Casual Button Down Shirt',
        'description': 'Versatile button down shirt for casual occasions',
        'price': 40.00,
        'image': 'assets/images/jacket6.jpg',
        'image_url': 'assets/images/jacket6.jpg',
        'category': 'shirt',
        'stock': 22,
        'created_at': DateTime.now().toString(),
        'updated_at': DateTime.now().toString()
      },
      {
        'id': '15',
        'name': 'Cargo Jeans',
        'description': 'Functional cargo jeans with multiple pockets',
        'price': 55.00,
        'image': 'assets/images/jean4.jpg',
        'image_url': 'assets/images/jean4.jpg',
        'category': 'jeans',
        'stock': 12,
        'created_at': DateTime.now().toString(),
        'updated_at': DateTime.now().toString()
      },
      {
        'id': '16',
        'name': 'Winter Puffer Jacket',
        'description': 'Warm puffer jacket for winter',
        'price': 140.00,
        'image': 'assets/images/jacket7.jpg',
        'image_url': 'assets/images/jacket7.jpg',
        'category': 'jacket',
        'stock': 6,
        'created_at': DateTime.now().toString(),
        'updated_at': DateTime.now().toString()
      }
    ];
  }

  static Future<Map<String, dynamic>> getProductById(String productId) async {
    // Return mock product only when USE_MOCK=true
    if (_useMock) {
      final products = _getMockProducts();
      final product = products.firstWhere(
        (p) => p['id'] == productId,
        orElse: () => throw Exception('Product not found'),
      );
      return product;
    }
    
    final response = await http.post(
      Uri.parse('$baseUrl/products/fetch-product'),
      headers: await _getHeaders(),
      body: jsonEncode({
        'product_id': productId,
      }),
    );

    if (response.statusCode == 200) {
      debugPrint('✅ [ApiService] ${response.statusCode} OK, bytes=${response.contentLength}');
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load product: ${response.body}');
    }
  }

  // Order methods
  static Future<String> createOrder(Map<String, dynamic> orderData) async {
    // If web platform, return mock order
    if (kIsWeb) {
      return jsonEncode({'order_id': 'mock-order-${DateTime.now().millisecondsSinceEpoch}'});
    }
    
    final response = await http.post(
      Uri.parse('$baseUrl/orders'),
      headers: await _getHeaders(),
      body: jsonEncode(orderData),
    );

    if (response.statusCode == 200) {
      debugPrint('✅ [ApiService] ${response.statusCode} OK, bytes=${response.contentLength}');
      return response.body;
    } else {
      throw Exception('Failed to create order: ${response.body}');
    }
  }

  // Recommendation methods
  static Future<List<dynamic>> getRecommendations(String category) async {
    // First try to get recommendations from the API
    try {
      final requestBody = {
        'attributes': [
          {
            'attribute_type': 'category',
            'attribute_value': category,
          }
        ],
      };

      // Set a timeout for the API call
      final response = await http.post(
        Uri.parse('${ApiConfig.recommendationBaseUrl}/api/recommend'),
        headers: await _getHeaders(),
        body: jsonEncode(requestBody),
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        List<dynamic> allProducts = [];

        if (decoded is Map && decoded.containsKey('recommendations')) {
          for (final rec in decoded['recommendations']) {
            if (rec['matching_products'] != null) {
              allProducts.addAll(rec['matching_products']);
            }
          }
        } else if (decoded is List) {
          allProducts = decoded;
        }
        
        if (allProducts.isNotEmpty) {
          return allProducts.map((json) => Product.fromJson(json)).toList();
        }
      }
    } on SocketException catch (e) {
      debugPrint('Network error in getRecommendations: $e');
    } on TimeoutException catch (e) {
      debugPrint('Recommendation API request timed out: $e');
    } catch (e) {
      debugPrint('Error in getRecommendations: $e');
    }

    // Fallback to local recommendations if API fails
    try {
      final allProducts = await getProducts();
      if (allProducts.isNotEmpty) {
        // Filter products by category if possible
        final filtered = allProducts.where((p) {
          if (p.category == null) return true;
          return p.category!.toLowerCase().contains(category.toLowerCase());
        }).toList();
        
        // If we have filtered results, return them, otherwise return random products
        final sourceList = filtered.isNotEmpty ? filtered : allProducts;
        sourceList.shuffle();
        return sourceList.take(3).toList();
      }
    } catch (e) {
      debugPrint('Error in fallback recommendations: $e');
    }

    // If all else fails, return empty list
    return [];
  }

  static Future<List<dynamic>> getOrders() async {
    // If web platform, return mock orders
    if (kIsWeb) {
      return [
        {
          'id': 'mock-order-1',
          'date': DateTime.now().toString(),
          'total': 129.98,
          'items': [
            {
              'product_id': '1',
              'quantity': 1,
              'price': 79.99
            },
            {
              'product_id': '2',
              'quantity': 1,
              'price': 49.99
            }
          ]
        }
      ];
    }
    
    final response = await http.get(
      Uri.parse('$baseUrl/orders'),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      debugPrint('✅ [ApiService] ${response.statusCode} OK, bytes=${response.contentLength}');
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load orders: ${response.body}');
    }
  }

  // Logout method
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
  }
}
