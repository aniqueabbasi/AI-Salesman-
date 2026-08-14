import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../models/Product.dart';
import '../../CartPage.dart';
import '../../../../Controller/CartProvider.dart';
import 'ProductDetailScreen.dart';
import '../../../../utils/cart_utils.dart';

class KidsClothingScreen extends StatelessWidget {
  const KidsClothingScreen({super.key});
  // Sample product data

  void _addToCart(BuildContext context, Product product) {
    CartUtils.addToCart(context, product);
  }

  @override
  Widget build(BuildContext context) {
    final List<Product> dummyProducts = [
      Product(
        id: 'kid1',
        name: 'Kids Tshirt set',
        price: 2999.99,
        description: 'Lightweight and comfortable summer T shirt for kids',
        category: 'Kids-clothing',
        images: ['assets/images/k1.jpeg'],
        sizes: ['S', 'M', 'L', 'XL'],
        colors: ['Red', 'Blue', 'Yellow'],
      ),
      Product(
        id: 'kid2',
        name: 'Denim Jacket',
        price: 1290.99,
        description: 'Denim Jacket for kids',
        category: 'Kids-clothing',
        images: ['assets/images/k2.jpeg'],
        sizes: ['S', 'M', 'L'],
        colors: ['Black', 'Navy', 'Red'],
      ),
      Product(
        id: 'kid3',
        name: 'Floral Dress',
        price: 3900.99,
        description: 'Floral Dress for kids',
        category: 'Kids-clothing',
        images: ['assets/images/k3.jpeg'],
        sizes: ['XS', 'S', 'M', 'L'],
        colors: ['White', 'Black', 'Grey'],
      ),
      Product(
        id: 'kid4',
        name: 'track suit',
        price: 3000.99,
        description: 'Track suit for kids',
        category: 'Kids-clothing',
        images: ['assets/images/k4.jpeg'],
        sizes: ['S', 'M', 'L', 'XL'],
        colors: ['Beige', 'Black', 'Navy'],
      ),
      Product(
        id: 'kid5',
        name: 'Party wear',
        price: 1500.99,
        description: 'Party wear for kids',
        category: 'Kids-clothing',
        images: ['assets/images/k5.jpg'],
        sizes: ['XS', 'S', 'M'],
        colors: ['Black', 'Grey', 'Navy'],
      ),
      Product(
        id: 'kid6',
        name: 'winter dress',
        price: 3400.99,
        description: 'winter dress for kids',
        category: 'Kids-clothing',
        images: ['assets/images/k6.jpg'],
        sizes: ['S', 'M', 'L'],
        colors: ['Black', 'Grey', 'Blue'],
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Kids Clothing"),
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
      body: GridView.builder(
        padding: const EdgeInsets.all(8.0),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.6,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          mainAxisExtent: 280,
        ),
        itemCount: dummyProducts.length,
        itemBuilder: (context, index) {
          final product = dummyProducts[index];
          return Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProductDetailScreen(product: product),
                  ),
                );
              },
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12.0),
                  color: Colors.white,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Product Image
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(12.0)),
                      child: GestureDetector(
                        onTap: () {
                          // Navigate to product detail page instead of cart
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ProductDetailScreen(product: product),
                            ),
                          );
                        },
                        child: AspectRatio(
                          aspectRatio: 1,
                          child: Image.asset(
                            product.images.isNotEmpty ? product.images[0] : 'assets/images/logo.png',
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => 
                                Image.asset('assets/images/logo.png', fit: BoxFit.cover),
                          ),
                        ),
                      ),
                    ),
                    // Product Details
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8.0,
                        vertical: 8.0,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Product name
                          Text(
                            product.name,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.black87,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          // Price and Add to Cart button row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Price - Wrapped in Flexible to prevent overflow
                              Flexible(
                                child: Text(
                                  '₨${(product.price * 30).toStringAsFixed(0)}',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFFFFA500),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              // Add to Cart button - Wrapped in Flexible
                              Flexible(
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: ElevatedButton.icon(
                                    onPressed: () {
                                      _addToCart(context, product);
                                      // Show a quick visual feedback
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('${product.name} added to cart!'),
                                          duration: const Duration(seconds: 1),
                                          behavior: SnackBarBehavior.floating,
                                          margin: const EdgeInsets.all(10),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                        ),
                                      );
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF6A1B9A),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      minimumSize: Size.zero,
                                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(18),
                                      ),
                                      elevation: 0,
                                    ),
                                    icon: const Icon(Icons.shopping_cart, size: 16),
                                    label: const Text(
                                      'Add',
                                      style: TextStyle(fontSize: 10),
                                    ),
                                  ),
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
          );
        },
      ),
    );
  }
}
