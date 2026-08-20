import 'shop_item_definition.dart';
import 'shop_category.dart';

class ShopRepository {
  static const List<ShopItemDefinition> _items = [
    // Boosters
    ShopItemDefinition(
      id: 'hammer_1',
      name: 'Hammer',
      description: 'Breaks any single block.',
      itemType: ItemType.booster,
      itemId: 'hammer',
      quantity: 1,
      price: 100,
      category: ShopCategory.boosters,
      sortOrder: 1,
    ),
    ShopItemDefinition(
      id: 'hammer_3',
      name: 'Hammer x3',
      description: 'Breaks any single block.',
      itemType: ItemType.booster,
      itemId: 'hammer',
      quantity: 3,
      price: 250,
      category: ShopCategory.boosters,
      sortOrder: 2,
    ),
    ShopItemDefinition(
      id: 'shuffle_1',
      name: 'Shuffle',
      description: 'Shuffles all blocks on the board.',
      itemType: ItemType.booster,
      itemId: 'shuffle',
      quantity: 1,
      price: 150,
      category: ShopCategory.boosters,
      sortOrder: 3,
    ),
    ShopItemDefinition(
      id: 'extra_moves_1',
      name: 'Extra Moves',
      description: '+5 Moves.',
      itemType: ItemType.booster,
      itemId: 'extraMoves',
      quantity: 1,
      price: 200,
      category: ShopCategory.boosters,
      sortOrder: 4,
    ),
    ShopItemDefinition(
      id: 'line_blast_1',
      name: 'Line Blast',
      description: 'Clears an entire row.',
      itemType: ItemType.booster,
      itemId: 'rowClear',
      quantity: 1,
      price: 300,
      category: ShopCategory.boosters,
      sortOrder: 5,
    ),
    ShopItemDefinition(
      id: 'color_bomb_1',
      name: 'Color Bomb',
      description: 'Clears all blocks of a selected color.',
      itemType: ItemType.booster,
      itemId: 'colorClear',
      quantity: 1,
      price: 400,
      category: ShopCategory.boosters,
      sortOrder: 6,
    ),
  ];

  Future<List<ShopItemDefinition>> getAvailableItems() async {
    // In the future this could load from an API or JSON asset.
    return _items.where((i) => i.enabled).toList();
  }
}
