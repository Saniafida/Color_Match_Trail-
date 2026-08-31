import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../game/progression/level_progress.dart';
import 'level_node.dart';

class AdventureBoard extends StatefulWidget {
  final Map<String, LevelProgress> progressMap;
  final int selectedLevel;
  final int totalLevels;
  final void Function(int) onSelectLevel;

  const AdventureBoard({
    super.key,
    required this.progressMap,
    required this.selectedLevel,
    this.totalLevels = 147,
    required this.onSelectLevel,
  });

  @override
  State<AdventureBoard> createState() => _AdventureBoardState();
}

class _AdventureBoardState extends State<AdventureBoard> {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _selectedLevelKey = GlobalKey();

  // Pattern of tile counts per row from top to bottom
  static const List<int> _rowPatterns = [
    7,  // Row 15: 141 - 147
    8,  // Row 14: 133 - 140
    9,  // Row 13: 124 - 132
    10, // Row 12: 114 - 123
    11, // Row 11: 103 - 113
    12, // Row 10: 91 - 102 (widest point)
    11, // Row 9: 78 - 89 (or 80 - 90)
    10, // Row 8: 66 - 76
    9,  // Row 7: 55 - 65
    8,  // Row 6: 45 - 54
    7,  // Row 5: 36 - 44
    6,  // Row 4: 28 - 35
    6,  // Row 3: 21 - 27
    6,  // Row 2: 15 - 20
    5,  // Row 1: 10 - 14
    9,  // Row 0: 1 - 9 (base)
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        // Start from base of the map (level 1)
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
      // Smoothly slide / scroll up to the player's reached level
      Future.delayed(const Duration(milliseconds: 250), () {
        if (mounted) {
          _scrollToSelectedLevel(animated: true);
        }
      });
    });
  }

  @override
  void didUpdateWidget(covariant AdventureBoard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedLevel != widget.selectedLevel) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToSelectedLevel(animated: true);
      });
    }
  }

  void _scrollToSelectedLevel({bool animated = true}) {
    if (!mounted || !_scrollController.hasClients) return;

    final targetContext = _selectedLevelKey.currentContext;
    if (targetContext != null) {
      Scrollable.ensureVisible(
        targetContext,
        alignment: 0.45,
        duration: animated ? const Duration(milliseconds: 850) : Duration.zero,
        curve: Curves.easeInOutCubic,
      );
    } else {
      // Fallback calculation based on mosaic rows
      final mosaicRows = _generateMosaicRows();
      int targetRowIndex = -1;
      for (int i = 0; i < mosaicRows.length; i++) {
        if (mosaicRows[i].contains(widget.selectedLevel)) {
          targetRowIndex = i;
          break;
        }
      }

      if (targetRowIndex != -1) {
        final maxScroll = _scrollController.position.maxScrollExtent;
        final fraction = (targetRowIndex + 0.5) / (mosaicRows.isNotEmpty ? mosaicRows.length : 1);
        final targetOffset = (maxScroll * fraction).clamp(0.0, maxScroll);
        if (animated) {
          _scrollController.animateTo(
            targetOffset,
            duration: const Duration(milliseconds: 850),
            curve: Curves.easeInOutCubic,
          );
        } else {
          _scrollController.jumpTo(targetOffset);
        }
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  List<List<int>> _generateMosaicRows() {
    // Generate consecutive ranges matching the tapering shape
    final List<List<int>> rows = [];
    int currentNumber = 1;

    // Build from bottom row (Row 0) upwards
    final reversedCounts = _rowPatterns.reversed.toList();

    for (int count in reversedCounts) {
      final List<int> row = [];
      for (int i = 0; i < count; i++) {
        if (currentNumber <= widget.totalLevels) {
          row.add(currentNumber);
          currentNumber++;
        }
      }
      if (row.isNotEmpty) {
        rows.add(row);
      }
    }

    // Return in top-to-bottom order for vertical scroll view
    return rows.reversed.toList();
  }

  @override
  Widget build(BuildContext context) {
    final mosaicRows = _generateMosaicRows();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 4.0),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F0DF), // Warm rich parchment
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: const Color(0xFF7BA836), // Natural olive-green outer rim
          width: 5.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
          const BoxShadow(
            color: Color(0xFFEAD8B8),
            blurRadius: 1,
            spreadRadius: 1,
            offset: Offset(0, -1),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            // Subtle parchment gradient
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFFFCF6EB),
                    Color(0xFFF7EEDD),
                    Color(0xFFF1E4CD),
                  ],
                ),
              ),
            ),

            // Scrollable Content
            SingleChildScrollView(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(8, 48, 8, 16),
              child: Column(
                children: [
                  // 1. Golden Trophy Banner on Grass
                  _buildTrophySection(),

                  const SizedBox(height: 10),

                  // 2. Motivational Text & Divider
                  _buildMotivationText(),

                  const SizedBox(height: 14),

                  // 3. Tapering Diamond Mosaic Grid of Level Tiles
                  for (final row in mosaicRows)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2.0),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            for (final levelNum in row)
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 1.2),
                                child: _buildTile(levelNum),
                              ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Top Header: Carved Wooden "ADVENTURE" Banner Plate
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: _buildWoodHeader(),
            ),

            // Decorative Corner Flowers (Top-Left & Top-Right)
            Positioned(
              top: 4,
              left: 6,
              child: _buildDaisyCluster(),
            ),
            Positioned(
              top: 4,
              right: 6,
              child: Transform.flip(flipX: true, child: _buildDaisyCluster()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWoodHeader() {
    return Center(
      child: Container(
        margin: const EdgeInsets.only(top: 2),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(16),
            bottomRight: Radius.circular(16),
          ),
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF945725),
              Color(0xFF6B3C16),
              Color(0xFF4A250B),
            ],
          ),
          border: Border.all(
            color: const Color(0xFFE5B57A),
            width: 2.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Text(
          'ADVENTURE',
          style: TextStyle(
            color: Color(0xFFFFF9EE),
            fontWeight: FontWeight.w900,
            fontSize: 20,
            letterSpacing: 2.0,
            shadows: [
              Shadow(color: Colors.black87, blurRadius: 4, offset: Offset(0, 2)),
              Shadow(color: Color(0xFF2E1505), blurRadius: 1, offset: Offset(0, 3)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTrophySection() {
    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Golden Radial Glow
          Container(
            width: 130,
            height: 130,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  Color(0x66FFD54F),
                  Color(0x22FFD54F),
                  Colors.transparent,
                ],
              ),
            ),
          ),
          // 3D Trophy on Grass Image
          Image.asset(
            'assets/images/trophy_adventure.png',
            width: 120,
            height: 120,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) => const Icon(
              Icons.emoji_events_rounded,
              size: 80,
              color: Color(0xFFFFB300),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMotivationText() {
    return Column(
      children: [
        const Text(
          'Take part in the Adventure',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Color(0xFF4A2E12),
            fontWeight: FontWeight.w900,
            fontSize: 15,
            height: 1.2,
          ),
        ),
        const Text(
          'and win the trophy.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Color(0xFF4A2E12),
            fontWeight: FontWeight.w900,
            fontSize: 15,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 6),
        // Decorative Leafy Vine Divider
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 38,
              height: 1.5,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    const Color(0xFF7BA836).withValues(alpha: 0.7),
                  ],
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4.0),
              child: Icon(
                Icons.eco_rounded,
                color: Color(0xFF7BA836),
                size: 14,
              ),
            ),
            Container(
              width: 38,
              height: 1.5,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF7BA836).withValues(alpha: 0.7),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTile(int levelNum) {
    final levelId = 'level_$levelNum';
    final prevCompleted = levelNum > 1 && (widget.progressMap['level_${levelNum - 1}']?.completed ?? false);
    final recordedProgress = widget.progressMap[levelId];
    final isUnlocked = levelNum <= 1 || prevCompleted || (recordedProgress?.unlocked ?? false);
    
    final progress = recordedProgress != null
        ? recordedProgress.copyWith(unlocked: isUnlocked)
        : LevelProgress(
            levelId: levelId,
            unlocked: isUnlocked,
            completed: false,
            bestStars: 0,
            bestScore: 0,
          );

    final isCurrent = levelNum == widget.selectedLevel;

    return KeyedSubtree(
      key: isCurrent ? _selectedLevelKey : null,
      child: LevelNode(
        progress: progress,
        isCurrent: isCurrent,
        width: 32,
        height: 35,
        onTap: () {
          HapticFeedback.selectionClick();
          widget.onSelectLevel(levelNum);
        },
      ),
    );
  }

  Widget _buildDaisyCluster() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildSingleDaisy(size: 14),
        const SizedBox(width: 2),
        _buildSingleDaisy(size: 18),
      ],
    );
  }

  Widget _buildSingleDaisy({required double size}) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 2,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Center(
        child: Container(
          width: size * 0.45,
          height: size * 0.45,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Color(0xFFFFC107),
          ),
        ),
      ),
    );
  }
}
