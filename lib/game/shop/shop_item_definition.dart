import 'shop_category.dart';

enum CurrencyType { coins, realMoney }
enum ItemType { booster, special, coinPackage }

class ShopItemDefinition {
  final String id;
  final String name;
  final String description;
  final ItemType itemType;
  final String itemId; // Maps to BoosterType.name, etc.
  final int quantity;
  final int price;
  final CurrencyType currencyType;
  final int maxPurchase;
  final bool enabled;
  final int sortOrder;
  final ShopCategory category;

  const ShopItemDefinition({
    required this.id,
    required this.name,
    required this.description,
    required this.itemType,
    required this.itemId,
    required this.quantity,
    required this.price,
    this.currencyType = CurrencyType.coins,
    this.maxPurchase = 5,
    this.enabled = true,
    this.sortOrder = 0,
    required this.category,
  });

  factory ShopItemDefinition.fromJson(Map<String, dynamic> json) {
    return ShopItemDefinition(
      id: json['id'] as String,
      name: json['titleKey'] as String? ?? json['name'] as String? ?? '',
      description: json['descriptionKey'] as String? ?? json['description'] as String? ?? '',
      itemType: ItemType.values.firstWhere(
        (e) => e.name == json['itemType'],
        orElse: () => ItemType.booster,
      ),
      itemId: json['itemId'] as String? ?? json['reward']?['itemId'] as String? ?? '',
      quantity: json['quantity'] as int? ?? json['reward']?['amount'] as int? ?? 1,
      price: json['price'] as int? ?? 0,
      currencyType: CurrencyType.values.firstWhere(
        (e) => e.name == json['currencyType'],
        orElse: () => CurrencyType.coins,
      ),
      maxPurchase: json['maxPurchase'] as int? ?? 5,
      enabled: json['enabled'] as bool? ?? true,
      sortOrder: json['sortOrder'] as int? ?? 0,
      category: ShopCategory.values.firstWhere(
        (e) => e.name == json['category'],
        orElse: () => ShopCategory.boosters,
      ),
    );
  }
}
