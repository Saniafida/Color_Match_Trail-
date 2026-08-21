import 'package:flutter/material.dart';

class StarResult extends StatelessWidget {
  final int stars;

  const StarResult({super.key, required this.stars});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (index) {
        final earned = index < stars;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Icon(
            earned ? Icons.star : Icons.star_border,
            size: 48,
            color: earned ? Colors.amber : Colors.white30,
          ),
        );
      }),
    );
  }
}
