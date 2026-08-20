import 'package:flutter/foundation.dart';
import '../../core/storage/storage.dart';

class CoinManager extends ChangeNotifier {
  final GameStorage storage;
  int _balance = 0;

  CoinManager({required this.storage});

  int get balance => _balance;

  Future<void> initialize() async {
    _balance = await storage.getCoins();
    notifyListeners();
  }

  Future<bool> addCoins(int amount) async {
    if (amount <= 0) return false;
    _balance += amount;
    await storage.setCoins(_balance);
    notifyListeners();
    return true;
  }

  Future<bool> spendCoins(int amount) async {
    if (amount <= 0) return false;
    if (_balance < amount) return false; // Validation to prevent negative balance
    
    _balance -= amount;
    await storage.setCoins(_balance);
    notifyListeners();
    return true;
  }
}
