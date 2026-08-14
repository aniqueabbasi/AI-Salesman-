import 'package:flutter/material.dart';
import 'package:prac/AppScreens/category_products_screen.dart';

class ShoesScreen extends StatelessWidget {
  const ShoesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const CategoryProductsScreen(category: 'shoes');
  }
}
