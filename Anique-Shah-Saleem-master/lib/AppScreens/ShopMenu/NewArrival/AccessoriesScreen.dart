import 'package:flutter/material.dart';

import '../../../../models/Product.dart';
import '../../../../res/app_theme.dart';
import '../../../../res/ui_kit.dart';
import '../../../../widgets/cart_count_button.dart';
import '../../../../widgets/product_card.dart';

class AccessoriesScreen extends StatelessWidget {
  const AccessoriesScreen({super.key});

  /// Prices are held in rupees. They used to be stored USD-style and scaled by
  /// 30 at render time, which meant the cart recorded the unscaled figure.
  static final List<Product> _accessories = [
    Product(
      id: 'acc1',
      name: 'Classic Watch - Black',
      price: 2699,
      description: 'Elegant wristwatch with leather strap',
      category: 'accessories',
      images: ['assets/images/watch1.jpg'],
      sizes: ['One Size'],
    ),
    Product(
      id: 'acc2',
      name: 'Classic Watch - Brown',
      price: 2999,
      description: 'Premium watch with genuine leather strap',
      category: 'accessories',
      images: ['assets/images/watch2.jpg'],
      sizes: ['One Size'],
    ),
    Product(
      id: 'acc3',
      name: 'Luxury Watch',
      price: 3899,
      description: 'Premium watch with stainless steel band',
      category: 'accessories',
      images: ['assets/images/watch1.jpg'],
      sizes: ['One Size'],
    ),
    Product(
      id: '4',
      name: 'Classic Watch - Brown',
      price: 2999,
      description: 'Premium watch with genuine leather strap',
      category: 'accessories',
      images: ['assets/images/watch2.jpg'],
      sizes: ['One Size'],
    ),
    Product(
      id: '5',
      name: 'Classic Watch - Brown',
      price: 2999,
      description: 'Premium watch with genuine leather strap',
      category: 'accessories',
      images: ['assets/images/watch2.jpg'],
      sizes: ['One Size'],
    ),
    Product(
      id: '6',
      name: 'Classic Watch - Brown',
      price: 2999,
      description: 'Premium watch with genuine leather strap',
      category: 'accessories',
      images: ['assets/images/watch2.jpg'],
      sizes: ['One Size'],
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
              'Accessories',
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
                itemCount: _accessories.length,
                itemBuilder: (context, index) =>
                    ProductCard(product: _accessories[index]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
