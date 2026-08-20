import 'package:flutter/foundation.dart';
import '../../models/models.dart';
import '../blast/blast.dart';
import '../gravity/gravity.dart';
import '../trail/match_result.dart';
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
      
      // 1. Scan the board for automatic matches
      final matches = matchScanner.scan();
      
      if (matches.isEmpty) {
        break; // Board is stable
      }

      currentCascadeLevel++;
      
      final Set<String> uniqueDestroyedBlockIds = {};
      final List<MatchResult> validMatches = [];
      
      // Deduplicate blocks to prevent them from being destroyed twice if they somehow overlap
      for (final match in matches) {
        final List<String> safeBlockIds = [];
        final List<Position> safePositions = [];
        
        for (int i = 0; i < match.blockIds.length; i++) {
          final id = match.blockIds[i];
          if (!uniqueDestroyedBlockIds.contains(id)) {
            uniqueDestroyedBlockIds.add(id);
            safeBlockIds.add(id);
            safePositions.add(match.positions[i]);
          }
        }
        
        if (safeBlockIds.length >= matchScanner.minimumConnectionLength) {
          validMatches.add(MatchResult(
            isValid: true,
            length: safeBlockIds.length,
            positions: safePositions,
            blockIds: safeBlockIds,
            color: match.color,
            connectionType: match.connectionType,
          ));
        }
      }

      if (validMatches.isEmpty) {
        break;
      }

      // 2. Blast matched blocks
      for (final match in validMatches) {
        await blastController.processMatch(match);
        totalCascadeBlasts++;
      }
      
      totalDestroyedBlocks += uniqueDestroyedBlockIds.length;
      
      phases.add(CascadeBlastPhase(
        cascadeLevel: currentCascadeLevel,
        matches: validMatches,
        uniqueDestroyedBlockIds: uniqueDestroyedBlockIds,
        totalDestroyedCount: uniqueDestroyedBlockIds.length,
      ));

      // 3. Gravity and Spawning
      await gravityController.applyGravity(allowedColors);
    }

    if (iterations >= maxCascadeIterations) {
      // Reached safety iteration limit
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
