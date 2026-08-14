import 'dart:math';

class Product {
  final String id;
  final String name;
  final String? description;
  final double price;
  final double? originalPrice;
  final List<String> images;
  final String? category;
  final bool isNew;
  final int discount;
  final Map<String, dynamic>? details;
  final List<String>? sizes;
  final List<String>? colors;
  /// Units available. Supplied by the backend; null for bundled dummy data.
  final int? stock;
  /// Set on listings created by a seller account.
  final String? sellerId;
  final String? shopName;

  Product({
    required this.id,
    required this.name,
    this.description,
    required this.price,
    this.originalPrice,
    required this.images,
    this.category,
    this.isNew = false,
    this.discount = 0,
    this.details,
    this.sizes,
    this.colors,
    this.stock,
    this.sellerId,
    this.shopName,
  });

  // Factory method to create a Product from a map (JSON)
  factory Product.fromJson(Map<String, dynamic> json) {
    double parsePrice(dynamic value) {
      if (value == null) return 0.0;
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }
    double price = parsePrice(json['price'] ?? json['selling_price'] ?? json['actual_price']);
    if (price == 0.0) {
      price = (1000 + Random().nextInt(4001)).toDouble();
    }
    // Handle images as a list or as a single image_url/imageUrl
    List<String> images = [];
    if (json['images'] != null && json['images'] is List) {
      images = List<String>.from(json['images']);
    }
    // Add fallback for single image fields if images is empty
    if (images.isEmpty) {
      if (json['image_url'] != null && json['image_url'] is String) {
        images = [json['image_url']];
      } else if (json['imageUrl'] != null && json['imageUrl'] is String) {
        images = [json['imageUrl']];
      } else if (json['image'] != null && json['image'] is String) {
        images = [json['image']];
      }
    }
    return Product(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'],
      price: price,
      originalPrice: (json['originalPrice'] as num?)?.toDouble(),
      images: images,
      category: json['category'],
      isNew: json['isNew'] ?? false,
      discount: json['discount'] ?? 0,
      details: json['details'],
      sizes: json['sizes'] != null ? List<String>.from(json['sizes']) : null,
      colors: json['colors'] != null ? List<String>.from(json['colors']) : null,
      stock: (json['stock'] as num?)?.toInt(),
      sellerId: json['seller_id']?.toString(),
      shopName: json['shop_name']?.toString(),
    );
  }

  get imageUrl => null;

  // Method to convert Product to a map (JSON)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'originalPrice': originalPrice,
      'images': images,
      'category': category,
      'isNew': isNew,
      'discount': discount,
      'details': details,
      'sizes': sizes,
      'colors': colors,
      'stock': stock,
      'seller_id': sellerId,
      'shop_name': shopName,
    };
  }
} 