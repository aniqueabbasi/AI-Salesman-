import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:prac/Controller/CartProvider.dart';

import '../../CartPage.dart';

class JeanProductDetail extends StatefulWidget {
  final Map<String, Object> JeanProduct;
  const JeanProductDetail({super.key, required this.JeanProduct});

  @override
  State<JeanProductDetail> createState() => _JeanProductDetailState();
}

class _JeanProductDetailState extends State<JeanProductDetail> {
  var selectedSize = '';
  int quantity = 1;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Center(
          child: Text(
            'Product Detail',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ),
      body: Column(
        children: [
          // Product title
          Text(
            widget.JeanProduct['title'] as String,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const Spacer(),

          // Image slider using PageView
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Container(
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(8)),
              height: 350,
              width: double.infinity,
              child: PageView.builder(
                itemCount: (widget.JeanProduct['imagesUrl'] as List).length,
                itemBuilder: (context, index) {
                  String imageUrl = (widget.JeanProduct['imagesUrl'] as List)[index];
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.asset(imageUrl, fit: BoxFit.cover),
                  );
                },
              ),
            ),
          ),
          const Spacer(flex: 5),

          // Product details and size options
          Container(
            height: 300,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: Colors.blue.shade50,
            ),
            child: Column(
              children: [
                // Price display
                Text(
                  'Rs ${widget.JeanProduct['price']}',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 5),

                // Size options as chips
                SizedBox(
                  height: 50,
                  child: ListView.builder(
                    itemBuilder: (context, index) {
                      final size = (widget.JeanProduct['sizes'] as List<dynamic>)[index];
                      return Padding(
                        padding: const EdgeInsets.only(left: 28, right: 5),
                        child: Center(
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                selectedSize = size;
                              });
                            },
                            child: Chip(
                              label: Text(size.toString()),
                              backgroundColor: selectedSize == size
                                  ? Colors.yellow.shade200
                                  : Colors.white,
                            ),
                          ),
                        ),
                      );
                    },
                    itemCount: (widget.JeanProduct['sizes'] as List<dynamic>).length,
                    scrollDirection: Axis.horizontal,
                  ),
                ),
                const SizedBox(height: 10),

                // Add to Cart button
                ElevatedButton(
                  onPressed: () {
                    if (selectedSize.isNotEmpty) {
                      // Add product to cart with selected size and quantity
                      Provider.of<CartProvider>(context, listen: false).addProduct({
                        'id': widget.JeanProduct['id'],
                        'title': widget.JeanProduct['title'],
                        'price': widget.JeanProduct['price'],
                        'imageUrl': widget.JeanProduct['imageUrl'],
                        'size': selectedSize, // Pass selected size
                        'quantity': quantity, // Pass selected quantity
                      });

                      // Show success message
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Product added to cart successfully!'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    } else {
                      // Show error message if size is not selected
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please select a size!'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(340, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    backgroundColor: Colors.pink.shade300,
                  ),
                  child: const Text('Add to Cart'),
                ),

                const SizedBox(height: 16),

                // Buy Button with Size Restriction
                ElevatedButton(
                  onPressed: () {
                    if (selectedSize.isNotEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Center(child: Text('Thanks for Shopping!')),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Center(child: Text('Please select a size!')),
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(340, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    backgroundColor: Colors.pink.shade300,
                  ),
                  child: const Text("Buy"),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        height: 60,
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.2),
              spreadRadius: 1,
              blurRadius: 5,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Empty container to balance the row
            const SizedBox(width: 40),
            
            // Cart Button (centered)
            IconButton(
              icon: const Icon(Icons.shopping_cart, size: 32, color: Colors.pink),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const CartPage()),
                );
              },
            ),
            
            // Settings Button
            IconButton(
              icon: const Icon(Icons.settings, size: 28, color: Colors.grey),
              onPressed: () {
                // Add settings functionality here
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Settings')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
