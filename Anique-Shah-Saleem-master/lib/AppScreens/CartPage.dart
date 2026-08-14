import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:prac/Controller/CartProvider.dart';
import 'package:prac/widgets/cart_badge_icon.dart';
import 'package:prac/res/app_theme.dart';
import 'package:prac/AppScreens/Checkout/CheckoutPage.dart';
import 'package:prac/services/auth_service.dart';
import 'package:prac/Authentication/Login.dart';

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  // Helper widget to display product image
  Widget _buildProductImage(String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) {
      debugPrint('No image provided, using logo');
      return Image.asset('assets/images/logo.png', 
        width: 80, 
        height: 80, 
        fit: BoxFit.cover
      );
    }
    
    // Clean up the image URL by removing any leading/trailing whitespace
    final cleanImageUrl = imageUrl.trim();
    debugPrint('Loading image: $cleanImageUrl');
    
    // Handle network images
    if (cleanImageUrl.startsWith('http')) {
      return Image.network(
        cleanImageUrl,
        width: 80,
        height: 80,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          debugPrint('Failed to load network image: $cleanImageUrl');
          return _buildFallbackImage();
        },
      );
    }
    
    // Handle local assets - try multiple possible paths
    final List<String> possiblePaths = [];
    
    // 1. Try the exact path first
    possiblePaths.add(cleanImageUrl);
    
    // 2. Try with assets/ prefix if not already there
    if (!cleanImageUrl.startsWith('assets/')) {
      possiblePaths.add('assets/$cleanImageUrl');
    }
    
    // 3. Try with assets/images/ prefix
    final imageName = cleanImageUrl.split('/').last;
    if (!imageName.startsWith('assets/')) {
      possiblePaths.add('assets/images/$imageName');
    }
    
    // Try each path until one works
    for (final path in possiblePaths) {
      try {
        return Image.asset(
          path,
          width: 80,
          height: 80,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            debugPrint('Failed to load image at path: $path');
            return const SizedBox.shrink(); // Return empty widget to try next path
          },
        );
      } catch (e) {
        debugPrint('Error loading image at $path: $e');
      }
    }
    
    // If we get here, all paths failed
    debugPrint('All image paths failed for: $cleanImageUrl');
    return _buildFallbackImage();
  }
  
  Widget _buildFallbackImage() {
    return Image.asset(
      'assets/images/logo.png',
      width: 80,
      height: 80,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        // If even the logo fails to load, return a colored container as a last resort
        return Container(
          width: 80,
          height: 80,
          color: Colors.grey[200],
          child: const Icon(Icons.image_not_supported, color: Colors.grey),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);
    final cart = cartProvider.cart; // Get cart data

    return Scaffold(
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.white,
                  Color(0xFFE8F5FF),
                ],
              ),
            ),
          ),

          // Cart Content
          Column(
            children: [
              AppBar(
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => Navigator.pop(context),
                ),
                title: const Text(
                  "Your Shopping Cart",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
                backgroundColor: Colors.transparent,
                elevation: 0,
                actions: [
                  IconButton(
                    icon: const Icon(Icons.shopping_bag_outlined),
                    onPressed: () {
                      void navigateToHome() {
                        // Navigate to home screen (replace with your actual home screen)
                        Navigator.pushNamedAndRemoveUntil(
                          context,
                          '/',  // Replace with your home route
                          (route) => false,
                        );
                      }
                      navigateToHome();
                    },
                  ),
                  const CartBadgeIcon(
                    iconColor: Colors.black,
                    key: ValueKey('cart_badge_header'),
                  ),
                ],
              ),
              Expanded(
                child: cart.isEmpty
                    ? _buildEmptyCart()
                    : ListView.builder(
                        itemCount: cart.length,
                        itemBuilder: (context, index) {
                          final cartItem = cart[index];
                          var productTotalPrice =
                              cartItem['price'] * cartItem['quantity'];

                          return Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.05),
                                    blurRadius: 10,
                                    spreadRadius: 0,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Row(
                                  children: [
                                    // Product Image
                                    Container(
                                      width: 80,
                                      height: 80,
                                      decoration: BoxDecoration(
                                        color: Colors.grey[100],
                                        borderRadius: BorderRadius.circular(15),
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(15),
                                        child: _buildProductImage(
                                          (cartItem['imageUrl'] ?? cartItem['image'])?.toString(),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    // Product Details
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            cartItem['name'].toString(),
                                            style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold),
                                          ),
                                          Text(
                                            'Size: ${cartItem['size']}',
                                            style: const TextStyle(
                                                fontSize: 14,
                                                color: AppTheme.textLight),
                                          ),
                                          const SizedBox(height: 8),
                                          // Quantity Controls
                                          Container(
                                            decoration: BoxDecoration(
                                              color: Colors.grey.shade50,
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              border: Border.all(
                                                  color: Colors.grey.shade200),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                IconButton(
                                                  icon: const Icon(Icons.remove,
                                                      size: 18),
                                                  onPressed: () {
                                                    Provider.of<CartProvider>(
                                                            context,
                                                            listen: false)
                                                        .updateQuantity(
                                                            cartItem, -1);
                                                  },
                                                  constraints:
                                                      const BoxConstraints(),
                                                  padding:
                                                      const EdgeInsets.all(8),
                                                ),
                                                Text(
                                                  cartItem['quantity']
                                                      .toString(),
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                IconButton(
                                                  icon: const Icon(Icons.add,
                                                      size: 18),
                                                  onPressed: () {
                                                    Provider.of<CartProvider>(
                                                            context,
                                                            listen: false)
                                                        .updateQuantity(
                                                            cartItem, 1);
                                                  },
                                                  constraints:
                                                      const BoxConstraints(),
                                                  padding:
                                                      const EdgeInsets.all(8),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    // Price and Delete
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          'PKR ${productTotalPrice.toStringAsFixed(2)}',
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Color.fromARGB(255, 79, 70, 248),
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                        IconButton(
                                          icon: Icon(
                                            Icons.delete_outline,
                                            color: const Color.fromARGB(255, 119, 65, 255)
                                                .withValues(alpha: 0.7),
                                            size: 22,
                                          ),
                                          onPressed: () {
                                            _showDeleteConfirmation(
                                                context, cartItem);
                                          },
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),

              // Bottom section with total and checkout
              if (cart.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(20.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        spreadRadius: 0,
                        offset: const Offset(0, -5),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Order summary
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Total (${cart.length} items):',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Consumer<CartProvider>(
                            builder: (context, cartProvider, child) {
                              double totalPrice = cartProvider.getTotalPrice();
                              return Text(
                                'PKR ${totalPrice.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color.fromARGB(255, 90, 65, 255),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      // Checkout button
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          gradient: AppTheme.accentGradient,
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [
                            BoxShadow(
                              color: const Color.fromARGB(255, 81, 65, 255).withValues(alpha: 0.3),
                              blurRadius: 8,
                              spreadRadius: 2,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: () async {
                            // Resolve the navigator before awaiting so we never
                            // touch a BuildContext that may be gone afterwards.
                            final navigator = Navigator.of(context);

                            // Check if user is logged in
                            final isLoggedIn = await AuthService.isLoggedIn();

                            if (!isLoggedIn) {
                              // If not logged in, show login screen
                              final result = await navigator.push(
                                MaterialPageRoute(builder: (_) => const Login()),
                              );

                              // If login was successful, proceed to checkout
                              if (result != true) return;
                            }

                            navigator.push(
                              MaterialPageRoute(builder: (_) => const CheckoutPage()),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color.fromARGB(255, 79, 70, 248),
                            shadowColor: Colors.transparent,
                            padding: const EdgeInsets.symmetric(vertical: 15),
                          ),
                          child: const Text(
                            'Proceed to Checkout',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // Show confirmation dialog when deleting a product
  void _showDeleteConfirmation(
      BuildContext context, Map<String, dynamic> cartItem) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text('Remove Product'),
          content: const Text(
              'Are you sure you want to remove this item from your cart?'),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.pop(context),
            ),
            TextButton(
              child: const Text(
                'Remove',
                style: TextStyle(color: Color.fromARGB(255, 89, 54, 244)),
              ),
              onPressed: () {
                Provider.of<CartProvider>(context, listen: false)
                    .removeProduct(cartItem);
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }

  // Empty cart view
  Widget _buildEmptyCart() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            size: 100,
            color: Colors.grey.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          const Text(
            'Your cart is empty',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Add items to get started',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
