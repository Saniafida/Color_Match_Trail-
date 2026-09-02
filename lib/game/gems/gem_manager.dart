import 'package:flutter/foundation.dart';
import '../../core/storage/storage.dart';

class GemManager extends ChangeNotifier {
  final GameStorage storage;
  int _balance = 0;

  GemManager({required this.storage});

  int get balance => _balance;

  Future<void> initialize() async {
    _balance = await storage.getGems();
    notifyListeners();
  }

  Future<bool> addGems(int amount) async {
    if (amount <= 0) return false;
    _balance += amount;
    await storage.setGems(_balance);
    notifyListeners();
    return true;
  }

  Future<bool> spendGems(int amount) async {
    if (amount <= 0) return false;
    if (_balance < amount) return false;
    
    _balance -= amount;
    await storage.setGems(_balance);
    notifyListeners();
    return true;
  }

  void setGemsForTesting(int amount) {
    _balance = amount;
    notifyListeners();
  }
}
