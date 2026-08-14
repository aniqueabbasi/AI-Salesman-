class Product {
  final String id;
  final String name;
  final String description;
  final double price;
  final int stock;
  final String category;
  final String createdAt;
  final String updatedAt;
  final String? imageUrl;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.stock,
    required this.category,
    required this.createdAt,
    required this.updatedAt,
    this.imageUrl,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      price: json['price'].toDouble(),
      stock: json['stock'],
      category: json['category'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
      imageUrl: json['image_url'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'stock': stock,
      'category': category,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'image_url': imageUrl,
    };
  }
  
  // Create a copy of this Product with optional field updates
  Product copyWith({
    String? id,
    String? name,
    String? description,
    double? price,
    int? stock,
    String? category,
    String? createdAt,
    String? updatedAt,
    String? imageUrl,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      stock: stock ?? this.stock,
      category: category ?? this.category,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }
}
