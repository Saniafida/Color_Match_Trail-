import 'dart:async';
import 'package:flutter/foundation.dart';
import 'combo_state.dart';
import 'combo_config.dart';

class ComboController extends ChangeNotifier {
  ComboState _state = const ComboState();
  ComboState get state => _state;
  
  Timer? _timeoutTimer;

  void registerScoreEvent() {
    final now = DateTime.now();
    int newLevel = 1;
    
    // Check if combo should continue based on timeout
    if (_state.lastEventTime != null) {
      final diff = now.difference(_state.lastEventTime!);
      if (diff <= ComboConfig.comboTimeout) {
        newLevel = _state.level + 1;
      }
    }
    
    _updateLevel(newLevel, now);
  }
  
  void registerCascade(int cascadeLevel) {
    // A cascade automatically extends the chain
    final now = DateTime.now();
    int newLevel = _state.level == 0 ? 1 : _state.level + 1;
    _updateLevel(newLevel, now);
  }

  void _updateLevel(int newLevel, DateTime time) {
    _state = ComboState(
      level: newLevel,
      multiplier: ComboConfig.getMultiplier(newLevel),
      lastEventTime: time,
    );
    notifyListeners();
    
    _timeoutTimer?.cancel();
    _timeoutTimer = Timer(ComboConfig.comboTimeout, reset);
  }

  void reset() {
    if (_state.isActive) {
      _state = const ComboState();
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _timeoutTimer?.cancel();
    super.dispose();
  }
}
