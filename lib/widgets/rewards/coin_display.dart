import 'package:flutter/material.dart';
import '../../core/services/service_locator.dart';

class CoinDisplay extends StatefulWidget {
  const CoinDisplay({super.key});

  @override
  State<CoinDisplay> createState() => _CoinDisplayState();
}

class _CoinDisplayState extends State<CoinDisplay> {
  final _coinManager = ServiceLocator.instance.coinManager;

  @override
  void initState() {
    super.initState();
    _coinManager.addListener(_onCoinsChanged);
  }

  @override
  void dispose() {
    _coinManager.removeListener(_onCoinsChanged);
    super.dispose();
  }

  void _onCoinsChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black45,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.amber.withAlpha(128), width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.monetization_on, color: Colors.amber, size: 20),
          const SizedBox(width: 6),
          Text(
            '\${_coinManager.balance}',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}
