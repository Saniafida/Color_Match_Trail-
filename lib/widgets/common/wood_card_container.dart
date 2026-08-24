import 'package:flutter/material.dart';

class WoodCardContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? width;
  final double? height;
  final double borderRadius;

  const WoodCardContainer({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin = const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    this.width,
    this.height,
    this.borderRadius = 20,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        color: const Color(0xFF6D4222), // Wood frame border
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: const Color(0xFFFFD54F),
          width: 3.0,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0xFF331A0B),
            offset: Offset(0, 5),
            blurRadius: 0,
          ),
          BoxShadow(
            color: Colors.black45,
            offset: Offset(0, 8),
            blurRadius: 10,
          ),
        ],
      ),
      child: Container(
        margin: const EdgeInsets.all(4),
        padding: padding,
        decoration: BoxDecoration(
          color: const Color(0xFFFFF9EC), // Inner cream board canvas
          borderRadius: BorderRadius.circular(borderRadius - 4),
          border: Border.all(
            color: const Color(0xFFE2CCAE),
            width: 1.5,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x22000000),
              offset: Offset(0, 2),
              blurRadius: 4,
            ),
          ],
        ),
        child: child,
      ),
    );
  }
}
