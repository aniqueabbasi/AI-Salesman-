import 'package:flutter/material.dart';

import '../../../../models/Product.dart';
import '../../../../res/app_theme.dart';
import '../../../../res/ui_kit.dart';
import '../../../../widgets/cart_count_button.dart';
import '../../../../widgets/product_card.dart';

class KidsClothingScreen extends StatelessWidget {
  const KidsClothingScreen({super.key});

  /// Prices are held in rupees. They were already rupee figures but were
  /// scaled by 30 at render time, so this screen showed ₨90,000 for a kids'
  /// t-shirt while the cart recorded ₨3,000.
  static final List<Product> _products = [
    Product(
      id: 'kid1',
      name: 'Kids Tshirt set',
      price: 2999,
      description: 'Lightweight and comfortable summer T shirt for kids',
      category: 'Kids-clothing',
      images: ['assets/images/k1.jpeg'],
      sizes: ['S', 'M', 'L', 'XL'],
      colors: ['Red', 'Blue', 'Yellow'],
    ),
    Product(
      id: 'kid2',
      name: 'Denim Jacket',
      price: 1290,
      description: 'Denim Jacket for kids',
      category: 'Kids-clothing',
      images: ['assets/images/k2.jpeg'],
      sizes: ['S', 'M', 'L'],
      colors: ['Black', 'Navy', 'Red'],
    ),
    Product(
      id: 'kid3',
      name: 'Floral Dress',
      price: 3900,
      description: 'Floral Dress for kids',
      category: 'Kids-clothing',
      images: ['assets/images/k3.jpeg'],
      sizes: ['XS', 'S', 'M', 'L'],
      colors: ['White', 'Black', 'Grey'],
    ),
    Product(
      id: 'kid4',
      name: 'track suit',
      price: 3000,
      description: 'Track suit for kids',
      category: 'Kids-clothing',
      images: ['assets/images/k4.jpeg'],
      sizes: ['S', 'M', 'L', 'XL'],
      colors: ['Beige', 'Black', 'Navy'],
    ),
    Product(
      id: 'kid5',
      name: 'Party wear',
      price: 1500,
      description: 'Party wear for kids',
      category: 'Kids-clothing',
      images: ['assets/images/k5.jpg'],
      sizes: ['XS', 'S', 'M'],
      colors: ['Black', 'Grey', 'Navy'],
    ),
    Product(
      id: 'kid6',
      name: 'winter dress',
      price: 3400,
      description: 'winter dress for kids',
      category: 'Kids-clothing',
      images: ['assets/images/k6.jpg'],
      sizes: ['S', 'M', 'L'],
      colors: ['Black', 'Grey', 'Blue'],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            const ScreenHeader(
              'Kids Clothing',
              trailing: CartCountButton(),
            ),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.fromLTRB(22, 16, 22, 28),
                physics: const BouncingScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.66,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: _products.length,
                itemBuilder: (context, index) =>
                    ProductCard(product: _products[index]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
