import 'dart:async';
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
  Timer? _debounceTimer;

  // Pattern of tile counts per row from base (Row 0) upwards for the first 16 rows (sum = 134)
  static const List<int> _baseRowPatterns = [
    9,  // Row 0: 1 - 9 (base)
    5,  // Row 1: 10 - 14
    6,  // Row 2: 15 - 20
    6,  // Row 3: 21 - 27
    6,  // Row 4: 28 - 35
    7,  // Row 5: 36 - 44
    8,  // Row 6: 45 - 54
    9,  // Row 7: 55 - 65
    10, // Row 8: 66 - 76
    11, // Row 9: 77 - 87
    12, // Row 10: 88 - 99
    11, // Row 11: 100 - 110
    10, // Row 12: 111 - 120
    9,  // Row 13: 121 - 129
    8,  // Row 14: 130 - 137
    7,  // Row 15: 138 - 144
  ];

  // Procedural oscillating wave pattern for infinite rows (Row 16+)
  static const List<int> _wavePatterns = [8, 9, 10, 11, 12, 11, 10, 9, 8, 7, 6, 6, 7];

  late int _maxDisplayedLevel;
  bool _isGeneratingMore = false;

  @override
  void initState() {
    super.initState();
    // Start with at least 134, or higher if selectedLevel warrants it
    _maxDisplayedLevel = widget.totalLevels > 134
        ? widget.totalLevels
        : (widget.selectedLevel > 100 ? widget.selectedLevel + 40 : 134);

    _scrollController.addListener(_onScroll);

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
    if (widget.selectedLevel > _maxDisplayedLevel) {
      setState(() {
        _maxDisplayedLevel = widget.selectedLevel + 20;
      });
    }
  }

  void _onScroll() {
    if (!_scrollController.hasClients || _isGeneratingMore) return;
    // When the player scrolls UP towards the top summit (offset <= 350), dynamically generate more levels!
    if (_scrollController.position.pixels <= 350) {
      _generateMoreLevels();
    }
  }

  void _generateMoreLevels() {
    if (_isGeneratingMore) return;
    _isGeneratingMore = true;

    final double oldMaxScroll = _scrollController.position.maxScrollExtent;
    final double oldOffset = _scrollController.position.pixels;

    setState(() {
      // Prepend/add the next batch of 40 levels seamlessly
      _maxDisplayedLevel += 40;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        final double newMaxScroll = _scrollController.position.maxScrollExtent;
        final double delta = newMaxScroll - oldMaxScroll;
        if (delta > 0) {
          // Keep viewport position stationary so there is zero jump/jitter
          _scrollController.jumpTo((oldOffset + delta).clamp(0.0, newMaxScroll));
        }
      }
      _debounceTimer?.cancel();
      _debounceTimer = Timer(const Duration(milliseconds: 300), () {
        if (mounted) {
          setState(() {
            _isGeneratingMore = false;
          });
        }
      });
    });
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
    _debounceTimer?.cancel();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  int _getRowCount(int rowIndex) {
    if (rowIndex < _baseRowPatterns.length) {
      return _baseRowPatterns[rowIndex];
    }
    final waveIndex = (rowIndex - _baseRowPatterns.length) % _wavePatterns.length;
    return _wavePatterns[waveIndex];
  }

  List<List<int>> _generateMosaicRows() {
    final List<List<int>> rows = [];
    int currentNumber = 1;
    int rowIndex = 0;

    while (currentNumber <= _maxDisplayedLevel) {
      final count = _getRowCount(rowIndex);
      final List<int> row = [];
      for (int i = 0; i < count; i++) {
        if (currentNumber <= _maxDisplayedLevel) {
          row.add(currentNumber);
          currentNumber++;
        } else {
          break;
        }
      }
      if (row.isNotEmpty) {
        rows.add(row);
      }
      rowIndex++;
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

            // Scrollable Content with smooth, fluid sliding physics
            RepaintBoundary(
              child: SingleChildScrollView(
                controller: _scrollController,
                physics: const ClampingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                padding: const EdgeInsets.fromLTRB(8, 48, 8, 16),
                child: Column(
                  children: [
                    // Dynamic Level Generation Pulse Indicator at the summit
                    if (_isGeneratingMore)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF7BA836),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: const [
                              BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
                            ],
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Generating Higher Levels...',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    // Top padding for the mosaic levels
                    const SizedBox(height: 12),

                    // Tapering Diamond Mosaic Grid of Level Tiles (each row cached with RepaintBoundary)
                    for (final row in mosaicRows)
                      RepaintBoundary(
                        child: Padding(
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
                      ),
                  ],
                ),
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
        onTap: isUnlocked
            ? () {
                HapticFeedback.selectionClick();
                widget.onSelectLevel(levelNum);
              }
            : null,
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
