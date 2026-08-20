import 'package:flutter/material.dart';
import '../../core/services/service_locator.dart';
import '../../game/shop/shop_category.dart';
import '../../game/shop/shop_item_definition.dart';
import '../../game/shop/purchase_result.dart';
import '../../models/booster.dart';
import '../../widgets/rewards/reward_popup.dart';
import '../../game/rewards/reward_definition.dart';
import 'widgets/shop_header.dart';
import 'widgets/shop_category_tabs.dart';
import 'widgets/shop_item_card.dart';
import 'widgets/purchase_dialog.dart';

class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  final _shopManager = ServiceLocator.instance.shopManager;
  final _inventoryManager = ServiceLocator.instance.inventoryManager;

  ShopCategory _selectedCategory = ShopCategory.boosters;

  @override
  void initState() {
    super.initState();
    _shopManager.addListener(_onShopUpdated);
    _inventoryManager.addListener(_onInventoryUpdated);
  }

  @override
  void dispose() {
    _shopManager.removeListener(_onShopUpdated);
    _inventoryManager.removeListener(_onInventoryUpdated);
    super.dispose();
  }

  void _onShopUpdated() {
    if (mounted) setState(() {});
  }

  void _onInventoryUpdated() {
    if (mounted) setState(() {});
  }

  int _getCurrentInventory(ShopItemDefinition item) {
    if (item.itemType == ItemType.booster) {
      final type = BoosterType.values.firstWhere(
        (e) => e.name == item.itemId,
        orElse: () => BoosterType.hammer,
      );
      return _inventoryManager.getQuantity(type);
    }
    return 0;
  }

  Future<void> _handlePurchase(ShopItemDefinition item) async {
    // Show confirmation if it's an expensive item or a multi-pack
    if (item.price >= 200 || item.quantity > 1) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => PurchaseDialog(item: item),
      );
      if (confirm != true) return;
    }

    final result = await _shopManager.purchaseItem(item);

    if (!mounted) return;

    if (result.isSuccess) {
      // Use existing RewardPopup to celebrate
      final rewardDef = RewardDefinition(
        id: 'purchase_${item.id}_${DateTime.now().millisecondsSinceEpoch}',
        type: RewardType.booster, // Fallback since special is not in enum
        amount: item.quantity,
        itemId: item.itemId,
        source: 'shop',
      );
      RewardPopup.show(context, [rewardDef]);
    } else {
      // Show error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.status == PurchaseResultStatus.insufficientFunds
                ? 'Not enough coins!'
                : result.status == PurchaseResultStatus.inventoryFull
                    ? 'Inventory is full!'
                    : result.message ?? 'Purchase failed.',
          ),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredItems = _shopManager.items.where((i) => i.category == _selectedCategory).toList();

    return Scaffold(
      backgroundColor: const Color(0xFF141E2A),
      appBar: const ShopHeader(),
      body: _shopManager.isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.amber))
          : Column(
              children: [
                ShopCategoryTabs(
                  selectedCategory: _selectedCategory,
                  onCategorySelected: (cat) {
                    setState(() {
                      _selectedCategory = cat;
                    });
                  },
                ),
                Expanded(
                  child: filteredItems.isEmpty
                      ? const Center(
                          child: Text(
                            'No items available.',
                            style: TextStyle(color: Colors.white54, fontSize: 16),
                          ),
                        )
                      : GridView.builder(
                          padding: const EdgeInsets.all(16),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.75,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                          ),
                          itemCount: filteredItems.length,
                          itemBuilder: (context, index) {
                            final item = filteredItems[index];
                            return ShopItemCard(
                              item: item,
                              currentInventory: _getCurrentInventory(item),
                              onBuyPressed: () => _handlePurchase(item),
                              isPurchasing: false, // _shopManager.isPurchasing is not exposed globally by design to avoid rebuilding whole list, but we could!
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}
