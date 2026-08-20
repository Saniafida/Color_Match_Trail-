import '../trail/match_result.dart';

class CascadeBlastPhase {
  final int cascadeLevel;
  final List<MatchResult> matches;
  final Set<String> uniqueDestroyedBlockIds;
  final int totalDestroyedCount;

  const CascadeBlastPhase({
    required this.cascadeLevel,
    required this.matches,
    required this.uniqueDestroyedBlockIds,
    required this.totalDestroyedCount,
  });
}

class CascadeResult {
  final bool completed;
  final int cascadeLevel;
  final int totalCascadeBlasts;
  final int totalDestroyedBlocks;
  final List<CascadeBlastPhase> phases;

  const CascadeResult({
    required this.completed,
    required this.cascadeLevel,
    required this.totalCascadeBlasts,
    required this.totalDestroyedBlocks,
    required this.phases,
  });
}
