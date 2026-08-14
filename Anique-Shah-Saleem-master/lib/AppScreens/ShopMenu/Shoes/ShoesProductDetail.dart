import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:prac/Controller/CartProvider.dart';

import '../../CartPage.dart';

class ShoesProductDetail extends StatefulWidget {
  final Map<String, Object> AllProduct;
  const ShoesProductDetail({super.key, required this.AllProduct});

  @override
  State<ShoesProductDetail> createState() => _ShoesProductDetailState();
}

class _ShoesProductDetailState extends State<ShoesProductDetail> {
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

        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: IconButton(
              icon: const Icon(Icons.shopping_cart, size: 28, color: Colors.pink), // Shopping Cart Icon
              onPressed: () {
                // Navigate to the cart screen
                Navigator.push(context, MaterialPageRoute(builder: (context)=>const CartPage()));
              },
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Product title
          Text(
            widget.AllProduct['title'] as String,
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
                itemCount: (widget.AllProduct['imagesUrl'] as List).length,
                itemBuilder: (context, index) {
                  String imageUrl = (widget.AllProduct['imagesUrl'] as List)[index];
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
                  'Rs ${widget.AllProduct['price']}',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 5),

                // Size options as chips
                SizedBox(
                  height: 50,
                  child: ListView.builder(
                    itemBuilder: (context, index) {
                      final size = (widget.AllProduct['sizes'] as List<dynamic>)[index];
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
                    itemCount: (widget.AllProduct['sizes'] as List<dynamic>).length,
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
                        'id': widget.AllProduct['id'],
                        'title': widget.AllProduct['title'],
                        'price': widget.AllProduct['price'],
                        'imageUrl': widget.AllProduct['imageUrl'],
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
    );
  }
}
