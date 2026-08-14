import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:prac/AppScreens/CartPage.dart';
import 'package:provider/provider.dart';
import '../../../../models/Product.dart';
import '../../../../Controller/CartProvider.dart';

class ProductDetailScreen extends StatefulWidget {
  final Product product;

  const ProductDetailScreen({Key? key, required this.product}) : super(key: key);

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  String selectedSize = 'M'; // Default selected size
  int quantity = 1; // Default quantity

  @override
  Widget build(BuildContext context) {
    // Get the first image URL or use a placeholder
    final String imageUrl = widget.product.images.isNotEmpty 
        ? widget.product.images[0] 
        : 'assets/images/logo.png';
    
    // Dummy review data
    const double averageRating = 4.5;
    const int reviewCount = 24;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.product.name),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const CartPage()),
                  );
                },
              ),
              Positioned(
                right: 8,
                top: 8,
                child: Consumer<CartProvider>(
                  builder: (context, cart, _) {
                    final itemCount = cart.cart.length;
                    return itemCount > 0
                        ? Container(
                            padding: const EdgeInsets.all(2),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 16,
                              minHeight: 16,
                            ),
                            child: Text(
                              itemCount.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          )
                        : const SizedBox.shrink();
                  },
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Product Image
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AspectRatio(
                    aspectRatio: 1,
                    child: Image.asset(
                      imageUrl,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      errorBuilder: (context, error, stackTrace) => 
                          Image.asset('assets/placeholder.png', fit: BoxFit.cover),
                    ),
                  ),
                  // Product Details
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Price Section
                        Text(
                          'PKR ${widget.product.price.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF6A1B9A),
                          ),
                        ),
                        const SizedBox(height: 8),
                        
                        // Category Tag
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            widget.product.category?.toUpperCase() ?? 'ACCESSORIES',
                            style: const TextStyle(
                              fontSize: 12,
                              color:Color.fromARGB(255, 28, 26, 26),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Description Section
                        const Text(
                          'Description',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.product.description ?? 'No description available',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[700],
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 24),
                        
                        // Rating Section
                        Row(
                          children: [
                            RatingBar.builder(
                              initialRating: averageRating,
                              minRating: 1,
                              direction: Axis.horizontal,
                              allowHalfRating: true,
                              itemCount: 5,
                              itemSize: 24,
                              itemBuilder: (context, _) => const Icon(
                                Icons.star,
                                color: Colors.amber,
                              ),
                              onRatingUpdate: (rating) {
                                // Handle rating update
                              },
                              ignoreGestures: true,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '$averageRating ($reviewCount reviews)',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
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
                        Row(
                          children: ['S', 'M', 'L', 'XL'].map((size) {
                            return Padding(
                              padding: const EdgeInsets.only(right: 12.0),
                              child: ChoiceChip(
                                label: Text(size),
                                selected: selectedSize == size,
                                onSelected: (bool selected) {
                                  // Handle size selection
                                },
                                selectedColor: const Color(0xFF6A1B9A),
                                labelStyle: TextStyle(
                                  color: selectedSize == size ? Colors.white : Colors.black,
                                ),
                                backgroundColor: Colors.grey[200],
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 24),
                        
                        // Quantity Selector
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Quantity',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.remove_circle_outline),
                                  onPressed: () {
                                    // Handle decrease quantity
                                  },
                                ),
                                Text(
                                  quantity.toString(),
                                  style: const TextStyle(fontSize: 18),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.add_circle_outline),
                                  onPressed: () {
                                    // Handle increase quantity
                                  },
                                ),
                              ],
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
          // Bottom Bar with Add to Cart Button
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withValues(alpha: 0.3),
                  spreadRadius: 1,
                  blurRadius: 5,
                  offset: const Offset(0, -3),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Total Price',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                    Text(
                      'PKR ${(widget.product.price * quantity).toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF6A1B9A),
                      ),
                    ),
                  ],
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 16.0),
                    child: ElevatedButton(
                      onPressed: () {
                        // Handle add to cart
                        // Get the exact image URL from the product
                        String imageUrl = '';
                        if (widget.product.images.isNotEmpty) {
                          // Use the first image exactly as it appears in the product
                          imageUrl = widget.product.images.first;
                          debugPrint('Adding to cart - Product ID: ${widget.product.id}');
                          debugPrint('  - Image path: $imageUrl');
                        }
                        
                        // Add the product to cart with all necessary details
                        Provider.of<CartProvider>(
                          context,
                          listen: false,
                        ).addProduct({
                          'id': widget.product.id,
                          'title': widget.product.name,
                          'price': widget.product.price,
                          'imageUrl': imageUrl,  // Pass the exact image path
                          'image': imageUrl,     // Add as 'image' for backward compatibility
                          'size': selectedSize,
                          'quantity': quantity,
                        });
                        
                        debugPrint('Product added to cart with image: $imageUrl');
                        
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Added to cart!'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6A1B9A),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Add to Cart',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}