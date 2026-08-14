import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../Controller/CartProvider.dart';
import '../res/app_theme.dart';
import '../models/Product.dart';
import '../AppScreens/ProductDetailPage.dart';

class ProductCard extends StatelessWidget {
  final Product product;
  final bool isHorizontal;
  final bool useProductData;
  
  const ProductCard({
    Key? key,
    required this.product,
    this.isHorizontal = false,
    this.useProductData = false,
  }) : super(key: key);

  /// Renders the product's own artwork when it has any, falling back to the
  /// supplied bundled asset only as a placeholder. Seller uploads arrive as
  /// http URLs, the seeded catalogue uses `assets/...` paths.
  Widget _productImage(
    String placeholderAsset, {
    required double? width,
    required double height,
  }) {
    Widget broken() => Container(
          width: width,
          height: height,
          color: Colors.grey.shade200,
          child: Icon(Icons.image_not_supported,
              color: Colors.grey.shade400, size: height > 100 ? 40 : 24),
        );

    final String source = product.images.isNotEmpty &&
            product.images.first.trim().isNotEmpty
        ? product.images.first.trim()
        : placeholderAsset;

    if (source.startsWith('http')) {
      return Image.network(
        source,
        width: width,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => broken(),
      );
    }
    return Image.asset(
      source,
      width: width,
      height: height,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => broken(),
    );
  }

  void _navigateToDetail(BuildContext context) {
    List<String> assetImages = [
      'assets/images/jean1.jpg',
      'assets/images/green.jpg',
      'assets/images/casual.jpg',
      'assets/images/m2.jpg',
      'assets/images/m3.jpg',
      'assets/images/jean2.jpg',
    ];
    int index = int.tryParse(product.id) ?? product.id.hashCode;
    String assetImage = assetImages[index % assetImages.length];
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProductDetailPage(product: product, assetImage: assetImage),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);
    final bool isInCart = cartProvider.isProductInCart(product.id);
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;
    
    // Use product data if flag is set
    if (useProductData && product.images.isNotEmpty) {
      return GestureDetector(
        onTap: () {
          _navigateToDetail(context);
        },
        child: Container(
          width: isHorizontal ? double.infinity : null,
          margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: SizedBox(
            height: isHorizontal ? 120 : 200,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 110,
                  width: double.infinity,
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                    child: _productImage(product.images[0],
                        width: double.infinity, height: 110),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: AppTheme.textDark,
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'PKR ${product.price.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: AppTheme.accentColor,
                            ),
                          ),
                          _buildCartButton(context, isInCart),
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
    }
    
    return GestureDetector(
      onTap: () {
        _navigateToDetail(context);
      },
      child: Container(
        width: isHorizontal ? double.infinity : null,
        margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: SizedBox(
          height: isHorizontal ? 120 : 200,
          child: isHorizontal 
            ? _buildHorizontalLayout(context, isInCart, isSmallScreen) 
            : _buildVerticalLayout(context, isInCart, isSmallScreen),
        ),
      ),
    );
  }

  Widget _buildVerticalLayout(BuildContext context, bool isInCart, bool isSmallScreen) {
    // Use a fixed list of asset images and alternate by product index
    List<Map<String, String>> assetImageData = [
      {
        'image': 'assets/images/jean1.jpg',
        'title': 'Classic Blue Jeans',
        'description': 'Comfortable and stylish blue jeans for everyday wear.'
      },
      {
        'image': 'assets/images/green.jpg',
        'title': 'Green Casual Shirt',
        'description': 'Fresh green shirt for a smart casual look.'
      },
      {
        'image': 'assets/images/casual.jpg',
        'title': 'Casual T-Shirt',
        'description': 'Soft and comfy t-shirt for relaxed days.'
      },
      {
        'image': 'assets/images/m2.jpg',
        'title': 'Modern Jacket',
        'description': 'Trendy jacket to keep you warm and stylish.'
      },
      {
        'image': 'assets/images/m3.jpg',
        'title': 'Urban Hoodie',
        'description': 'Perfect hoodie for urban adventures.'
      },
      {
        'image': 'assets/images/jean2.jpg',
        'title': 'Slim Fit Jeans',
        'description': 'Slim fit jeans for a modern look.'
      },
    ];
    int index = int.tryParse(product.id) ?? product.id.hashCode;
    var assetData = assetImageData[index % assetImageData.length];
    String assetImage = assetData['image']!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 110,
          width: double.infinity,
          child: Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
                child: _productImage(assetImage,
                    width: double.infinity, height: 110),
              ),
              
              if (product.isNew || product.discount > 0)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (product.isNew)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.accentColor,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'NEW',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 9,
                            ),
                          ),
                        ),
                      if (product.discount > 0)
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.error,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '-${product.discount}%',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 9,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        
        Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                product.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: AppTheme.textDark,
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (product.originalPrice != null && product.originalPrice! > product.price)
                          Text(
                            '\$${product.originalPrice!.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 10,
                              decoration: TextDecoration.lineThrough,
                              color: AppTheme.textLight,
                            ),
                          ),
                        Text(
                          'PKR ${product.price.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: AppTheme.accentColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: _buildCartButton(context, isInCart),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHorizontalLayout(BuildContext context, bool isInCart, bool isSmallScreen) {
    // Use a fixed list of asset images and alternate by product index
    List<Map<String, String>> assetImageData = [
      {
        'image': 'assets/images/jean1.jpg',
        'title': 'Classic Blue Jeans',
        'description': 'Comfortable and stylish blue jeans for everyday wear.'
      },
      {
        'image': 'assets/images/green.jpg',
        'title': 'Green Casual Shirt',
        'description': 'Fresh green shirt for a smart casual look.'
      },
      {
        'image': 'assets/images/casual.jpg',
        'title': 'Casual T-Shirt',
        'description': 'Soft and comfy t-shirt for relaxed days.'
      },
      {
        'image': 'assets/images/m2.jpg',
        'title': 'Modern Jacket',
        'description': 'Trendy jacket to keep you warm and stylish.'
      },
      {
        'image': 'assets/images/m3.jpg',
        'title': 'Urban Hoodie',
        'description': 'Perfect hoodie for urban adventures.'
      },
      {
        'image': 'assets/images/jean2.jpg',
        'title': 'Slim Fit Jeans',
        'description': 'Slim fit jeans for a modern look.'
      },
    ];
    int index = int.tryParse(product.id) ?? product.id.hashCode;
    var assetData = assetImageData[index % assetImageData.length];
    String assetImage = assetData['image']!;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            bottomLeft: Radius.circular(16),
          ),
          child: _productImage(assetImage, width: 90, height: 120),
        ),

        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  product.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: AppTheme.textDark,
                  ),
                ),
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (product.originalPrice != null && product.originalPrice! > product.price)
                            Text(
                              '\$${product.originalPrice!.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 10,
                                decoration: TextDecoration.lineThrough,
                                color: AppTheme.textLight,
                              ),
                            ),
                          Text(
                            'PKR ${product.price.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: AppTheme.accentColor,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    
                    _buildSmallCartButton(context, isInCart),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSmallCartButton(BuildContext context, bool isInCart) {
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    
    return Container(
      height: 32,
      width: 32,
      decoration: BoxDecoration(
        gradient: isInCart 
          ? const LinearGradient(
              colors: [Color(0xFF43A047), Color(0xFF2E7D32)],  // Success colors
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            )
          : AppTheme.brandGradient,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: isInCart 
              ? AppTheme.success.withValues(alpha: 0.2)
              : AppTheme.brandPrimary.withValues(alpha: 0.2),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: IconButton(
        padding: EdgeInsets.zero,
        icon: Icon(
          isInCart ? Icons.check : Icons.add_shopping_cart,
          color: Colors.white,
          size: 16,
        ),
        onPressed: () {
          if (isInCart) {
            cartProvider.removeFromCart(product.id);
          } else {
            // Build cart item with the same image that is currently shown
            String imgPath;
            if (product.images.isNotEmpty) {
              imgPath = product.images[0];
            } else {
              List<String> assetImages = [
                'assets/images/jean1.jpg',
                'assets/images/green.jpg',
                'assets/images/casual.jpg',
                'assets/images/m2.jpg',
                'assets/images/m3.jpg',
                'assets/images/jean2.jpg',
              ];
              int index = int.tryParse(product.id) ?? product.id.hashCode;
              imgPath = assetImages[index % assetImages.length];
            }
            cartProvider.addProduct({
              'id': product.id,
              'name': product.name,
              'price': product.price,
              'image': imgPath,
              'category': product.category ?? '',
              'quantity': 1,
              'size': product.sizes?.isNotEmpty == true ? product.sizes![0] : 'Default',
            });
          }
        },
      ),
    );
  }

  Widget _buildCartButton(BuildContext context, bool isInCart) {
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    
    return Container(
      height: 36,
      decoration: BoxDecoration(
        gradient: isInCart 
          ? const LinearGradient(
              colors: [Color(0xFF43A047), Color(0xFF2E7D32)],  // Success colors
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            )
          : AppTheme.brandGradient,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: isInCart 
              ? AppTheme.success.withValues(alpha: 0.3)
              : AppTheme.brandPrimary.withValues(alpha: 0.3),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: IconButton(
        padding: EdgeInsets.zero,
        icon: Icon(
          isInCart ? Icons.check : Icons.add_shopping_cart,
          color: Colors.white,
          size: 18,
        ),
        onPressed: () {
          if (isInCart) {
            cartProvider.removeFromCart(product.id);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${product.name} removed from cart'),
                duration: const Duration(seconds: 1),
                behavior: SnackBarBehavior.floating,
              ),
            );
          } else {
            // Build cart item with the same image that is currently shown
            String imgPath;
            if (product.images.isNotEmpty) {
              imgPath = product.images[0];
            } else {
              List<String> assetImages = [
                'assets/images/jean1.jpg',
                'assets/images/green.jpg',
                'assets/images/casual.jpg',
                'assets/images/m2.jpg',
                'assets/images/m3.jpg',
                'assets/images/jean2.jpg',
              ];
              int index = int.tryParse(product.id) ?? product.id.hashCode;
              imgPath = assetImages[index % assetImages.length];
            }
            cartProvider.addProduct({
              'id': product.id,
              'name': product.name,
              'price': product.price,
              'image': imgPath,
              'category': product.category ?? '',
              'quantity': 1,
              'size': product.sizes?.isNotEmpty == true ? product.sizes![0] : 'Default',
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${product.name} added to cart'),
                duration: const Duration(seconds: 1),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
      ),
    );
  }
} 