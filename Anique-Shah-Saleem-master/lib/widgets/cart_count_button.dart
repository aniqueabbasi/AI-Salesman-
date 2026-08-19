import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../AppScreens/CartPage.dart';
import '../Controller/CartProvider.dart';
import '../res/app_theme.dart';

/// Circular ink cart control used in screen headers. Shows the live item
/// count, or a bag icon while the cart is empty.
class CartCountButton extends StatelessWidget {
  final double size;

  const CartCountButton({super.key, this.size = 38});

  @override
  Widget build(BuildContext context) {
    return Consumer<CartProvider>(
      builder: (context, cart, _) {
        var count = 0;
        for (final item in cart.cart) {
          count += (item['quantity'] is int) ? item['quantity'] as int : 1;
        }
        return GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CartPage()),
          ),
          child: Container(
            width: size,
            height: size,
            decoration: const BoxDecoration(
              color: AppTheme.ink,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: count > 0
                ? Text(
                    '$count',
                    style: AppTheme.ui(14,
                        color: AppTheme.surface,
                        weight: FontWeight.w600,
                        height: 1.0),
                  )
                : Icon(Icons.shopping_bag_outlined,
                    size: size * 0.47, color: AppTheme.surface),
          ),
        );
      },
    );
  }
}
