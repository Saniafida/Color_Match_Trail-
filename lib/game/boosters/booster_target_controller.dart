import 'package:flutter/foundation.dart';
import '../../models/position.dart';
import 'booster_definition.dart';
import 'booster_manager.dart';
import 'booster_use_state.dart';

class BoosterTargetController extends ChangeNotifier {
  final BoosterManager boosterManager;
  final bool Function(Position) isValidTarget;

  BoosterTargetController({
    required this.boosterManager,
    required this.isValidTarget,
  }) {
    boosterManager.addListener(_onBoosterStateChanged);
  }

  bool _isTargeting = false;
  bool get isTargeting => _isTargeting;

  BoosterDefinition? get currentBooster => boosterManager.selectedBoosterDef;

  void _onBoosterStateChanged() {
    final shouldBeTargeting = boosterManager.state == BoosterUseState.selecting;
    if (_isTargeting != shouldBeTargeting) {
      _isTargeting = shouldBeTargeting;
      notifyListeners();
    }
  }

  void handleTap(Position pos) {
    if (!_isTargeting) return;
    
    if (isValidTarget(pos)) {
      boosterManager.executeTargetedBooster(pos);
    } else {
      boosterManager.cancelSelection();
    }
  }

  void cancel() {
    if (_isTargeting) {
      boosterManager.cancelSelection();
    }
  }

  @override
  void dispose() {
    boosterManager.removeListener(_onBoosterStateChanged);
    super.dispose();
  }
}
