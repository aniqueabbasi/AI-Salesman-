import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/Product.dart';
import '../Controller/CartProvider.dart';

class CartUtils {
  // Add a product to cart with proper image handling
  static void addToCart(BuildContext context, Product product) {
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    
    // Create cart item with all required fields
    final cartItem = {
      'id': product.id,
      'name': product.name,
      'title': product.name, // For backward compatibility
      'price': product.price,
      'imageUrl': _getFirstValidImage(product.images),
      'image': _getFirstValidImage(product.images), // Add both for compatibility
      'size': product.sizes?.isNotEmpty == true ? product.sizes!.first : 'One Size',
      'quantity': 1,
      'category': product.category ?? 'uncategorized',
      'description': product.description ?? '',
    };
    
    cartProvider.addProduct(cartItem);
    
    // Show success message
    _showSuccessMessage(context, product.name);
  }
  
  // Get first valid image URL or path
  static String _getFirstValidImage(List<String>? images) {
    if (images == null || images.isEmpty) {
      return 'assets/images/logo.png'; // Default fallback image
    }
    
    // Return the first non-empty image path
    for (var image in images) {
      if (image.isNotEmpty) {
        return image;
      }
    }
    
    return 'assets/images/logo.png'; // Fallback if all images are empty
  }
  
  // Show success message when item is added to cart
  static void _showSuccessMessage(BuildContext context, String productName) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$productName added to cart!'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}
