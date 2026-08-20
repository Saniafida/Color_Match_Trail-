import 'package:flutter/foundation.dart';
import '../../storage/game_save_manager.dart';

class AdFreeManager extends ChangeNotifier {
  final GameSaveManager saveManager;
  static const String _adFreeKey = 'isAdFree';

  AdFreeManager({required this.saveManager});

  bool get isAdFree {
    final monetization = saveManager.playerData.monetization;
    return monetization[_adFreeKey] as bool? ?? false;
  }

  void enableAdFree() {
    if (isAdFree) return;
    
    final updated = Map<String, dynamic>.from(saveManager.playerData.monetization);
    updated[_adFreeKey] = true;
    saveManager.updateMonetization(updated);
    notifyListeners();
  }

  void disableAdFree() {
    if (!isAdFree) return;

    final updated = Map<String, dynamic>.from(saveManager.playerData.monetization);
    updated[_adFreeKey] = false;
    saveManager.updateMonetization(updated);
    notifyListeners();
  }
}
