import 'package:flutter/material.dart';

import '../../../../models/Product.dart';
import '../../../../res/app_theme.dart';
import '../../../../res/ui_kit.dart';
import '../../../../widgets/cart_count_button.dart';
import '../../../../widgets/product_card.dart';

class WomensClothingScreen extends StatelessWidget {
  const WomensClothingScreen({super.key});

  /// Prices are held in rupees. They were previously a mix of rupee and
  /// dollar figures scaled by 30 at render time, which showed the one already
  /// in rupees as ₨150,000 and recorded a different number in the cart.
  static final List<Product> _products = [
    Product(
      id: 'wc1',
      name: 'Floral Summer Dress',
      price: 4999,
      description: 'Lightweight and comfortable summer dress with floral print',
      category: 'womens-clothing',
      images: ['assets/images/w1.jpg'],
      sizes: ['S', 'M', 'L', 'XL'],
      colors: ['Red', 'Blue', 'Yellow'],
    ),
    Product(
      id: 'wc2',
      name: 'Elegant Evening Gown',
      price: 3899,
      description: 'Stunning evening gown with sequin details',
      category: 'womens-clothing',
      images: ['assets/images/w2.jpeg'],
      sizes: ['S', 'M', 'L'],
      colors: ['Black', 'Navy', 'Red'],
    ),
    Product(
      id: 'wc3',
      name: 'Casual T-Shirt & Jeans',
      price: 1199,
      description: 'Comfortable everyday outfit',
      category: 'womens-clothing',
      images: ['assets/images/w3.jpeg'],
      sizes: ['XS', 'S', 'M', 'L'],
      colors: ['White', 'Black', 'Grey'],
    ),
    Product(
      id: 'wc4',
      name: 'Winter Coat',
      price: 2699,
      description: 'Warm and stylish winter coat',
      category: 'womens-clothing',
      images: ['assets/images/coat.jpg'],
      sizes: ['S', 'M', 'L', 'XL'],
      colors: ['Beige', 'Black', 'Navy'],
    ),
    Product(
      id: 'wc5',
      name: 'Office Blazer',
      price: 2099,
      description: 'Professional blazer for office wear',
      category: 'womens-clothing',
      images: ['assets/images/blazer.jpg'],
      sizes: ['XS', 'S', 'M'],
      colors: ['Black', 'Grey', 'Navy'],
    ),
    Product(
      id: 'wc6',
      name: 'Black Eastren dress',
      price: 1049,
      description: 'Black Eastren dress',
      category: 'womens-clothing',
      images: ['assets/images/eastren.jpeg'],
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
              "Women's Clothing",
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
