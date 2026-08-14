import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../models/Product.dart';
import '../../CartPage.dart';
import '../../../../Controller/CartProvider.dart';
import 'ProductDetailScreen.dart';
import '../../../../utils/cart_utils.dart';

class AccessoriesScreen extends StatelessWidget {
  const AccessoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Dummy products for accessories
    final List<Product> dummyAccessories = [
      Product(
        id: 'acc1',
        name: 'Classic Watch - Black',
        price: 89.99,
        description: 'Elegant wristwatch with leather strap',
        category: 'accessories',
        images: ['assets/images/watch1.jpg'],
        sizes: ['One Size'],
      ),
      Product(
        id: 'acc2',
        name: 'Classic Watch - Brown',
        price: 99.99,
        description: 'Premium watch with genuine leather strap',
        category: 'accessories',
        images: ['assets/images/watch2.jpg'],
        sizes: ['One Size'],
      ),
      Product(
        id: 'acc3',
        name: 'Luxury Watch',
        price: 129.99,
        description: 'Premium watch with stainless steel band',
        category: 'accessories',
        images: ['assets/images/watch1.jpg'],
        sizes: ['One Size'],
      ),
      Product(
        id: '4',
        name: 'Classic Watch - Brown',
        price: 99.99,
        description: 'Premium watch with genuine leather strap',
        category: 'accessories',
        images: ['assets/images/watch2.jpg'],
        sizes: ['One Size'],
      ),
      Product(
        id: '5',
        name: 'Classic Watch - Brown',
        price: 99.99,
        description: 'Premium watch with genuine leather strap',
        category: 'accessories',
        images: ['assets/images/watch2.jpg'],
        sizes: ['One Size'],
      ),
      Product(
        id: '6',
        name: 'Classic Watch - Brown',
        price: 99.99,
        description: 'Premium watch with genuine leather strap',
        category: 'accessories',
        images: ['assets/images/watch2.jpg'],
        sizes: ['One Size'],
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Accessories'),
        actions: [
          // Cart icon with badge
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
              // Cart badge
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
          childAspectRatio: 0.6, // Slightly narrower cards for better fit
          crossAxisSpacing: 12,  // Slightly less spacing between cards
          mainAxisSpacing: 12,
          mainAxisExtent: 280,   // Slightly reduced height
        ),
        itemCount: dummyAccessories.length,
        itemBuilder: (context, index) {
          final product = dummyAccessories[index];
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
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: Image.asset(
                        product.images[0],
                        fit: BoxFit.cover,
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
                                '₨${(product.price * 30).toStringAsFixed(0)}', // Convert to PKR (assuming 1 USD = 300 PKR)
                                style: const TextStyle(
                                  fontSize: 14, // Slightly smaller font
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFFFA500), // Orange color
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
                                    CartUtils.addToCart(context, product);
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF6A1B9A), // Purple color
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8, // Reduced horizontal padding
                                      vertical: 4,  // Reduced vertical padding
                                    ),
                                    minimumSize: Size.zero, // Remove minimum size constraints
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(18), // Slightly smaller radius
                                    ),
                                    elevation: 0,
                                  ),
                                  icon: const Icon(Icons.shopping_cart, size: 16), // Smaller icon
                                  label: const Text(
                                    'Add', // Shorter label
                                    style: TextStyle(fontSize: 10), // Smaller font
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
            )
          );
        },
      ),
    );
  }
}
