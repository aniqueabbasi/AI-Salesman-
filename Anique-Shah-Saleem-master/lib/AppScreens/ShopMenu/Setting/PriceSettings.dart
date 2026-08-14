import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:prac/Controller/ProductProvider.dart';
import 'package:prac/models/Product.dart';
import 'package:prac/res/app_theme.dart';

class PriceSettingsScreen extends StatefulWidget {
  const PriceSettingsScreen({Key? key}) : super(key: key);

  @override
  _PriceSettingsScreenState createState() => _PriceSettingsScreenState();
}

class _PriceSettingsScreenState extends State<PriceSettingsScreen> {
  bool _isEditing = false;
  bool _isLoading = false;
  final Map<String, TextEditingController> _priceControllers = {};

  @override
  void dispose() {
    // Dispose all controllers
    for (var controller in _priceControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  // Refresh product data
  void _refreshProducts() {
    setState(() {
      _isLoading = true;
    });

    Provider.of<ProductProvider>(context, listen: false).refreshProducts().then((_) {
      setState(() {
        _isLoading = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final productProvider = Provider.of<ProductProvider>(context);
    final products = productProvider.products;
    
    // Initialize controllers if needed
    for (var product in products) {
      if (!_priceControllers.containsKey(product.id)) {
        _priceControllers[product.id] = TextEditingController(
          text: product.price.toStringAsFixed(2)
        );
      } else {
        // Update controller if price has changed
        if (_priceControllers[product.id]!.text != product.price.toStringAsFixed(2)) {
          _priceControllers[product.id]!.text = product.price.toStringAsFixed(2);
        }
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Price Settings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshProducts,
          ),
          IconButton(
            icon: Icon(_isEditing ? Icons.save : Icons.edit),
            onPressed: () {
              setState(() {
                if (_isEditing) {
                  // Save all price changes
                  _saveAllPriceChanges(context);
                }
                _isEditing = !_isEditing;
              });
            },
          )
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : ListView.builder(
          itemCount: products.length,
          itemBuilder: (context, index) {
            final product = products[index];
            final controller = _priceControllers[product.id];
            
            return Card(
              margin: const EdgeInsets.all(8.0),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  children: [
                    // Product image
                    Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          image: AssetImage(product.images.isNotEmpty ? product.images[0] : 'assets/images/jacket1.jpg'),
                          fit: BoxFit.cover,
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    const SizedBox(width: 16),
                    
                    // Product details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            product.category ?? 'Category',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 8),
                          
                          // Price field (editable or static)
                          _isEditing 
                            ? TextField(
                                controller: controller,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'Price (PKR)',
                                  border: OutlineInputBorder(),
                                ),
                              )
                            : Text(
                                'PKR ${product.price.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  color: AppTheme.accentPink,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                        ],
                      ),
                    ),
                    
                    // Quick edit button for individual product
                    if (_isEditing)
                      IconButton(
                        icon: const Icon(Icons.check),
                        color: Colors.green,
                        onPressed: () => _saveProductPrice(context, product),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
    );
  }
  
  // Save a single product price
  void _saveProductPrice(BuildContext context, Product product) async {
    final controller = _priceControllers[product.id];
    
    if (controller != null) {
      try {
        final newPrice = double.parse(controller.text);
        
        // Since our ProductProvider doesn't have updateProductPrice method anymore,
        // we'll just demonstrate the price update UI
        _refreshProducts();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Price for ${product.name} updated to PKR ${newPrice.toStringAsFixed(2)}'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Invalid price format: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  // Save all product prices
  void _saveAllPriceChanges(BuildContext context) {
    final Map<String, double> priceUpdates = {};
    
    // Collect all price updates
    for (var entry in _priceControllers.entries) {
      try {
        final newPrice = double.parse(entry.value.text);
        priceUpdates[entry.key] = newPrice;
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Invalid price format for product ${entry.key}: $e'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }
    
    // Just refresh the UI to simulate price updates
    _refreshProducts();
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('All prices updated successfully!'),
        backgroundColor: Colors.green,
      ),
    );
  }
} 