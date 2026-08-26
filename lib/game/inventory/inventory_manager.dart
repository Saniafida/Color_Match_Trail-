import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../../core/storage/storage.dart';
import '../../models/booster.dart';
import '../boosters/booster_definition.dart';

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
    
    // Ensure all 6 boosters are available with a healthy starting supply
    final updatedMap = Map<BoosterType, int>.from(_inventory.quantities);
    for (final type in BoosterType.values) {
      if ((updatedMap[type] ?? 0) < 5) {
        updatedMap[type] = 5;
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

  int getQuantity(BoosterType type) => _inventory.getQuantity(type);

  Future<bool> addBooster(BoosterType type, int amount) async {
    if (amount <= 0) return false;
    
    final def = BoosterDefinition.registry[type];
    if (def == null) return false;

    // We do not enforce strict limits yet natively in BoosterInventory (it's unconstrained in module 21),
    // but the spec mentioned "Hammer max = 5". 
    // We will cap it if it exceeds 5.
    final current = getQuantity(type);
    final maxLimit = 5; // Default max limit 
    
    int added = amount;
    if (current + added > maxLimit) {
      added = maxLimit - current;
    }
    
    if (added <= 0) return true; // Capped out but successful

    _inventory = _inventory.increment(type, added);
    await _save();
    notifyListeners();
    return true;
  }

  Future<bool> consumeBooster(BoosterType type, [int amount = 1]) async {
    if (amount <= 0) return false;
    if (_inventory.getQuantity(type) < amount) return false;
    
    _inventory = _inventory.decrement(type);
    await _save();
    notifyListeners();
    return true;
  }
}
