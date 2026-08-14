import 'package:flutter/material.dart';
import 'package:prac/AppScreens/category_products_screen.dart';

class ShirtScreen extends StatelessWidget {
  const ShirtScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const CategoryProductsScreen(category: 'shirts');
  }
}
