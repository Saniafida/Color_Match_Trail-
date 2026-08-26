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
    final raw = await storage.getBoosterInventoryRaw();
    if (raw != null && raw.isNotEmpty) {
      try {
        _inventory = BoosterInventory.fromJson(jsonDecode(raw));
      } catch (e) {
        // Handle gracefully, remain default
      }
    }
    
    // Ensure all 6 boosters are stocked with generous supply (99 each)
    final updatedMap = Map<BoosterType, int>.from(_inventory.quantities);
    for (final type in BoosterType.values) {
      if ((updatedMap[type] ?? 0) < 10) {
        updatedMap[type] = 99;
      }
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
    final q = _inventory.getQuantity(type);
    return q > 0 ? q : 99;
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
    
    var current = _inventory.getQuantity(type);
    if (current <= 0) {
      current = 99;
      _inventory = _inventory.increment(type, 99);
    }
    
    _inventory = _inventory.decrement(type, amount.clamp(1, current));
    
    // Keep it continuously replenished for testing/fun
    if (_inventory.getQuantity(type) < 5) {
      _inventory = _inventory.increment(type, 20);
    }
    
    await _save();
    notifyListeners();
    return true;
  }
}
