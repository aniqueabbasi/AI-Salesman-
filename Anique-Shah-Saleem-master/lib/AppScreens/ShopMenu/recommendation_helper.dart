import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:prac/models/Product.dart';
import 'package:prac/AppScreens/ShopMenu/dummy_products.dart';
import '../../config/api_config.dart';

Future<List<Product>> getRecommendedProducts(Product product) async {
  // Try API first
  try {
    final attributes = [
      if (product.category != null && product.category!.isNotEmpty)
        {'attribute_type': 'category', 'attribute_value': product.category},
    ];
    final url = Uri.parse('${ApiConfig.recommendationBaseUrl}/api/recommend');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'attributes': attributes,
        'min_confidence': 0.5,
        'min_lift': 1.0,
        'max_results': 10,
        'include_products': true,
      }),
    );
    if (response.statusCode == 200) {
      final recs = jsonDecode(response.body)['recommendations'];
      List<Product> extractedProducts = [];
      for (var rec in recs) {
        if (rec['matching_products'] != null) {
          for (var prodJson in rec['matching_products']) {
            if (prodJson['id'] != product.id) {
              extractedProducts.add(Product.fromJson(prodJson));
              if (extractedProducts.length >= 10) break;
            }
          }
        }
        if (extractedProducts.length >= 10) break;
      }
      if (extractedProducts.isNotEmpty) return extractedProducts;
    }
  } catch (e) {
    // Ignore API errors, fallback to dummy
  }
  // Fallback to dummy data
  final cat = (product.category ?? '').toLowerCase();
  List<Product> dummyList = [];
  if (cat.contains('shirt')) dummyList = dummyShirts;
  if (cat.contains('jean')) dummyList = dummyJeans;
  if (cat.contains('shoe')) dummyList = dummyShoes;
  if (cat.contains('jacket')) dummyList = dummyJackets;
  return dummyList.where((p) => p.id != product.id).take(10).toList();
} 