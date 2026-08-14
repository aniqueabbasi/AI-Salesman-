import 'package:flutter/material.dart';
import 'package:prac/AppScreens/CartPage.dart';
import 'package:provider/provider.dart';
import 'package:prac/Controller/CartProvider.dart';
import 'package:prac/models/Product.dart';
import 'package:prac/res/app_theme.dart';
import 'package:prac/services/api_service.dart';
import 'package:prac/widgets/cart_badge_icon.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:prac/Authentication/Login.dart';

class ProductDetailPage extends StatefulWidget {
  final Product product;
  final String? heroTag;
  final String? assetImage;

  const ProductDetailPage({super.key, required this.product, this.heroTag, this.assetImage});

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  var selectedSize = '';
  int quantity = 1;
  double userRating = 0; // Holds user-selected rating
  List<String> sizes = ['S', 'M', 'L', 'XL', 'XXL']; // Default sizes
  
  // Recommendation state
  List<Product> recommendedProducts = [];
  bool isLoadingRecommendations = false;
  String recommendationsError = '';

  @override
  void initState() {
    super.initState();
    // Set appropriate sizes based on product category
    if (widget.product.sizes != null && widget.product.sizes!.isNotEmpty) {
      sizes = widget.product.sizes!;
    } else if (widget.product.category?.toLowerCase() == 'shoes') {
      sizes = ['7', '8', '9', '10', '11', '12'];
    } else if (widget.product.category?.toLowerCase() == 'jeans') {
      sizes = ['28', '30', '32', '34', '36', '38'];
    }
    
    // Initialize selected size
    if (sizes.isNotEmpty) {
      selectedSize = sizes[0];
    }
    // Fetch recommendations
    fetchRecommendations();

    // Initialize user rating based on existing rating if available
    double initialRating = widget.product.details != null && widget.product.details!['rating'] != null
        ? (widget.product.details!['rating'] as num).toDouble()
        : 4.5;
    userRating = initialRating;
  }

  Future<void> fetchRecommendations() async {
    if (widget.product.category == null) return;
    debugPrint('[DEBUG] Fetching recommendations for category: \'${widget.product.category}\'');
    setState(() {
      isLoadingRecommendations = true;
      recommendationsError = '';
    });
    try {
      final recs = await ApiService.getRecommendations(widget.product.category!);
      debugPrint('[DEBUG] Raw recommendations: $recs');
      List<Product> extractedProducts = [];
      for (var rec in recs) {
        if (rec.id != widget.product.id) {
          extractedProducts.add(rec);
          if (extractedProducts.length >= 10) break;
        }
      }
      if (!mounted) return;
      setState(() {
        recommendedProducts = extractedProducts;
        isLoadingRecommendations = false;
      });
    } catch (e) {
      debugPrint('[DEBUG] Failed to load recommendations: $e');
      if (!mounted) return;
      setState(() {
        recommendationsError = 'Failed to load recommendations';
        isLoadingRecommendations = false;
      });
    }
  }

  void _incrementQuantity() {
    setState(() {
      quantity++;
    });
  }

  void _decrementQuantity() {
    setState(() {
      if (quantity > 1) {
        quantity--;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Find the asset image used for this product
    String? assetImage = widget.assetImage;
    String description = '';
    if (assetImage != null) {
      Map<String, String> descMap = {
        'assets/images/jean1.jpg': 'Comfortable and stylish blue jeans for everyday wear.',
        'assets/images/green.jpg': 'Fresh green shirt for a smart casual look.',
        'assets/images/casual.jpg': 'Soft and comfy t-shirt for relaxed days.',
        'assets/images/m2.jpg': 'Trendy jacket to keep you warm and stylish.',
        'assets/images/m3.jpg': 'Perfect hoodie for urban adventures.',
        'assets/images/jean2.jpg': 'Slim fit jeans for a modern look.',
      };
      description = descMap[assetImage] ?? '';
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Product Details',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: const [
          Padding(
            padding: EdgeInsets.all(8.0),
            child: CartBadgeIcon(iconColor: Colors.black),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product Image
              Hero(
                tag: widget.heroTag ?? 'product-${widget.product.id}',
                child: Container(
                  height: 350,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: (() {
                          if (widget.assetImage != null && widget.assetImage!.isNotEmpty) {
                            return AssetImage(widget.assetImage!) as ImageProvider<Object>;
                          }
                          // Use first product image if available
                          if (widget.product.images.isNotEmpty) {
                            final String first = widget.product.images.first;
                            if (first.startsWith('http')) {
                              return NetworkImage(first) as ImageProvider<Object>;
                            } else {
                              return AssetImage(first) as ImageProvider<Object>;
                            }
                          }
                          // Fallback to cycling local demo assets
                          int index = int.tryParse(widget.product.id) ?? widget.product.id.hashCode;
                          List<String> assetImages = [
                            'assets/images/jean1.jpg',
                            'assets/images/green.jpg',
                            'assets/images/casual.jpg',
                            'assets/images/m2.jpg',
                            'assets/images/m3.jpg',
                            'assets/images/jean2.jpg',
                          ];
                          return AssetImage(assetImages[index % assetImages.length]) as ImageProvider<Object>;
                        })(),
                      fit: BoxFit.cover,
                    ),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(30),
                      bottomRight: Radius.circular(30),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 10,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Product Title and Price
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            widget.product.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 24,
                            ),
                          ),
                        ),
                        Text(
                          'PKR ${widget.product.price.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 22,
                            color: AppTheme.accentPink,
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // Category and discount badge
                    Row(
                      children: [
                        if (widget.product.category != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryBlue.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              widget.product.category!.toUpperCase(),
                              style: const TextStyle(color: AppTheme.primaryBlue),
                            ),
                          ),
                        const SizedBox(width: 10),
                        if (widget.product.discount > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color.fromARGB(255, 65, 90, 255).withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${widget.product.discount}% OFF',
                              style: const TextStyle(
                                color: Color.fromARGB(255, 84, 65, 255),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Description
                    const Text(
                      'Description',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      description,
                      style: const TextStyle(fontSize: 15, color: Colors.black87),
                    ),
                    
                    const SizedBox(height: 12),

                    // Rating
                    const Text(
                      'Rating',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Star Rating (interactive)
                    Row(
                      children: [
                        for (int i = 1; i <= 5; i++)
                          IconButton(
                            icon: Icon(
                              i <= userRating.round()
                                  ? Icons.star
                                  : Icons.star_border,
                              color: Colors.amber,
                            ),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            iconSize: 24,
                            onPressed: () {
                              setState(() {
                                userRating = i.toDouble();
                              });
                              // TODO: Persist rating to backend or local storage
                            },
                          ),
                        const SizedBox(width: 6),
                        Text(
                          userRating.toStringAsFixed(1),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    
                    // Size Selection
                    const Text(
                      'Select Size',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 60,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: sizes.length,
                        itemBuilder: (context, index) {
                          final size = sizes[index];
                          final bool isSelected = selectedSize == size;
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                selectedSize = size;
                              });
                            },
                            child: Container(
                              margin: const EdgeInsets.only(right: 10),
                              width: 60,
                              decoration: BoxDecoration(
                                color: isSelected ? AppTheme.primaryPurple : Colors.white,
                                borderRadius: BorderRadius.circular(15),
                                border: Border.all(
                                  color: isSelected ? AppTheme.primaryPurple : Colors.grey.shade300,
                                  width: 2,
                                ),
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color: AppTheme.primaryPurple.withValues(alpha: 0.3),
                                          blurRadius: 8,
                                          spreadRadius: 2,
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Center(
                                child: Text(
                                  size,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: isSelected ? Colors.white : Colors.black,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Quantity Selection
                    const Text(
                      'Quantity',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Row(
                            children: [
                              IconButton(
                                onPressed: _decrementQuantity,
                                icon: const Icon(Icons.remove),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10),
                                child: Text(
                                  quantity.toString(),
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              IconButton(
                                onPressed: _incrementQuantity,
                                icon: const Icon(Icons.add),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Recommended Products Row
                    if (isLoadingRecommendations)
                      const Center(child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: CircularProgressIndicator(),
                      ))
                    else if (recommendationsError.isNotEmpty)
                      Center(child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Text(recommendationsError, style: const TextStyle(color: Colors.red)),
                      ))
                    else if (recommendedProducts.isNotEmpty)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(bottom: 8.0),
                            child: Text(
                              'You may also like',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ),
                          SizedBox(
                            height: 170,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: recommendedProducts.length > 10 ? 10 : recommendedProducts.length,
                              separatorBuilder: (context, i) => const SizedBox(width: 12),
                              itemBuilder: (context, i) {
                                final rec = recommendedProducts[i];
                                return GestureDetector(
                                  onTap: () {
                                    Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => ProductDetailPage(product: rec),
                                      ),
                                    );
                                  },
                                  child: SizedBox(
                                    width: 140,
                                    child: Card(
                                      child: Column(
                                        children: [
                                          ClipRRect(
                                            borderRadius: const BorderRadius.only(
                                              topLeft: Radius.circular(16),
                                              topRight: Radius.circular(16),
                                            ),
                                            child: (() {
                                              String? imageUrl = rec.images.isNotEmpty ? rec.images[0] : null;
                                              if (imageUrl == null || imageUrl.isEmpty) {
                                                return Container(
                                                  height: 80,
                                                  width: 130,
                                                  color: Colors.grey[200],
                                                  child: const Icon(Icons.image, size: 40, color: Colors.grey),
                                                );
                                              } else if (imageUrl.startsWith('http')) {
                                                return Image.network(
                                                  imageUrl,
                                                  height: 80,
                                                  width: 130,
                                                  fit: BoxFit.cover,
                                                  loadingBuilder: (context, child, progress) =>
                                                      progress == null ? child : const Center(child: CircularProgressIndicator()),
                                                  errorBuilder: (context, error, stackTrace) => Container(
                                                    height: 80,
                                                    width: 130,
                                                    color: Colors.grey[200],
                                                    child: const Icon(Icons.broken_image, size: 40, color: Colors.grey),
                                                  ),
                                                );
                                              } else {
                                                return Image.asset(
                                                  imageUrl,
                                                  height: 80,
                                                  width: 130,
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (context, error, stackTrace) => Container(
                                                    height: 80,
                                                    width: 130,
                                                    color: Colors.grey[200],
                                                    child: const Icon(Icons.broken_image, size: 40, color: Colors.grey),
                                                  ),
                                                );
                                              }
                                            })(),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  rec.name,
                                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                                Text(
                                                  'PKR ${rec.price}',
                                                  style: const TextStyle(color: Color.fromARGB(255, 81, 41, 243)),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              spreadRadius: 0,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Row(
          children: [
            // Total price
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Total Price',
                    style: TextStyle(
                      color: Colors.grey,
                    ),
                  ),
                  Text(
                    'PKR ${(widget.product.price * quantity).toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                      color: Color.fromARGB(255, 65, 71, 255),
                    ),
                  ),
                ],
              ),
            ),
            // Add to cart button
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  gradient: AppTheme.accentGradient,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: const Color.fromARGB(255, 75, 65, 255).withValues(alpha: 0.3),
                      blurRadius: 8,
                      spreadRadius: 2,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: () async {
                    // Resolve everything that needs a BuildContext up front, so
                    // nothing reads `context` after an await.
                    final navigator = Navigator.of(context);
                    final messenger = ScaffoldMessenger.of(context);
                    final cartProvider =
                        Provider.of<CartProvider>(context, listen: false);

                    final prefs = await SharedPreferences.getInstance();
                    final token = prefs.getString('token');
                    debugPrint('Token at add to cart: $token'); // Debug print

                    if (token == null) {
                      // Show login screen and wait for result
                      final loggedIn = await navigator.push(
                        MaterialPageRoute(builder: (_) => const Login()),
                      );
                      debugPrint('Returned from login: $loggedIn'); // Debug print
                      if (loggedIn != true) return; // Only continue if login was successful
                    }

                    // User is logged in, proceed to add to cart
                    if (selectedSize.isEmpty) {
                      messenger.showSnackBar(
                        const SnackBar(content: Text('Please select a size')),
                      );
                      return;
                    }

                    // Convert Product to a cart item with the selected quantity
                    final images = widget.product.images;
                    String imageUrl = '';
                    
                    // Handle the image URL
                    if (images.isNotEmpty) {
                      String firstImage = images.first.trim();
                      if (firstImage.startsWith('http')) {
                        imageUrl = firstImage;
                      } else if (firstImage.startsWith('assets/')) {
                        imageUrl = firstImage;
                      } else if (firstImage.isNotEmpty) {
                        firstImage = firstImage.replaceAll('\\', '/');
                        if (firstImage.startsWith('images/')) {
                          imageUrl = 'assets/$firstImage';
                        } else if (!firstImage.startsWith('assets/')) {
                          imageUrl = 'assets/images/$firstImage';
                          if (firstImage.contains('/')) {
                            final filename = firstImage.split('/').last;
                            imageUrl = 'assets/images/$filename';
                          }
                        }
                      }
                    }
                    
                    // Create cart item with the correct quantity
                    Map<String, dynamic> cartItem = {
                      'id': widget.product.id,
                      'name': widget.product.name,
                      'price': widget.product.price,
                      'image': imageUrl.isNotEmpty ? imageUrl : 'assets/images/placeholder.jpg',
                      'category': widget.product.category ?? '',
                      'quantity': quantity, // Set the quantity here
                      'size': selectedSize.isNotEmpty ? selectedSize : 
                          (widget.product.sizes?.isNotEmpty == true ? widget.product.sizes!.first : 'Default'),
                    };
                    
                    // Add to cart
                    cartProvider.addProduct(cartItem);
                    
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text('${widget.product.name} added to cart'),
                        action: SnackBarAction(
                          label: 'VIEW CART',
                          textColor: Colors.white,
                          onPressed: () {
                            navigator.push(
                              MaterialPageRoute(builder: (_) => const CartPage()),
                            );
                          },
                        ),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 79, 70, 248),
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.shopping_cart, color: Colors.white),
                      SizedBox(width: 8),
                      Text(
                        'Add to Cart',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 