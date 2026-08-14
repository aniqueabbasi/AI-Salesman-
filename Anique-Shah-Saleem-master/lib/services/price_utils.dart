import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:prac/Controller/ProductProvider.dart';

/// Utility class for managing product prices
class PriceUtils {
  /// Show price update simulation dialog
  static void showPriceUpdateDialog(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        backgroundColor: Colors.green,
      ),
    );
  }
  
  /// Simulated update of a specific product price
  static void updateSingleProductPrice(BuildContext context, String productId, double newPrice) {
    final provider = Provider.of<ProductProvider>(context, listen: false);
    // Refresh products to simulate price update
    provider.refreshProducts();
    
    // Show update confirmation
    showPriceUpdateDialog(
      context,
      'Updated price for product $productId to PKR ${newPrice.toStringAsFixed(2)}'
    );
  }
  
  /// Simulated update of prices for specific product categories
  static void updateCategoryPrices(BuildContext context, String category, double priceMultiplier) {
    final provider = Provider.of<ProductProvider>(context, listen: false);
    final products = provider.getProductsByCategory(category);
    
    // Refresh products to simulate price update
    provider.refreshProducts();
    
    // Show update confirmation
    showPriceUpdateDialog(
      context,
      'Updated prices for ${products.length} $category products with multiplier $priceMultiplier'
    );
  }
  
  /// Simulated discount application to all products 
  static void applyDiscountToAll(BuildContext context, double discountPercentage) {
    if (discountPercentage < 0 || discountPercentage > 100) {
      throw Exception('Discount percentage must be between 0 and 100');
    }
    
    final provider = Provider.of<ProductProvider>(context, listen: false);
    final products = provider.products;
    
    // Refresh products to simulate price update
    provider.refreshProducts();
    
    // Show update confirmation
    showPriceUpdateDialog(
      context,
      'Applied ${discountPercentage.toStringAsFixed(0)}% discount to ${products.length} products'
    );
  }
  
  /// Simulated batch update of prices
  static void updatePricesDirectly(BuildContext context, Map<String, double> priceMap) {
    final provider = Provider.of<ProductProvider>(context, listen: false);
    
    // Refresh products to simulate price update
    provider.refreshProducts();
    
    // Show update confirmation
    showPriceUpdateDialog(
      context,
      'Updated prices for ${priceMap.length} products'
    );
  }
  
  /// Force refresh all products to get latest prices
  static Future<void> refreshPrices(BuildContext context) async {
    final provider = Provider.of<ProductProvider>(context, listen: false);
    await provider.refreshProducts();
  }
  
  /// Example usage: Update all jacket prices by 15%
  static void example1(BuildContext context) {
    updateCategoryPrices(context, 'jacket', 1.15); // Increase by 15%
    refreshPrices(context); // Refresh to ensure UI updates
  }
  
  /// Example usage: Apply 20% discount to all products
  static void example2(BuildContext context) {
    applyDiscountToAll(context, 20); // 20% discount
    refreshPrices(context); // Refresh to ensure UI updates
  }
  
  /// Example usage: Set specific prices for products
  static void example3(BuildContext context) {
    updatePricesDirectly(context, {
      '1': 79.99,  // Premium Denim Jacket
      '2': 59.99,  // Classic Black Jeans
      '3': 89.99,  // Runner Sports Shoes
      '4': 45.99,  // Casual Cotton Shirt
      '5': 129.99, // Winter Jacket
      '6': 64.99,  // Slim Fit Jeans
    });
    refreshPrices(context); // Refresh to ensure UI updates
  }
} 