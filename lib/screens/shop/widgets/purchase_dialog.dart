import 'package:flutter/material.dart';
import '../../../game/shop/shop_item_definition.dart';

class PurchaseDialog extends StatelessWidget {
  final ShopItemDefinition item;

  const PurchaseDialog({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1E2A38),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Colors.amber, width: 2),
      ),
      title: const Text(
        'CONFIRM PURCHASE',
        textAlign: TextAlign.center,
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Buy ${item.name} for ${item.price} Coins?',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70, fontSize: 16),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('CANCEL', style: TextStyle(color: Colors.white54)),
                ),
              ),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('BUY'),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
}
