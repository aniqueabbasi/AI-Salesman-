import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../Controller/CartProvider.dart';
import '../AppScreens/CartPage.dart';
import '../res/app_theme.dart';

/// A reusable shopping-cart icon that shows a red badge with the
/// current cart item count. Call inside an [AppBar] `actions` list.
class CartBadgeIcon extends StatelessWidget {
  final Color iconColor;
  const CartBadgeIcon({Key? key, this.iconColor = AppTheme.accentPink}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<CartProvider>(
      builder: (_, cartProv, __) {
        // Count total quantity (not just distinct items)
        int itemCount = 0;
        for (var item in cartProv.cart) {
          final qty = (item['quantity'] is int) ? item['quantity'] as int : 1;
          itemCount += qty;
        }

        return Stack(
          alignment: Alignment.center,
          children: [
            IconButton(
              icon: Icon(Icons.shopping_cart, size: 28, color: iconColor),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const CartPage()),
                );
              },
            ),
            if (itemCount > 0)
              Positioned(
                right: 6,
                top: 6,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                  child: Text(
                    itemCount.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
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
