import 'dart:math';
import 'package:flutter/material.dart';
import '../../app/routes/routes.dart';
import '../../models/models.dart';
import '../../game/blocks/block_color_mapper.dart';
import '../../game/tile_sort/tile_sort_level_model.dart';
import '../../game/tile_sort/tile_sort_level_generator.dart';
import '../../core/services/service_locator.dart';
import '../gameplay/widgets/pause_dialog.dart';

class TileSortScreen extends StatefulWidget {
  final int startingLevel;

  const TileSortScreen({
    super.key,
    this.startingLevel = 1,
  });

  @override
  State<TileSortScreen> createState() => _TileSortScreenState();
}

class _TileSortScreenState extends State<TileSortScreen>
    with TickerProviderStateMixin {
  late int currentLevelNumber;
  late TileSortLevel currentLevel;

  // Game state
  late int movesRemaining;
  int currentScore = 0;

  // Boosters count
  int undoCount = 3;
  int addTubeCount = 3;
  int shuffleCount = 3;
  int skipCount = 3;

  // Tube stacks: each tube is a list of BlockColor (bottom -> top)
  late List<List<BlockColor>> tubes;
  final List<List<List<BlockColor>>> _history = [];

  // Selected tube index (-1 means none selected)
  int? selectedTubeIndex;

  // Tube completion celebration tracking
  final Set<int> _completedTubes = {};
  bool _isLevelComplete = false;

  // Shake animation for invalid move
  int? _shakingTubeIndex;
  late AnimationController _shakeController;

  @override
  void initState() {
    super.initState();
    currentLevelNumber = widget.startingLevel;
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _loadLevel(currentLevelNumber);
    try {
      ServiceLocator.instance.audioManager.playMiniGamesBgm();
    } catch (_) {}
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  void _loadLevel(int levelNum) {
    currentLevelNumber = levelNum;
    currentLevel = TileSortLevelGenerator.getLevel(levelNum);

    // Deep copy initial tubes
    tubes = currentLevel.initialTubes
        .map((tube) => List<BlockColor>.from(tube))
        .toList();

    _history.clear();
    _completedTubes.clear();
    selectedTubeIndex = null;
    movesRemaining = currentLevel.moves;
    _isLevelComplete = false;
    _checkCompletedTubes();
    if (mounted) setState(() {});
  }

  void _checkCompletedTubes() {
    for (int i = 0; i < tubes.length; i++) {
      if (tubes[i].length == currentLevel.capacity &&
          tubes[i].every((c) => c == tubes[i].first)) {
        _completedTubes.add(i);
      }
    }

    final totalActiveColors = currentLevel.activeColors.length;
    if (_completedTubes.length >= totalActiveColors) {
      setState(() {
        _isLevelComplete = true;
        currentScore += 1500 + (movesRemaining * 50);
      });
      try {
        ServiceLocator.instance.coinManager.addCoins(250);
        ServiceLocator.instance.gemManager.addGems(1);
      } catch (_) {}
    }
  }

  void _onTubeTapped(int tubeIndex) {
    if (_isLevelComplete || movesRemaining <= 0) return;

    final targetTube = tubes[tubeIndex];

    // If no tube currently selected
    if (selectedTubeIndex == null) {
      if (targetTube.isEmpty) return; // Cannot pick from empty tube
      if (_completedTubes.contains(tubeIndex)) return; // Already finished

      setState(() {
        selectedTubeIndex = tubeIndex;
      });
    } else {
      // Tube already selected
      final sourceIndex = selectedTubeIndex!;

      if (sourceIndex == tubeIndex) {
        // Deselect when tapping the same tube again
        setState(() {
          selectedTubeIndex = null;
        });
        return;
      }

      final sourceTube = tubes[sourceIndex];
      if (sourceTube.isEmpty) {
        setState(() => selectedTubeIndex = null);
        return;
      }

      final movingTile = sourceTube.last;

      // Validation rule: Destination is empty OR top tile matches color, AND not full
      final bool isValid = targetTube.length < currentLevel.capacity &&
          (targetTube.isEmpty || targetTube.last == movingTile);

      if (isValid) {
        // Save history for UNDO
        _history.add(tubes.map((t) => List<BlockColor>.from(t)).toList());

        setState(() {
          sourceTube.removeLast();
          targetTube.add(movingTile);
          selectedTubeIndex = null;
          movesRemaining--;
          currentScore += 100;

          _checkCompletedTubes();
        });
      } else {
        // Invalid move: shake destination tube
        setState(() {
          _shakingTubeIndex = tubeIndex;
          selectedTubeIndex = null;
        });
        _shakeController.forward(from: 0).then((_) {
          if (mounted) {
            setState(() {
              _shakingTubeIndex = null;
            });
          }
        });
      }
    }
  }

  // Booster: Undo
  void _onUndo() {
    if (_history.isEmpty || undoCount <= 0) return;
    setState(() {
      tubes = _history.removeLast();
      undoCount--;
      selectedTubeIndex = null;
      movesRemaining++;
      _completedTubes.clear();
      _checkCompletedTubes();
    });
  }

  // Booster: Add Tube
  void _onAddTube() {
    if (addTubeCount <= 0 || tubes.length >= 7) return;
    setState(() {
      tubes.add([]);
      addTubeCount--;
    });
  }

  // Booster: Shuffle
  void _onShuffle() {
    if (shuffleCount <= 0) return;
    setState(() {
      _history.add(tubes.map((t) => List<BlockColor>.from(t)).toList());
      final uncompletedBlocks = <BlockColor>[];
      for (int i = 0; i < tubes.length; i++) {
        if (!_completedTubes.contains(i)) {
          uncompletedBlocks.addAll(tubes[i]);
          tubes[i].clear();
        }
      }
      uncompletedBlocks.shuffle(Random());
      int tubeIdx = 0;
      for (final color in uncompletedBlocks) {
        while (_completedTubes.contains(tubeIdx) || tubes[tubeIdx].length >= currentLevel.capacity) {
          tubeIdx = (tubeIdx + 1) % tubes.length;
        }
        tubes[tubeIdx].add(color);
      }
      shuffleCount--;
      selectedTubeIndex = null;
      _checkCompletedTubes();
    });
  }

  // Booster: Skip
  void _onSkipLevel() {
    if (skipCount <= 0) return;
    setState(() {
      skipCount--;
      _isLevelComplete = true;
      currentScore += 2000;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Fullscreen Garden Background
          Image.asset(
            'assets/images/backgrounds/bg_garden.jpg',
            fit: BoxFit.cover,
          ),

          // 2. Soft Lush Green Tint Layer for High Contrast & Tube Visibility
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF1B3B1A).withAlpha(120), // Soft green top
                  const Color(0xFF0E2E14).withAlpha(150), // Emerald mid
                  const Color(0xFF081C0C).withAlpha(190), // Deep rich forest green bottom
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),

          // 3. Main Gameplay Layout
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 4),

                // TOP HUD: Back Button, Moves Box, Goal Panel, Score Box, Settings Button
                _buildTopHud(),

                const SizedBox(height: 6),

                // TITLE SIGN: "TILE SORT" with Level Badge
                _buildTitleSign(),

                const Spacer(flex: 1),

                // MAIN GAMEPLAY AREA: Tubes on Wooden Shelf Table
                _buildTubesGameplayArea(),

                const Spacer(flex: 1),

                // BOTTOM BOOSTER CONTROLS (Undo, Add Tube, Shuffle, Skip Level)
                _buildBottomBoostersBoard(),

                const SizedBox(height: 6),

                // HINT BAR
                _buildHintBar(),

                const SizedBox(height: 8),
              ],
            ),
          ),

          // 4. LEVEL COMPLETE CELEBRATION OVERLAY
          if (_isLevelComplete) _buildLevelCompleteOverlay(),
        ],
      ),
    );
  }

  // ==========================================
  // 🏆 TOP HUD
  // ==========================================
  Widget _buildTopHud() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 1. Back Arrow Button
          _buildCircleIconButton(
            icon: Icons.arrow_back_rounded,
            colorGradient: const [Color(0xFF42A5F5), Color(0xFF1976D2)],
            shadowColor: const Color(0xFF0D47A1),
            borderColor: const Color(0xFF90CAF9),
            onTap: () => Navigator.pop(context),
          ),

          // 2. Moves Box
          Container(
            width: 58,
            height: 64,
            decoration: _woodenPanelDecoration(),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Moves',
                  style: TextStyle(
                    color: Color(0xFF7A4E24),
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  '$movesRemaining',
                  style: const TextStyle(
                    color: Color(0xFF3E200C),
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),

          // 3. Dynamic Goal Panel
          Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.topCenter,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 10),
                padding: const EdgeInsets.fromLTRB(8, 14, 8, 4),
                decoration: _woodenPanelDecoration(),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: currentLevel.activeColors.map((color) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2.0),
                      child: _buildGoalTile(color, currentLevel.capacity),
                    );
                  }).toList(),
                ),
              ),

              // Blue Ribbon Header: "Goal"
              Positioned(
                top: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF42A5F5), Color(0xFF1565C0)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFBBDEFB), width: 1.2),
                    boxShadow: const [
                      BoxShadow(color: Color(0xFF0D47A1), offset: Offset(0, 1.5), blurRadius: 0),
                    ],
                  ),
                  child: const Text(
                    'Goal',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ],
          ),

          // 4. Score Box
          Container(
            width: 58,
            height: 64,
            decoration: _woodenPanelDecoration(),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Score',
                  style: TextStyle(
                    color: Color(0xFF7A4E24),
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  '$currentScore',
                  style: const TextStyle(
                    color: Color(0xFF3E200C),
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(3, (i) {
                    final earned = currentScore >= (i + 1) * 400;
                    return Icon(
                      Icons.star_rounded,
                      color: earned ? const Color(0xFFFFB300) : const Color(0xFF8D6E63),
                      size: 13,
                    );
                  }),
                ),
              ],
            ),
          ),

          // 5. Pause Button
          _buildCircleIconButton(
            icon: Icons.pause_rounded,
            colorGradient: const [Color(0xFF8D582A), Color(0xFF5D3312)],
            shadowColor: const Color(0xFF3E1F08),
            borderColor: const Color(0xFFFFD54F),
            onTap: _showPauseDialog,
          ),

          const SizedBox(width: 4),

          // 6. Settings Gear Button
          _buildCircleIconButton(
            icon: Icons.settings_rounded,
            colorGradient: const [Color(0xFF42A5F5), Color(0xFF1976D2)],
            shadowColor: const Color(0xFF0D47A1),
            borderColor: const Color(0xFF90CAF9),
            onTap: () => Navigator.pushNamed(context, AppRoutes.settings),
          ),
        ],
      ),
    );
  }

  void _showPauseDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PauseDialog(
        onResume: () => Navigator.pop(context),
        onRestart: () {
          Navigator.pop(context);
          _loadLevel(currentLevelNumber);
        },
        onExit: () {
          Navigator.pop(context);
          Navigator.pop(context);
        },
      ),
    );
  }

  Widget _buildCircleIconButton({
    required IconData icon,
    required List<Color> colorGradient,
    required Color shadowColor,
    required Color borderColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: colorGradient,
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          border: Border.all(color: borderColor, width: 2.0),
          boxShadow: [
            BoxShadow(color: shadowColor, offset: const Offset(0, 3), blurRadius: 0),
            const BoxShadow(color: Colors.black26, offset: Offset(0, 3), blurRadius: 3),
          ],
        ),
        child: Center(
          child: Icon(icon, color: Colors.white, size: 20),
        ),
      ),
    );
  }

  BoxDecoration _woodenPanelDecoration() {
    return BoxDecoration(
      color: const Color(0xFFFFF9EC),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: const Color(0xFFFFD54F), width: 2.0),
      boxShadow: const [
        BoxShadow(color: Color(0xFF8D5325), offset: Offset(0, 3), blurRadius: 0),
        BoxShadow(color: Colors.black26, offset: Offset(0, 3), blurRadius: 3),
      ],
    );
  }

  Widget _buildGoalTile(BlockColor color, int amount) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: Image.asset(
            BlockColorMapper.getAssetPath(color),
            width: 24,
            height: 24,
            fit: BoxFit.contain,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          '$amount',
          style: const TextStyle(
            color: Color(0xFF3E200C),
            fontSize: 9.5,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }

  // ==========================================
  // 🪵 TITLE SIGN WITH LEVEL NUMBER
  // ==========================================
  Widget _buildTitleSign() {
    return Column(
      children: [
        // Wooden Board Sign
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 5),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF8D5325), Color(0xFF6B3C17), Color(0xFF4E2A0E)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFFFD54F), width: 2.2),
            boxShadow: const [
              BoxShadow(color: Color(0xFF2C1605), offset: Offset(0, 4), blurRadius: 0),
              BoxShadow(color: Colors.black38, offset: Offset(0, 5), blurRadius: 5),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'TILE SORT • LV. $currentLevelNumber',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.0,
                  shadows: [
                    Shadow(color: Colors.black87, offset: Offset(0, 2), blurRadius: 3),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 3),

        // Dark instruction pill
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.black.withAlpha(160),
            borderRadius: BorderRadius.circular(12),
          ),
          child: RichText(
            text: TextSpan(
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white),
              children: [
                const TextSpan(text: 'Sort the tiles by '),
                const TextSpan(
                  text: 'color!',
                  style: TextStyle(color: Color(0xFFFFD54F), fontWeight: FontWeight.w900),
                ),
                TextSpan(
                  text: '  (${currentLevel.shelfName})',
                  style: const TextStyle(color: Colors.white70, fontSize: 9.5),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ==========================================
  // 🧪 MAIN GAMEPLAY AREA: TUBES ON SHELF
  // ==========================================
  Widget _buildTubesGameplayArea() {
    final tubeWidth = tubes.length <= 4 ? 64.0 : (tubes.length == 5 ? 56.0 : 48.0);
    final tubeHeight = currentLevel.capacity == 3
        ? 210.0
        : (currentLevel.capacity == 4 ? 250.0 : 280.0);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: Column(
        children: [
          // Row of Glass Tubes
          SizedBox(
            height: tubeHeight + 40,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(tubes.length, (index) {
                return _buildGlassTube(index, tubeWidth, tubeHeight);
              }),
            ),
          ),

          // Sturdy 3D Wooden Shelf Table Base themed per tier
          _buildThemedShelf(),
        ],
      ),
    );
  }

  Widget _buildThemedShelf() {
    List<Color> shelfColors;
    Color borderColor;

    switch (currentLevel.theme) {
      case TubeTheme.potionFlask:
        shelfColors = const [Color(0xFF5D4037), Color(0xFF3E2723), Color(0xFF1B0000)];
        borderColor = const Color(0xFF81C784);
        break;
      case TubeTheme.royalEnchanted:
        shelfColors = const [Color(0xFF6A1B9A), Color(0xFF4A148C), Color(0xFF1A0033)];
        borderColor = const Color(0xFFFFD700);
        break;
      case TubeTheme.crystalClassic:
        shelfColors = const [Color(0xFFB06B32), Color(0xFF8D5325), Color(0xFF5D3512)];
        borderColor = const Color(0xFFFFD54F);
        break;
    }

    return Container(
      height: 22,
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: shelfColors,
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: borderColor, width: 1.6),
        boxShadow: const [
          BoxShadow(color: Color(0xFF2C1605), offset: Offset(0, 5), blurRadius: 0),
          BoxShadow(color: Colors.black54, offset: Offset(0, 8), blurRadius: 8),
        ],
      ),
    );
  }

  Widget _buildGlassTube(int tubeIndex, double width, double height) {
    final stack = tubes[tubeIndex];
    final isSelected = selectedTubeIndex == tubeIndex;
    final isCompleted = _completedTubes.contains(tubeIndex);
    final isShaking = _shakingTubeIndex == tubeIndex;

    BorderRadius tubeRadius;
    Color tubeBorderColor;

    switch (currentLevel.theme) {
      case TubeTheme.potionFlask:
        // Flask shaped curve
        tubeRadius = const BorderRadius.vertical(
          top: Radius.circular(8),
          bottom: Radius.circular(28),
        );
        tubeBorderColor = isCompleted
            ? const Color(0xFF69F0AE)
            : (isSelected ? const Color(0xFF64FFDA) : Colors.white.withAlpha(200));
        break;
      case TubeTheme.royalEnchanted:
        // Ornate royal curve
        tubeRadius = const BorderRadius.vertical(
          top: Radius.circular(12),
          bottom: Radius.circular(24),
        );
        tubeBorderColor = isCompleted
            ? const Color(0xFFFFD700)
            : (isSelected ? const Color(0xFFFF80AB) : const Color(0xFFE1BEE7));
        break;
      case TubeTheme.crystalClassic:
        tubeRadius = const BorderRadius.vertical(
          top: Radius.circular(10),
          bottom: Radius.circular(22),
        );
        tubeBorderColor = isCompleted
            ? const Color(0xFFFFD54F)
            : (isSelected ? const Color(0xFF64FFDA) : Colors.white.withAlpha(180));
        break;
    }

    final blockSize = (width - 10).clamp(38.0, 48.0);

    return GestureDetector(
      onTap: () => _onTubeTapped(tubeIndex),
      child: AnimatedBuilder(
        animation: _shakeController,
        builder: (context, child) {
          double offsetX = 0;
          if (isShaking) {
            offsetX = sin(_shakeController.value * pi * 4) * 6;
          }
          return Transform.translate(
            offset: Offset(offsetX, 0),
            child: child,
          );
        },
        child: Container(
          width: width,
          margin: const EdgeInsets.symmetric(horizontal: 1.5),
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.bottomCenter,
            children: [
              // Glass Vessel
              Container(
                width: width - 2,
                height: height,
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(45),
                  borderRadius: tubeRadius,
                  border: Border.all(
                    color: tubeBorderColor,
                    width: isSelected || isCompleted ? 2.8 : 2.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(60),
                      offset: const Offset(0, 4),
                      blurRadius: 6,
                    ),
                    if (isCompleted)
                      BoxShadow(
                        color: tubeBorderColor.withAlpha(140),
                        blurRadius: 12,
                        spreadRadius: 2,
                      )
                    else if (isSelected)
                      const BoxShadow(
                        color: Color(0x8864FFDA),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                  ],
                ),
                child: Stack(
                  children: [
                    // Vertical Glass Specular Highlight
                    Positioned(
                      left: 5,
                      top: 10,
                      bottom: 20,
                      child: Container(
                        width: 3.5,
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(80),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),

                    // Blocks Stack (slot 0 at bottom of tube, top-most block at top)
                    Positioned.fill(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(3, 6, 3, 8),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: List.generate(currentLevel.capacity, (index) {
                            // index 0 is the top-most slot (capacity - 1)
                            // index (capacity - 1) is the bottom-most slot (0)
                            final slotIndex = currentLevel.capacity - 1 - index;

                            if (slotIndex < stack.length) {
                              final isTopAndSelected =
                                  isSelected && slotIndex == stack.length - 1;

                              if (isTopAndSelected) {
                                return SizedBox(height: blockSize + 2);
                              }

                              return _buildBlockTile(stack[slotIndex], size: blockSize);
                            }

                            return SizedBox(height: blockSize + 2);
                          }),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Floating Selected Block
              if (isSelected && stack.isNotEmpty)
                Positioned(
                  top: -26,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: blockSize + 8,
                        height: blockSize + 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFFFFD54F).withAlpha(120),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0xFFFFD54F),
                              blurRadius: 12,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                      ),
                      _buildBlockTile(stack.last, size: blockSize, isFloating: true),
                    ],
                  ),
                ),

              // Tube Lip Top Rim
              Positioned(
                top: 0,
                child: Container(
                  width: width,
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(160),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.white, width: 1),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBlockTile(BlockColor color, {double size = 44, bool isFloating = false}) {
    return Container(
      width: size,
      height: size,
      margin: const EdgeInsets.symmetric(vertical: 1),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          if (isFloating)
            const BoxShadow(
              color: Colors.black45,
              offset: Offset(0, 6),
              blurRadius: 8,
            )
          else
            const BoxShadow(
              color: Colors.black26,
              offset: Offset(0, 2),
              blurRadius: 2,
            ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.asset(
          BlockColorMapper.getAssetPath(color),
          fit: BoxFit.contain,
        ),
      ),
    );
  }

  // ==========================================
  // 🪵 BOTTOM BOOSTER CONTROLS
  // ==========================================
  Widget _buildBottomBoostersBoard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6A1B9A), Color(0xFF4A148C), Color(0xFF311B92)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFBA68C8), width: 2.2),
        boxShadow: const [
          BoxShadow(color: Color(0xFF1A0033), offset: Offset(0, 4), blurRadius: 0),
          BoxShadow(color: Colors.black45, offset: Offset(0, 6), blurRadius: 6),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildBoosterButton(
            label: 'Undo',
            iconWidget: const Icon(Icons.undo_rounded, color: Color(0xFFFFD54F), size: 26),
            badgeCount: undoCount,
            onTap: _onUndo,
          ),
          _buildBoosterButton(
            label: 'Add Tube',
            iconWidget: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 14,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.white, width: 1.2),
                  ),
                ),
                Positioned(
                  bottom: -2,
                  right: -4,
                  child: Container(
                    padding: const EdgeInsets.all(1),
                    decoration: const BoxDecoration(
                      color: Color(0xFF4CAF50),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.add, color: Colors.white, size: 11),
                  ),
                ),
              ],
            ),
            badgeCount: addTubeCount,
            onTap: _onAddTube,
          ),
          _buildBoosterButton(
            label: 'Shuffle',
            iconWidget: const Icon(Icons.shuffle_rounded, color: Color(0xFF69F0AE), size: 26),
            badgeCount: shuffleCount,
            onTap: _onShuffle,
          ),
          _buildBoosterButton(
            label: 'Skip Level',
            iconWidget: const Icon(Icons.skip_next_rounded, color: Color(0xFF40C4FF), size: 28),
            badgeCount: skipCount,
            onTap: _onSkipLevel,
          ),
        ],
      ),
    );
  }

  Widget _buildBoosterButton({
    required String label,
    required Widget iconWidget,
    required int badgeCount,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF9C27B0), Color(0xFF7B1FA2), Color(0xFF4A148C)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE1BEE7), width: 1.8),
                  boxShadow: const [
                    BoxShadow(color: Color(0xFF1A0033), offset: Offset(0, 3), blurRadius: 0),
                    BoxShadow(color: Colors.black38, offset: Offset(0, 3), blurRadius: 4),
                  ],
                ),
                child: Center(child: iconWidget),
              ),
              Positioned(
                bottom: -4,
                right: -4,
                child: Container(
                  width: 19,
                  height: 19,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF5252), Color(0xFFD32F2F)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.2),
                    boxShadow: const [
                      BoxShadow(color: Colors.black38, offset: Offset(0, 1), blurRadius: 2),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      '$badgeCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              shadows: [
                Shadow(color: Colors.black54, offset: Offset(0, 1), blurRadius: 2),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // 💡 HINT BAR
  // ==========================================
  Widget _buildHintBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF9EC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFFD54F), width: 1.8),
        boxShadow: const [
          BoxShadow(color: Color(0xFF8D5325), offset: Offset(0, 2), blurRadius: 0),
          BoxShadow(color: Colors.black26, offset: Offset(0, 2), blurRadius: 4),
        ],
      ),
      child: const Row(
        children: [
          Icon(Icons.lightbulb_rounded, color: Color(0xFFFFB300), size: 24),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Try to sort all tiles into the same color!',
              style: TextStyle(
                color: Color(0xFF3E200C),
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // 🎉 LEVEL COMPLETE OVERLAY
  // ==========================================
  Widget _buildLevelCompleteOverlay() {
    return Container(
      color: Colors.black.withAlpha(180),
      child: Center(
        child: Container(
          width: 320,
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
          decoration: BoxDecoration(
            color: const Color(0xFF633A18),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFF8D5325), width: 5),
            boxShadow: const [
              BoxShadow(color: Color(0xFF2C1605), offset: Offset(0, 8), blurRadius: 0),
              BoxShadow(color: Colors.black54, offset: Offset(0, 12), blurRadius: 16),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Banner: LEVEL COMPLETE!
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF8CE03E), Color(0xFF439906)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFA5F062), width: 2),
                ),
                child: Text(
                  'LEVEL $currentLevelNumber COMPLETE!',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    shadows: [
                      Shadow(color: Color(0xFF1E5002), offset: Offset(0, 2), blurRadius: 3),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 14),

              // 3 Stars
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(3, (i) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4.0),
                    child: Icon(Icons.star_rounded, color: Color(0xFFFFD700), size: 40),
                  );
                }),
              ),

              const SizedBox(height: 12),

              // Score & Reward Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF9EC),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFFFD54F), width: 2),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      children: [
                        const Text(
                          'SCORE',
                          style: TextStyle(color: Color(0xFF7A4E24), fontSize: 11, fontWeight: FontWeight.w900),
                        ),
                        Text(
                          '$currentScore',
                          style: const TextStyle(color: Color(0xFF3E200C), fontSize: 18, fontWeight: FontWeight.w900),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Image.asset('assets/images/icons/icon_coin.png', width: 22, height: 22),
                        const SizedBox(width: 3),
                        const Text(
                          '+250',
                          style: TextStyle(color: Color(0xFF3E200C), fontSize: 15, fontWeight: FontWeight.w900),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Image.asset('assets/images/icons/icon_gem.png', width: 22, height: 22),
                        const SizedBox(width: 3),
                        const Text(
                          '+1',
                          style: TextStyle(color: Color(0xFF3E200C), fontSize: 15, fontWeight: FontWeight.w900),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Action Buttons: REPLAY & NEXT
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _loadLevel(currentLevelNumber),
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF42A5F5), Color(0xFF1565C0)],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFF90CAF9), width: 1.8),
                          boxShadow: const [
                            BoxShadow(color: Color(0xFF0D47A1), offset: Offset(0, 3), blurRadius: 0),
                          ],
                        ),
                        child: const Center(
                          child: Text(
                            'REPLAY',
                            style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w900),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _loadLevel(currentLevelNumber + 1),
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF8CE03E), Color(0xFF439906)],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFA5F062), width: 1.8),
                          boxShadow: const [
                            BoxShadow(color: Color(0xFF286403), offset: Offset(0, 3), blurRadius: 0),
                          ],
                        ),
                        child: const Center(
                          child: Text(
                            'NEXT LEVEL',
                            style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w900),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
