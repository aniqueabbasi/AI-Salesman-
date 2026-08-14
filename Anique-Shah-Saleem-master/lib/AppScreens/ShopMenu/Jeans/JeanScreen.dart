import 'package:flutter/material.dart';
import 'package:prac/AppScreens/category_products_screen.dart';

class JeanScreen extends StatelessWidget {
  const JeanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const CategoryProductsScreen(category: 'jeans');
  }
}
