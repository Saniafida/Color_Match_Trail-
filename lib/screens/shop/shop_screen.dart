import 'package:flutter/material.dart';
import '../../core/services/service_locator.dart';
import '../../game/shop/shop_item_definition.dart';
import '../../widgets/common/game_top_bar.dart';
import '../../widgets/common/wood_sign_header.dart';

class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  final _shopManager = ServiceLocator.instance.shopManager;
  final _inventoryManager = ServiceLocator.instance.inventoryManager;

  int _selectedTabIndex = 0;
  final List<String> _tabs = ['Boosters', 'Coins', 'Items', 'Themes'];

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

  String _getBoosterAsset(String itemId) {
    if (itemId.contains('hammer')) return 'assets/images/boosters/hammer.png';
    if (itemId.contains('color')) return 'assets/images/boosters/color_bomb.png';
    if (itemId.contains('shuffle')) return 'assets/images/boosters/shuffle.png';
    if (itemId.contains('extra') || itemId.contains('move')) return 'assets/images/boosters/extra_moves.png';
    return 'assets/images/boosters/bomb.png';
  }

  Future<void> _handleBuy(ShopItemDefinition item) async {
    final result = await _shopManager.purchaseItem(item);
    if (!mounted) return;

    if (result.isSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Purchased ${item.name}!'),
          backgroundColor: const Color(0xFF4CAF50),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message ?? 'Not enough coins!'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredItems = _shopManager.items;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Garden Background
          Image.asset(
            'assets/images/backgrounds/bg_garden.jpg',
            fit: BoxFit.cover,
          ),

          // 2. Overlay
          Container(
            color: Colors.black.withAlpha(50),
          ),

          // 3. Content
          SafeArea(
            child: Column(
              children: [
                // Top Bar (Hearts, Coins, Gems, Settings)
                const GameTopBar(
                  showProfile: false,
                  showSettings: true,
                ),

                // Wood Sign Header: "Shop"
                WoodSignHeader(
                  title: 'Shop',
                  onBack: () => Navigator.pop(context),
                ),

                const SizedBox(height: 8),

                // Category Tabs: Boosters, Coins, Items, Themes
                _buildCategoryTabs(),

                const SizedBox(height: 8),

                // Shop Items List
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF9EC), // Inner cream board canvas
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFFFD54F), width: 2.5),
                      boxShadow: const [
                        BoxShadow(color: Colors.black38, offset: Offset(0, 4), blurRadius: 6),
                      ],
                    ),
                    child: ListView.separated(
                      itemCount: filteredItems.length,
                      separatorBuilder: (context, index) => const Divider(color: Color(0xFFE2CCAE), thickness: 1),
                      itemBuilder: (context, index) {
                        final item = filteredItems[index];
                        final assetPath = _getBoosterAsset(item.itemId);

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: Row(
                            children: [
                              // Icon image
                              Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: const Color(0xFFFFD54F), width: 1.5),
                                ),
                                child: ClipOval(
                                  child: Image.asset(assetPath, fit: BoxFit.cover),
                                ),
                              ),
                              const SizedBox(width: 12),

                              // Name & Description
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.name,
                                      style: const TextStyle(
                                        color: Color(0xFF3E200C),
                                        fontSize: 15,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                    Text(
                                      item.description,
                                      style: const TextStyle(
                                        color: Color(0xFF8D6E63),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Green Price Buy Button
                              GestureDetector(
                                onTap: () => _handleBuy(item),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFF8CE03E), Color(0xFF4CAF50), Color(0xFF2E7D32)],
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: Colors.white70, width: 1.5),
                                    boxShadow: const [
                                      BoxShadow(color: Color(0xFF1B5E20), offset: Offset(0, 2), blurRadius: 0),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Image.asset('assets/images/icons/icon_coin.png', width: 18, height: 18),
                                      const SizedBox(width: 6),
                                      Text(
                                        '${item.price}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryTabs() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFF5D3A1A),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFFD54F), width: 1.5),
      ),
      child: Row(
        children: List.generate(_tabs.length, (index) {
          final isSelected = index == _selectedTabIndex;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedTabIndex = index),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFFE53935) : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                  border: isSelected ? Border.all(color: Colors.white70, width: 1.2) : null,
                ),
                child: Center(
                  child: Text(
                    _tabs[index],
                    style: TextStyle(
                      color: isSelected ? Colors.white : const Color(0xFFD7CCC8),
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
