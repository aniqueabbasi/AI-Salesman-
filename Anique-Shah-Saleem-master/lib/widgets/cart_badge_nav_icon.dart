import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../Controller/CartProvider.dart';

/// Compact shopping cart icon with quantity badge for use inside
/// BottomNavigationBar items.
class CartBadgeNavIcon extends StatelessWidget {
  const CartBadgeNavIcon({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<CartProvider>(
      builder: (_, cartProv, __) {
        int itemCount = 0;
        for (var item in cartProv.cart) {
          final qty = (item['quantity'] is int) ? item['quantity'] as int : 1;
          itemCount += qty;
        }
        final Color? color = IconTheme.of(context).color;
        return Stack(
          alignment: Alignment.center,
          children: [
            Icon(Icons.shopping_cart, size: 24, color: color),
            if (itemCount > 0)
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  padding: const EdgeInsets.all(1.5),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(minWidth: 12, minHeight: 12),
                  child: Text(
                    itemCount.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
