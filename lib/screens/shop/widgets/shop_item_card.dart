import 'package:flutter/material.dart';
import '../../../game/shop/shop_item_definition.dart';
import '../../../models/booster.dart';
import '../../../game/boosters/booster_definition.dart';

class ShopItemCard extends StatelessWidget {
  final ShopItemDefinition item;
  final int currentInventory;
  final VoidCallback onBuyPressed;
  final bool isPurchasing;

  const ShopItemCard({
    super.key,
    required this.item,
    required this.currentInventory,
    required this.onBuyPressed,
    this.isPurchasing = false,
  });

  IconData _getIcon() {
    if (item.itemType == ItemType.booster) {
      final type = BoosterType.values.firstWhere(
        (e) => e.name == item.itemId,
        orElse: () => BoosterType.hammer,
      );
      final def = BoosterDefinition.registry[type];
      return def?.icon ?? Icons.star;
    }
    return Icons.star;
  }

  @override
  Widget build(BuildContext context) {
    final inventoryFull = currentInventory + item.quantity > item.maxPurchase;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF233245),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white24),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Owned: $currentInventory/${item.maxPurchase}',
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              ),
              if (item.quantity > 1)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.redAccent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'x${item.quantity}',
                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
          const Spacer(),
          Icon(_getIcon(), color: Colors.amber, size: 48),
          const SizedBox(height: 8),
          Text(
            item.name,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            item.description,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 10,
            ),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: (isPurchasing || inventoryFull) ? null : onBuyPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: inventoryFull ? Colors.grey : Colors.green,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: inventoryFull
                  ? const Text('FULL')
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.monetization_on, size: 16, color: Colors.amber),
                        const SizedBox(width: 4),
                        Text(
                          '${item.price}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
