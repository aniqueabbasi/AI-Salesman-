import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../AppScreens/ProductDetailPage.dart';
import '../Controller/CartProvider.dart';
import '../models/Product.dart';
import '../res/app_theme.dart';
import '../res/ui_kit.dart';

/// Catalogue tile. Renders vertically inside grids and horizontally inside
/// lists; both share one image source, one cart action and one visual style.
class ProductCard extends StatelessWidget {
  final Product product;
  final bool isHorizontal;

  /// Retained for call-site compatibility. The card already prefers the
  /// product's own artwork whenever it has any, so this no longer changes
  /// anything.
  final bool useProductData;

  const ProductCard({
    Key? key,
    required this.product,
    this.isHorizontal = false,
    this.useProductData = false,
  }) : super(key: key);

  /// Bundled artwork used when a product carries no image of its own. Picked
  /// by id so a given product always gets the same stand-in.
  static const List<String> _assetFallbacks = [
    'assets/images/jean1.jpg',
    'assets/images/green.jpg',
    'assets/images/casual.jpg',
    'assets/images/m2.jpg',
    'assets/images/m3.jpg',
    'assets/images/jean2.jpg',
  ];

  String get _fallbackAsset {
    final index = int.tryParse(product.id) ?? product.id.hashCode;
    return _assetFallbacks[index.abs() % _assetFallbacks.length];
  }

  /// The product's own artwork when present, otherwise its bundled stand-in.
  String get _imageSource {
    final own =
        product.images.isNotEmpty ? product.images.first.trim() : '';
    return own.isNotEmpty ? own : _fallbackAsset;
  }

  void _navigateToDetail(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            ProductDetailPage(product: product, assetImage: _fallbackAsset),
      ),
    );
  }

  void _toggleCart(BuildContext context, bool isInCart) {
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    final messenger = ScaffoldMessenger.of(context);

    if (isInCart) {
      cartProvider.removeFromCart(product.id);
      messenger.showSnackBar(
        SnackBar(
          content: Text('${product.name} removed from cart'),
          duration: const Duration(seconds: 1),
        ),
      );
      return;
    }

    cartProvider.addProduct({
      'id': product.id,
      'name': product.name,
      'price': product.price,
      'image': _imageSource,
      'category': product.category ?? '',
      'quantity': 1,
      'size': product.sizes?.isNotEmpty == true ? product.sizes![0] : 'Default',
    });
    messenger.showSnackBar(
      SnackBar(
        content: Text('${product.name} added to cart'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);
    final isInCart = cartProvider.isProductInCart(product.id);

    return GestureDetector(
      onTap: () => _navigateToDetail(context),
      child: Container(
        width: isHorizontal ? double.infinity : null,
        height: isHorizontal ? 116 : null,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: AppTheme.surfaceRaised,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          border: Border.all(color: AppTheme.borderSoft),
        ),
        child: isHorizontal
            ? _buildHorizontalLayout(context, isInCart)
            : _buildVerticalLayout(context, isInCart),
      ),
    );
  }

  // ---------------------------------------------------------------
  // Layouts
  // ---------------------------------------------------------------

  /// Grid tile. The image takes whatever height the grid cell leaves over, so
  /// the card always fills its slot exactly rather than trailing blank space.
  Widget _buildVerticalLayout(BuildContext context, bool isInCart) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: SizedBox(
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                ProductImage(_imageSource, fit: BoxFit.cover),
                _buildBadges(),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(10, 10, 10, 11),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Fixed to two lines so prices stay on a common baseline across
              // the row regardless of how long each name runs.
              SizedBox(
                height: 34,
                child: Text(
                  product.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style:
                      AppTheme.ui(13, weight: FontWeight.w500, height: 1.28),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: _buildPrice(17)),
                  const SizedBox(width: 8),
                  _CartButton(
                    isInCart: isInCart,
                    onTap: () => _toggleCart(context, isInCart),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHorizontalLayout(BuildContext context, bool isInCart) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          width: 96,
          child: Stack(
            fit: StackFit.expand,
            children: [
              ProductImage(_imageSource, fit: BoxFit.cover),
              _buildBadges(),
            ],
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  product.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.ui(14, weight: FontWeight.w500, height: 1.25),
                ),
                Row(
                  children: [
                    Expanded(child: _buildPrice(18)),
                    const SizedBox(width: 8),
                    _CartButton(
                      isInCart: isInCart,
                      onTap: () => _toggleCart(context, isInCart),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------
  // Pieces
  // ---------------------------------------------------------------

  Widget _buildPrice(double size) {
    final original = product.originalPrice;
    final hasOriginal = original != null && original > product.price;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (hasOriginal)
          Text(
            formatPkr(original),
            maxLines: 1,
            style: AppTheme.ui(11, color: AppTheme.textMuted).copyWith(
              decoration: TextDecoration.lineThrough,
            ),
          ),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            formatPkr(product.price),
            maxLines: 1,
            style: AppTheme.display(size),
          ),
        ),
      ],
    );
  }

  Widget _buildBadges() {
    if (!product.isNew && product.discount <= 0) {
      return const SizedBox.shrink();
    }

    return Positioned(
      top: 8,
      left: 8,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (product.isNew) const _Badge('New', color: AppTheme.ink),
          if (product.discount > 0)
            Padding(
              padding: EdgeInsets.only(top: product.isNew ? 4 : 0),
              child: _Badge('-${product.discount}%', color: AppTheme.accent),
            ),
        ],
      ),
    );
  }
}

/// Small overlay pill for NEW / discount markers.
class _Badge extends StatelessWidget {
  final String label;
  final Color color;

  const _Badge(this.label, {required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AppTheme.radiusSm - 4),
      ),
      child: Text(
        label.toUpperCase(),
        style: AppTheme.mono(9, color: Colors.white, tracking: 0.06),
      ),
    );
  }
}

/// Compact circular add/remove control. Kept small so the price beside it
/// never has to truncate.
class _CartButton extends StatelessWidget {
  final bool isInCart;
  final VoidCallback onTap;

  const _CartButton({required this.isInCart, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: isInCart ? AppTheme.positive : AppTheme.accent,
          shape: BoxShape.circle,
        ),
        child: Icon(
          isInCart ? Icons.check : Icons.add,
          color: Colors.white,
          size: 19,
        ),
      ),
    );
  }
}
