import 'package:shared_preferences/shared_preferences.dart';

/// The kind of account that is signed in.
enum UserRole { customer, seller }

class AuthService {
  static const String _tokenKey = 'auth_token';
  static const String _roleKey = 'user_role';
  static const String _emailKey = 'user_email';
  static const String _shopNameKey = 'shop_name';

  // Check if user is logged in
  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey) != null;
  }

  // Get auth token
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  // Save auth token
  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    // ApiService reads this key when building Authorization headers.
    await prefs.setString('token', token);
  }

  /// Persist who signed in, so the app can route to the right home screen on
  /// launch without asking the server again.
  static Future<void> saveSession({
    required String token,
    required String role,
    String? email,
    String? shopName,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    await prefs.setString('token', token);
    await prefs.setString(_roleKey, role);
    if (email != null) await prefs.setString(_emailKey, email);
    if (shopName != null) await prefs.setString(_shopNameKey, shopName);
  }

  static Future<UserRole> getRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_roleKey) == 'seller'
        ? UserRole.seller
        : UserRole.customer;
  }

  static Future<bool> isSeller() async => (await getRole()) == UserRole.seller;

  static Future<String?> getEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_emailKey);
  }

  static Future<String?> getShopName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_shopNameKey);
  }

  // Clear auth token (logout)
  static Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove('token');
    await prefs.remove(_roleKey);
    await prefs.remove(_emailKey);
    await prefs.remove(_shopNameKey);
    await prefs.remove('user_id');
  }
}
