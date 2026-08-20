import 'package:flutter/foundation.dart';
import 'shop_item_definition.dart';
import 'purchase_result.dart';
import 'shop_repository.dart';
import '../coins/coin_manager.dart';
import '../inventory/inventory_manager.dart';
import '../../models/booster.dart';

class ShopManager extends ChangeNotifier {
  final ShopRepository repository;
  final CoinManager coinManager;
  final InventoryManager inventoryManager;

  List<ShopItemDefinition> _items = [];
  bool _isLoading = true;
  bool _isPurchasing = false;

  ShopManager({
    required this.repository,
    required this.coinManager,
    required this.inventoryManager,
  });

  List<ShopItemDefinition> get items => _items;
  bool get isLoading => _isLoading;

  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      _items = await repository.getAvailableItems();
      _items.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    } catch (e) {
      _items = [];
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<PurchaseResult> purchaseItem(ShopItemDefinition item) async {
    if (_isPurchasing) {
      return const PurchaseResult(status: PurchaseResultStatus.error, message: 'Transaction in progress');
    }
    
    if (item.currencyType != CurrencyType.coins) {
      return const PurchaseResult(status: PurchaseResultStatus.error, message: 'Currency not supported yet');
    }

    _isPurchasing = true;
    notifyListeners(); // Optionally notify to show global loading indicator

    try {
      // 1. Verify Coins
      if (coinManager.balance < item.price) {
        _isPurchasing = false;
        notifyListeners();
        return const PurchaseResult(status: PurchaseResultStatus.insufficientFunds);
      }

      // 2. Verify Inventory limit
      if (item.itemType == ItemType.booster) {
        final type = BoosterType.values.firstWhere(
          (e) => e.name == item.itemId,
          orElse: () => BoosterType.hammer,
        );

        final currentAmount = inventoryManager.getQuantity(type);
        if (currentAmount + item.quantity > item.maxPurchase) {
          _isPurchasing = false;
          notifyListeners();
          return const PurchaseResult(status: PurchaseResultStatus.inventoryFull);
        }

        // 3. Process Transaction safely
        // First deduct coins. If it fails, abort.
        final spent = await coinManager.spendCoins(item.price);
        if (!spent) {
          _isPurchasing = false;
          notifyListeners();
          return const PurchaseResult(status: PurchaseResultStatus.error, message: 'Failed to deduct coins');
        }

        // Grant item
        final granted = await inventoryManager.addBooster(type, item.quantity);
        if (!granted) {
          // Rollback coins
          await coinManager.addCoins(item.price);
          _isPurchasing = false;
          notifyListeners();
          return const PurchaseResult(status: PurchaseResultStatus.error, message: 'Failed to grant item');
        }
        
        _isPurchasing = false;
        notifyListeners();
        return const PurchaseResult(status: PurchaseResultStatus.success);
      }

      _isPurchasing = false;
      notifyListeners();
      return const PurchaseResult(status: PurchaseResultStatus.error, message: 'Item type not fully implemented');
    } catch (e) {
      _isPurchasing = false;
      notifyListeners();
      return const PurchaseResult(status: PurchaseResultStatus.error, message: 'An unexpected error occurred');
    }
  }
}
