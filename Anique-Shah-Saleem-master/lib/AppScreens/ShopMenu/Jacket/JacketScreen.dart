import 'package:flutter/material.dart';
import 'package:prac/AppScreens/category_products_screen.dart';

class JacketScreen extends StatelessWidget {
  const JacketScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const CategoryProductsScreen(category: 'jackets');
  }
}
