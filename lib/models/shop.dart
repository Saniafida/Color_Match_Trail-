import 'reward.dart';

class ShopItem {
  final String id;
  final String title;
  final String description;
  final double price;
  final String currencyType; // e.g., 'USD', 'COINS'
  final Reward reward;
  final bool isAvailable;

  const ShopItem({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.currencyType,
    required this.reward,
    this.isAvailable = true,
  });

  ShopItem copyWith({
    String? id,
    String? title,
    String? description,
    double? price,
    String? currencyType,
    Reward? reward,
    bool? isAvailable,
  }) {
    return ShopItem(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      price: price ?? this.price,
      currencyType: currencyType ?? this.currencyType,
      reward: reward ?? this.reward,
      isAvailable: isAvailable ?? this.isAvailable,
    );
  }
}
