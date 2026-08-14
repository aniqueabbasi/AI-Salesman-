import 'package:flutter/material.dart';

class JeanProductCard extends StatelessWidget {

  final String title;
  final int price;
  final String image;

  const JeanProductCard({super.key, required this.title, required this.price, required this.image});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 4, right: 4),
      padding: const EdgeInsets.only(bottom: 2),
      decoration: BoxDecoration(
          color: Colors.blue.shade100,
          borderRadius: BorderRadius.circular(12)
      ),
      child: Flexible(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Container(
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12)
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image(
                    image: AssetImage(image),
                    height: 110,
                    width: 155,
                    fit: BoxFit.cover, // Adjust this to control the fit
                  ),
                ),
              ),
            ),

            const Divider(
              color: Colors.grey,
            ),

            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),),

            Text('Rs $price', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),),
          ],
        ),
      ),
    );
  }
}
