import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../../core/storage/storage.dart';
import '../../models/booster.dart';

class InventoryManager extends ChangeNotifier {
  final GameStorage storage;
  BoosterInventory _inventory = const BoosterInventory();

  InventoryManager({required this.storage});

  BoosterInventory get inventory => _inventory;

  Future<void> initialize() async {
    // Always initialize/reset all 6 power-ups to exactly 3
    final updatedMap = <BoosterType, int>{};
    for (final type in BoosterType.values) {
      updatedMap[type] = 3;
    }
    _inventory = BoosterInventory(quantities: updatedMap);
    await _save();
    notifyListeners();
  }

  Future<void> _save() async {
    final raw = jsonEncode(_inventory.toJson());
    await storage.setBoosterInventoryRaw(raw);
  }

  int getQuantity(BoosterType type) {
    return _inventory.getQuantity(type);
  }

  Future<bool> addBooster(BoosterType type, int amount) async {
    if (amount <= 0) return false;
    
    _inventory = _inventory.increment(type, amount);
    await _save();
    notifyListeners();
    return true;
  }

  Future<bool> consumeBooster(BoosterType type, [int amount = 1]) async {
    if (amount <= 0) return false;
    if (_inventory.getQuantity(type) < amount) return false;
    
    _inventory = _inventory.decrement(type, amount);
    await _save();
    notifyListeners();
    return true;
  }
}
