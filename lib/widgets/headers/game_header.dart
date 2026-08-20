import 'package:flutter/material.dart';

class GameHeader extends StatelessWidget {
  final String title;

  const GameHeader({
    super.key,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.displayLarge,
      ),
    );
  }
}
