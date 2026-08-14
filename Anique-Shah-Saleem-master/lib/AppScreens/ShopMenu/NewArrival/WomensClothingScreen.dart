import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../models/Product.dart';
import '../../CartPage.dart';
import '../../../../Controller/CartProvider.dart';
import 'ProductDetailScreen.dart';
import '../../../../utils/cart_utils.dart';

class WomensClothingScreen extends StatelessWidget {
  const WomensClothingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Dummy products for women's clothing
    final List<Product> dummyProducts = [
      Product(
        id: 'wc1',
        name: 'Floral Summer Dress',
        price: 4999.99,
        description: 'Lightweight and comfortable summer dress with floral print',
        category: 'womens-clothing',
        images: ['assets/images/w1.jpg'],
        sizes: ['S', 'M', 'L', 'XL'],
        colors: ['Red', 'Blue', 'Yellow'],
      ),
      Product(
        id: 'wc2',
        name: 'Elegant Evening Gown',
        price: 129.99,
        description: 'Stunning evening gown with sequin details',
        category: 'womens-clothing',
        images: ['assets/images/w2.jpeg'],
        sizes: ['S', 'M', 'L'],
        colors: ['Black', 'Navy', 'Red'],
      ),
      Product(
        id: 'wc3',
        name: 'Casual T-Shirt & Jeans',
        price: 39.99,
        description: 'Comfortable everyday outfit',
        category: 'womens-clothing',
        images: ['assets/images/w3.jpeg'],
        sizes: ['XS', 'S', 'M', 'L'],
        colors: ['White', 'Black', 'Grey'],
      ),
      Product(
        id: 'wc4',
        name: 'Winter Coat',
        price: 89.99,
        description: 'Warm and stylish winter coat',
        category: 'womens-clothing',
        images: ['assets/images/coat.jpg'],
        sizes: ['S', 'M', 'L', 'XL'],
        colors: ['Beige', 'Black', 'Navy'],
      ),
      Product(
        id: 'wc5',
        name: 'Office Blazer',
        price: 69.99,
        description: 'Professional blazer for office wear',
        category: 'womens-clothing',
        images: ['assets/images/blazer.jpg'],
        sizes: ['XS', 'S', 'M'],
        colors: ['Black', 'Grey', 'Navy'],
      ),
      Product(
        id: 'wc6',
        name: 'Black Eastren dress',
        price: 34.99,
        description: 'Black Eastren dress',
        category: 'womens-clothing',
        images: ['assets/images/eastren.jpeg'],
        sizes: ['S', 'M', 'L'],
        colors: ['Black', 'Grey', 'Blue'],
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Women's Clothing"),
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
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: Image.asset(
                          product.images[0],
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => 
                              Image.asset('assets/images/logo.png', fit: BoxFit.cover),
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
                                      CartUtils.addToCart(context, product);
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
