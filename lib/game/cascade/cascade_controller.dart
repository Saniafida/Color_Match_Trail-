import 'package:flutter/foundation.dart';
import '../../models/models.dart';
import '../blast/blast.dart';
import '../gravity/gravity.dart';
import 'board_match_scanner.dart';
import 'cascade_result.dart';

class CascadeController extends ChangeNotifier {
  final BoardMatchScanner matchScanner;
  final BlastController blastController;
  final GravityController gravityController;
  final int maxCascadeIterations;

  bool _isRunning = false;
  bool get inputLocked => _isRunning || gravityController.inputLocked || blastController.isBlasting;

  CascadeController({
    required this.matchScanner,
    required this.blastController,
    required this.gravityController,
    this.maxCascadeIterations = 20,
  });

  Future<CascadeResult> startCascade(List<BlockColor> allowedColors) async {
    if (_isRunning) {
      return const CascadeResult(completed: false, cascadeLevel: 0, totalCascadeBlasts: 0, totalDestroyedBlocks: 0, phases: []);
    }

    _isRunning = true;
    notifyListeners();

    int currentCascadeLevel = 0;
    int totalCascadeBlasts = 0;
    int totalDestroyedBlocks = 0;
    final List<CascadeBlastPhase> phases = [];

    int iterations = 0;

    while (iterations < maxCascadeIterations) {
      iterations++;

      // Scan for automatic board matches
      final matches = matchScanner.scan();
      if (matches.isNotEmpty) {
        currentCascadeLevel += matches.length;
        final Set<String> uniqueIds = {};
        for (final match in matches) {
          totalCascadeBlasts++;
          final blastRes = await blastController.processMatch(match, source: DestructionSource.cascade);
          if (blastRes.success) {
            uniqueIds.addAll(blastRes.destroyedBlockIds);
            totalDestroyedBlocks += blastRes.destroyedCount;
          }
        }
        phases.add(CascadeBlastPhase(
          cascadeLevel: iterations,
          matches: matches,
          uniqueDestroyedBlockIds: uniqueIds,
          totalDestroyedCount: uniqueIds.length,
        ));
      }
      
      // Apply gravity and block spawning
      final gravityResult = await gravityController.applyGravity(allowedColors);
      
      if (!gravityResult.cascadeCheckRequired && matches.isEmpty) {
        break; // Board is completely stable
      }
    }

    _isRunning = false;
    notifyListeners();

    return CascadeResult(
      completed: true,
      cascadeLevel: currentCascadeLevel,
      totalCascadeBlasts: totalCascadeBlasts,
      totalDestroyedBlocks: totalDestroyedBlocks,
      phases: phases,
    );
  }
}
