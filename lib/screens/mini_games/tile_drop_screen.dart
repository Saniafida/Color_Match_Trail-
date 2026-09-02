import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../game/blocks/block_color_mapper.dart';
import '../../game/tile_drop/tile_drop_level_model.dart';
import '../../game/tile_drop/tile_drop_level_generator.dart';
import '../../models/models.dart';
import '../../core/services/service_locator.dart';

enum _DropBooster { none, hammer, bomb, colorBomb }

class TileDropScreen extends StatefulWidget {
  final int initialLevel;

  const TileDropScreen({
    super.key,
    this.initialLevel = 1,
  });

  @override
  State<TileDropScreen> createState() => _TileDropScreenState();
}

class _TileDropScreenState extends State<TileDropScreen>
    with TickerProviderStateMixin {
  // ── Level State ─────────────────────────────
  late int currentLevelNumber;
  late TileDropLevel currentLevel;
  late List<List<BlockColor?>> grid; // [row][col], row 0 is bottom
  late int movesRemaining;
  late Map<BlockColor, int> collectedGoals;
  int currentScore = 0;
  int userCoins = 1250;

  // ── Active Shooter / Dropper ─────────────────
  int selectedCol = 0;
  late BlockColor activeTile;
  late BlockColor nextTile;
  bool isDropping = false;
  bool isProcessingCascade = false;
  int comboStreak = 0;
  String? comboText;
  Timer? _comboTimer;

  // ── Boosters ─────────────────────────────────
  _DropBooster activeBooster = _DropBooster.none;
  int hammerCount = 3;
  int bombCount = 3;
  int colorBombCount = 3;
  int shuffleCount = 2;

  // ── Overlays & Flow ──────────────────────────
  bool isGameOver = false;
  bool isLevelComplete = false;
  bool isPaused = false;

  // ── Animations ───────────────────────────────
  late AnimationController _dropAnimController;
  late Animation<double> _dropAnimation;
  int? _droppingTargetRow;
  int? _droppingCol;
  BlockColor? _droppingColor;

  late AnimationController _blastAnimController;
  late Animation<double> _blastScale;
  Set<Point<int>> _highlightedCells = {};

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  late AnimationController _confettiController;
  final List<_ParticleBurstItem> _particleBursts = [];
  final List<_ScorePopupData> _scorePopups = [];

  final Random _rng = Random();

  @override
  void initState() {
    super.initState();
    currentLevelNumber = widget.initialLevel;

    _dropAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 240),
    );
    _dropAnimation = CurvedAnimation(
      parent: _dropAnimController,
      curve: Curves.easeInQuad,
    );

    _blastAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    _blastScale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.25), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.25, end: 0.0), weight: 60),
    ]).animate(_blastAnimController);

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.92, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _confettiController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _loadLevel(currentLevelNumber);
    try {
      ServiceLocator.instance.audioManager.playMiniGamesBgm();
    } catch (_) {}
  }

  @override
  void dispose() {
    _dropAnimController.dispose();
    _blastAnimController.dispose();
    _pulseController.dispose();
    _confettiController.dispose();
    _comboTimer?.cancel();
    super.dispose();
  }

  // ─────────────────────────────────────────────
  // LEVEL INITIALIZATION
  // ─────────────────────────────────────────────

  void _loadLevel(int lvlNum) {
    currentLevelNumber = lvlNum;
    currentLevel = TileDropLevelGenerator.getLevel(lvlNum);
    movesRemaining = currentLevel.moves;
    collectedGoals = {for (var c in currentLevel.targetRequirements.keys) c: 0};
    currentScore = 0;
    comboStreak = 0;
    comboText = null;
    isGameOver = false;
    isLevelComplete = false;
    isPaused = false;
    isDropping = false;
    isProcessingCascade = false;
    activeBooster = _DropBooster.none;
    _highlightedCells.clear();
    _particleBursts.clear();
    _scorePopups.clear();

    selectedCol = currentLevel.columns ~/ 2;

    // Build grid from level initial setup or empty
    final cols = currentLevel.columns;
    final rows = currentLevel.rows;
    grid = List.generate(
      rows,
      (r) => List<BlockColor?>.filled(cols, null),
    );

    if (currentLevel.initialGrid != null) {
      for (int r = 0; r < rows && r < currentLevel.initialGrid!.length; r++) {
        for (int c = 0; c < cols && c < currentLevel.initialGrid![r].length; c++) {
          grid[r][c] = currentLevel.initialGrid![r][c];
        }
      }
    }

    activeTile = _randomLevelColor();
    nextTile = _randomLevelColor();

    setState(() {});
  }

  BlockColor _randomLevelColor() {
    final colors = currentLevel.activeColors;
    return colors[_rng.nextInt(colors.length)];
  }

  // ─────────────────────────────────────────────
  // GAMEPLAY ACTIONS: MOVE & DROP
  // ─────────────────────────────────────────────

  void _onColumnTap(int col) {
    if (isGameOver || isLevelComplete || isPaused) return;

    if (activeBooster != _DropBooster.none) {
      // Find top tile in that column or top occupied
      _handleBoosterColumnTap(col);
      return;
    }

    if (isDropping || isProcessingCascade) return;

    if (selectedCol == col) {
      // Direct drop on repeat tap
      _dropCurrentTile();
    } else {
      HapticFeedback.selectionClick();
      setState(() => selectedCol = col.clamp(0, currentLevel.columns - 1));
    }
  }

  void _onHorizontalDrag(DragUpdateDetails details, double boardWidth) {
    if (isDropping || isProcessingCascade || isGameOver || isLevelComplete || isPaused) {
      return;
    }
    final colWidth = boardWidth / currentLevel.columns;
    final newCol = (details.localPosition.dx / colWidth).floor().clamp(0, currentLevel.columns - 1);
    if (newCol != selectedCol) {
      HapticFeedback.selectionClick();
      setState(() => selectedCol = newCol);
    }
  }

  int? _getFirstAvailableRow(int col) {
    for (int r = 0; r < currentLevel.rows; r++) {
      if (grid[r][col] == null) return r;
    }
    return null; // Column is full
  }

  void _dropCurrentTile() {
    if (isDropping || isProcessingCascade || isGameOver || isLevelComplete || isPaused) {
      return;
    }

    final targetRow = _getFirstAvailableRow(selectedCol);
    if (targetRow == null) {
      // Column is full — shake/warn
      HapticFeedback.heavyImpact();
      _showWarningBanner('Column Full!');
      return;
    }

    HapticFeedback.mediumImpact();

    setState(() {
      isDropping = true;
      _droppingCol = selectedCol;
      _droppingTargetRow = targetRow;
      _droppingColor = activeTile;
    });

    _dropAnimController.forward(from: 0).then((_) {
      if (!mounted) return;

      // Settle tile into grid
      grid[targetRow][selectedCol] = _droppingColor;
      movesRemaining--;
      comboStreak = 0;

      // Spawn next tile
      activeTile = nextTile;
      nextTile = _randomLevelColor();

      setState(() {
        isDropping = false;
        _droppingTargetRow = null;
        _droppingCol = null;
        _droppingColor = null;
      });

      _processMatchesAndCascade();
    });
  }

  // ─────────────────────────────────────────────
  // MATCH DETECTION (BFS) & CASCADE ENGINE
  // ─────────────────────────────────────────────

  Future<void> _processMatchesAndCascade() async {
    if (!mounted) return;
    setState(() => isProcessingCascade = true);

    bool hasMatches = true;

    while (hasMatches && mounted) {
      final matches = _findMatches();

      if (matches.isEmpty) {
        hasMatches = false;
        break;
      }

      comboStreak++;
      if (comboStreak >= 2) {
        _triggerComboBanner(comboStreak);
      }

      // Group matches by color for audio/visual popups
      final matchedPoints = <Point<int>>{};
      for (final group in matches) {
        matchedPoints.addAll(group);
        final color = grid[group.first.x][group.first.y]!;
        final count = group.length;

        // Update goals
        if (collectedGoals.containsKey(color)) {
          collectedGoals[color] = (collectedGoals[color]! + count);
        }

        // Score bonus
        final baseScore = count * 100;
        final bonus = (count >= 5 ? 300 : (count == 4 ? 150 : 0));
        final earned = (baseScore + bonus) * comboStreak;
        currentScore += earned;

        // Spawn score popup at center of group
        final centerRow = group.fold(0, (s, p) => s + p.x) / group.length;
        final centerCol = group.fold(0, (s, p) => s + p.y) / group.length;
        _addScorePopup(centerRow, centerCol, '+$earned');
      }

      // 1. Highlight phase
      HapticFeedback.lightImpact();
      setState(() {
        _highlightedCells = matchedPoints;
      });
      await _blastAnimController.forward(from: 0);

      // 2. Spawn particles
      for (final p in matchedPoints) {
        final color = grid[p.x][p.y];
        if (color != null) {
          _spawnParticlesAt(p.x, p.y, color);
        }
      }

      // 3. Clear matched cells
      for (final p in matchedPoints) {
        grid[p.x][p.y] = null;
      }
      setState(() {
        _highlightedCells = {};
      });

      await Future.delayed(const Duration(milliseconds: 90));

      // 4. Apply Gravity (tiles fall down into empty cells)
      _applyGravity();
      setState(() {});
      await Future.delayed(const Duration(milliseconds: 180));
    }

    if (!mounted) return;

    setState(() => isProcessingCascade = false);

    // ── Check Win / Loss Condition ──────────────
    _checkGameEndState();
  }

  List<List<Point<int>>> _findMatches() {
    final rows = currentLevel.rows;
    final cols = currentLevel.columns;
    final visited = List.generate(rows, (_) => List<bool>.filled(cols, false));
    final List<List<Point<int>>> matchGroups = [];

    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        final color = grid[r][c];
        if (color == null || visited[r][c]) continue;

        // Flood-fill (BFS) connected same-color tiles (orthogonal)
        final group = <Point<int>>[];
        final queue = <Point<int>>[Point(r, c)];
        visited[r][c] = true;

        while (queue.isNotEmpty) {
          final curr = queue.removeAt(0);
          group.add(curr);

          final neighbors = [
            Point(curr.x + 1, curr.y),
            Point(curr.x - 1, curr.y),
            Point(curr.x, curr.y + 1),
            Point(curr.x, curr.y - 1),
          ];

          for (final n in neighbors) {
            if (n.x >= 0 && n.x < rows && n.y >= 0 && n.y < cols) {
              if (!visited[n.x][n.y] && grid[n.x][n.y] == color) {
                visited[n.x][n.y] = true;
                queue.add(n);
              }
            }
          }
        }

        // 3 or more connected -> Valid match
        if (group.length >= 3) {
          matchGroups.add(group);
        }
      }
    }

    return matchGroups;
  }

  void _applyGravity() {
    final rows = currentLevel.rows;
    final cols = currentLevel.columns;

    for (int c = 0; c < cols; c++) {
      int writeRow = 0;
      for (int r = 0; r < rows; r++) {
        if (grid[r][c] != null) {
          if (writeRow != r) {
            grid[writeRow][c] = grid[r][c];
            grid[r][c] = null;
          }
          writeRow++;
        }
      }
    }
  }

  void _checkGameEndState() {
    // 1. Check Win
    bool allGoalsMet = true;
    for (final entry in currentLevel.targetRequirements.entries) {
      final collected = collectedGoals[entry.key] ?? 0;
      if (collected < entry.value) {
        allGoalsMet = false;
        break;
      }
    }

    if (allGoalsMet) {
      _triggerWin();
      return;
    }

    // 2. Check Game Over: Moves exhausted
    if (movesRemaining <= 0) {
      _triggerGameOver();
      return;
    }

    // 3. Check Game Over: Board overflowed (top danger row blocked across all cols)
    bool hasAnyAvailableCol = false;
    for (int c = 0; c < currentLevel.columns; c++) {
      if (_getFirstAvailableRow(c) != null) {
        hasAnyAvailableCol = true;
        break;
      }
    }
    if (!hasAnyAvailableCol) {
      _triggerGameOver();
    }
  }

  void _triggerWin() {
    HapticFeedback.heavyImpact();
    setState(() => isLevelComplete = true);
    _confettiController.forward(from: 0);
    try {
      ServiceLocator.instance.coinManager.addCoins(250);
      ServiceLocator.instance.gemManager.addGems(1);
    } catch (_) {}
  }

  void _triggerGameOver() {
    HapticFeedback.heavyImpact();
    setState(() => isGameOver = true);
  }

  void _triggerComboBanner(int streak) {
    _comboTimer?.cancel();
    final text = (streak >= 4)
        ? 'MEGA COMBO! ×$streak'
        : (streak == 3 ? 'SUPER COMBO ×3' : 'COMBO ×2!');
    setState(() => comboText = text);
    _comboTimer = Timer(const Duration(milliseconds: 1100), () {
      if (mounted) setState(() => comboText = null);
    });
  }

  void _showWarningBanner(String msg) {
    _comboTimer?.cancel();
    setState(() => comboText = msg);
    _comboTimer = Timer(const Duration(milliseconds: 800), () {
      if (mounted) setState(() => comboText = null);
    });
  }

  // ─────────────────────────────────────────────
  // BOOSTERS LOGIC
  // ─────────────────────────────────────────────

  void _onSelectBooster(_DropBooster booster) {
    if (isDropping || isProcessingCascade || isGameOver || isLevelComplete) return;

    if (activeBooster == booster) {
      setState(() => activeBooster = _DropBooster.none);
      return;
    }

    setState(() => activeBooster = booster);
  }

  void _handleBoosterColumnTap(int col) {
    // Find highest occupied row in this column or target
    int targetRow = -1;
    for (int r = currentLevel.rows - 1; r >= 0; r--) {
      if (grid[r][col] != null) {
        targetRow = r;
        break;
      }
    }

    if (targetRow == -1 && activeBooster != _DropBooster.bomb) {
      // Empty column
      return;
    }

    _applyBoosterAt(targetRow >= 0 ? targetRow : 0, col);
  }

  void _applyBoosterAt(int r, int c) {
    if (activeBooster == _DropBooster.hammer) {
      if (hammerCount <= 0 || grid[r][c] == null) return;
      hammerCount--;
      final color = grid[r][c]!;
      _spawnParticlesAt(r, c, color);
      grid[r][c] = null;
      if (collectedGoals.containsKey(color)) {
        collectedGoals[color] = collectedGoals[color]! + 1;
      }
      activeBooster = _DropBooster.none;
      _applyGravity();
      setState(() {});
      _processMatchesAndCascade();
    } else if (activeBooster == _DropBooster.bomb) {
      if (bombCount <= 0) return;
      bombCount--;
      // Blast 3x3 surrounding cells
      for (int dr = -1; dr <= 1; dr++) {
        for (int dc = -1; dc <= 1; dc++) {
          final nr = r + dr;
          final nc = c + dc;
          if (nr >= 0 && nr < currentLevel.rows && nc >= 0 && nc < currentLevel.columns) {
            final col = grid[nr][nc];
            if (col != null) {
              _spawnParticlesAt(nr, nc, col);
              grid[nr][nc] = null;
              if (collectedGoals.containsKey(col)) {
                collectedGoals[col] = collectedGoals[col]! + 1;
              }
            }
          }
        }
      }
      activeBooster = _DropBooster.none;
      _applyGravity();
      setState(() {});
      _processMatchesAndCascade();
    } else if (activeBooster == _DropBooster.colorBomb) {
      if (colorBombCount <= 0 || grid[r][c] == null) return;
      colorBombCount--;
      final targetColor = grid[r][c]!;
      for (int row = 0; row < currentLevel.rows; row++) {
        for (int col = 0; col < currentLevel.columns; col++) {
          if (grid[row][col] == targetColor) {
            _spawnParticlesAt(row, col, targetColor);
            grid[row][col] = null;
            if (collectedGoals.containsKey(targetColor)) {
              collectedGoals[targetColor] = collectedGoals[targetColor]! + 1;
            }
          }
        }
      }
      activeBooster = _DropBooster.none;
      _applyGravity();
      setState(() {});
      _processMatchesAndCascade();
    }
  }

  void _onUseShuffle() {
    if (shuffleCount <= 0 || isDropping || isProcessingCascade) return;
    shuffleCount--;
    final allTiles = <BlockColor>[];
    for (int r = 0; r < currentLevel.rows; r++) {
      for (int c = 0; c < currentLevel.columns; c++) {
        if (grid[r][c] != null) allTiles.add(grid[r][c]!);
      }
    }
    allTiles.shuffle(_rng);

    int idx = 0;
    for (int r = 0; r < currentLevel.rows; r++) {
      for (int c = 0; c < currentLevel.columns; c++) {
        if (grid[r][c] != null) {
          grid[r][c] = allTiles[idx++];
        }
      }
    }

    HapticFeedback.mediumImpact();
    setState(() {});
    _processMatchesAndCascade();
  }

  // ─────────────────────────────────────────────
  // PARTICLE SYSTEM
  // ─────────────────────────────────────────────

  void _spawnParticlesAt(int row, int col, BlockColor color) {
    final burstId = '${DateTime.now().microsecondsSinceEpoch}_${row}_$col';
    _particleBursts.add(_ParticleBurstItem(
      id: burstId,
      gridRow: row,
      gridCol: col,
      color: color,
    ));
    setState(() {});
  }

  void _addScorePopup(double row, double col, String text) {
    final popupId = '${DateTime.now().microsecondsSinceEpoch}_${row.toInt()}_${col.toInt()}';
    _scorePopups.add(_ScorePopupData(
      id: popupId,
      row: row,
      col: col,
      text: text,
    ));
    setState(() {});
  }

  // ─────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── 1. Garden Background ──────────────────────────────────────────
          Image.asset(
            'assets/images/backgrounds/bg_garden.jpg',
            fit: BoxFit.cover,
          ),

          // ── 2. Dimming & Vignette Overlay ─────────────────────────────────
          Container(color: Colors.black.withValues(alpha: 0.15)),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.black.withValues(alpha: 0.25),
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.35),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),

          // ── 3. Main Gameplay Column ───────────────────────────────────────
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 2),
                _buildTopBar(),
                const SizedBox(height: 2),
                _buildGoalAndMovesRow(),
                const SizedBox(height: 2),

                // Active Shooter Dispenser + Board
                Expanded(
                  child: Center(
                    child: _buildBoardArea(),
                  ),
                ),

                const SizedBox(height: 2),
                _buildBottomBoostersBar(),
                const SizedBox(height: 4),
              ],
            ),
          ),

          // ── Floating Combo & Booster Notification Banners ─────────────────
          if (comboText != null)
            Positioned(
              top: 110,
              left: 0,
              right: 0,
              child: IgnorePointer(
                child: Center(child: _buildComboBanner()),
              ),
            ),
          if (activeBooster != _DropBooster.none)
            Positioned(
              bottom: 68,
              left: 0,
              right: 0,
              child: Center(child: _buildBoosterActiveBanner()),
            ),

          // ── 4. Overlays (Win / Loss / Pause) ──────────────────────────────
          if (isGameOver) _buildGameOverOverlay(),
          if (isLevelComplete) _buildLevelCompleteOverlay(),
          if (isPaused) _buildPauseOverlay(),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // TOP BAR & HEADER
  // ─────────────────────────────────────────────

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 1. Back Button
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFF42A5F5), Color(0xFF1E88E5), Color(0xFF0D47A1)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                border: Border.all(color: const Color(0xFFE3F2FD), width: 1.6),
                boxShadow: const [
                  BoxShadow(color: Color(0xFF072658), offset: Offset(0, 2), blurRadius: 0),
                  BoxShadow(color: Colors.black38, offset: Offset(0, 2), blurRadius: 3),
                ],
              ),
              child: const Center(
                child: Icon(Icons.arrow_back_rounded, color: Colors.white, size: 19),
              ),
            ),
          ),

          const SizedBox(width: 6),

          // Coins Pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF8D5325), Color(0xFF5D3312)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFFFD54F), width: 1.6),
              boxShadow: const [
                BoxShadow(color: Colors.black45, offset: Offset(0, 2), blurRadius: 4),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset('assets/images/icons/icon_coin.png', width: 20, height: 20),
                const SizedBox(width: 4),
                Text(
                  '$userCoins',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                    shadows: [
                      Shadow(color: Colors.black54, offset: Offset(0, 1), blurRadius: 2),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 6),

          // Wooden Header Crest "TILE DROP"
          Expanded(
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF8D5325), Color(0xFF5D3512)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFFFD54F), width: 2.0),
                    boxShadow: const [
                      BoxShadow(color: Color(0xFF2C1605), offset: Offset(0, 3), blurRadius: 0),
                      BoxShadow(color: Colors.black45, offset: Offset(0, 3), blurRadius: 4),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.local_florist, color: Color(0xFFFF80AB), size: 14),
                      const SizedBox(width: 5),
                      Text(
                        'TILE DROP  •  LVL $currentLevelNumber',
                        style: const TextStyle(
                          color: Color(0xFFFFD54F),
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.6,
                          shadows: [
                            Shadow(color: Color(0xFF3E200C), offset: Offset(0, 2), blurRadius: 2),
                          ],
                        ),
                      ),
                      const SizedBox(width: 5),
                      const Icon(Icons.local_florist, color: Color(0xFFFF80AB), size: 14),
                    ],
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(width: 6),

          // Pause Button
          GestureDetector(
            onTap: () => setState(() => isPaused = true),
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF8D5325), Color(0xFF5D3312)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFFFD54F), width: 1.6),
                boxShadow: const [
                  BoxShadow(color: Colors.black45, offset: Offset(0, 2), blurRadius: 3),
                ],
              ),
              child: const Icon(Icons.pause_rounded, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // GOAL & MOVES ROW
  // ─────────────────────────────────────────────

  Widget _buildGoalAndMovesRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Row(
        children: [
          // Moves Counter Box (Warm Mahogany Wood)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF8D5325), Color(0xFF5D3312)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFFFD54F), width: 1.8),
              boxShadow: const [
                BoxShadow(color: Color(0xFF2C1605), offset: Offset(0, 2), blurRadius: 0),
                BoxShadow(color: Colors.black38, offset: Offset(0, 3), blurRadius: 4),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'MOVES',
                  style: TextStyle(
                    color: Color(0xFFFFE082),
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  '$movesRemaining',
                  style: TextStyle(
                    color: movesRemaining <= 5 ? const Color(0xFFFF5252) : Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    shadows: const [
                      Shadow(color: Colors.black87, offset: Offset(0, 2), blurRadius: 3),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 6),

          // Goals Card Box (Warm Creamy Parchment with Wood Trim)
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFF9EC), Color(0xFFFBE9D0)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFC78F4E), width: 1.8),
                boxShadow: const [
                  BoxShadow(color: Color(0xFF4E2C0C), offset: Offset(0, 2), blurRadius: 0),
                  BoxShadow(color: Colors.black26, offset: Offset(0, 3), blurRadius: 4),
                ],
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.center,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: currentLevel.targetRequirements.entries.map((entry) {
                    final target = entry.value;
                    final collected = (collectedGoals[entry.key] ?? 0).clamp(0, target);
                    final isDone = collected >= target;

                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Image.asset(
                            BlockColorMapper.getAssetPath(entry.key),
                            width: 22,
                            height: 22,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isDone ? '✓' : '$collected/$target',
                            style: TextStyle(
                              color: isDone ? const Color(0xFF2E7D32) : const Color(0xFF3E200C),
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // GAMEPLAY BOARD AREA + SHOOTER
  // ─────────────────────────────────────────────

  Widget _buildBoardArea() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cols = currentLevel.columns;
        final rows = currentLevel.rows;

        // Dynamic height & sizing allocation
        const shooterHeight = 48.0;
        const spacing = 4.0;
        const boardBorderWidth = 2.5;
        const boardPadding = 4.0;
        const horizontalInset = (boardPadding + boardBorderWidth) * 2; // 13.0
        const verticalInset = (boardPadding + boardBorderWidth) * 2;   // 13.0

        final maxW = constraints.maxWidth - 16;
        final maxH = constraints.maxHeight - shooterHeight - spacing - 8;

        final cellW = (maxW - horizontalInset) / cols;
        final cellH = (maxH - verticalInset) / rows;
        final cellSize = min(cellW, cellH).clamp(20.0, 52.0);

        final innerBoardWidth = cellSize * cols;
        final innerBoardHeight = cellSize * rows;
        final boardWidth = innerBoardWidth + horizontalInset;
        final boardHeight = innerBoardHeight + verticalInset;

        return SizedBox(
          width: boardWidth,
          height: boardHeight + shooterHeight + spacing,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Active Dropper / Shooter Top Pod ─────────────────────────
              SizedBox(
                height: shooterHeight,
                width: boardWidth,
                child: _buildShooterPod(boardWidth, cellSize, horizontalInset),
              ),

              const SizedBox(height: spacing),

              // ── Central Grid Board ───────────────────────────────────────
              SizedBox(
                width: boardWidth,
                height: boardHeight,
                child: GestureDetector(
                  onHorizontalDragUpdate: (details) =>
                      _onHorizontalDrag(details, boardWidth),
                  child: Container(
                    width: boardWidth,
                    height: boardHeight,
                    padding: const EdgeInsets.all(boardPadding),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF42240E).withValues(alpha: 0.95),
                          const Color(0xFF2C1607).withValues(alpha: 0.97),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFFD49755),
                        width: boardBorderWidth,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFFD54F).withValues(alpha: 0.30),
                          blurRadius: 10,
                          spreadRadius: 1,
                        ),
                        const BoxShadow(
                          color: Colors.black54,
                          offset: Offset(0, 6),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: SizedBox(
                      width: innerBoardWidth,
                      height: innerBoardHeight,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          // Grid background cells
                          _buildGridCells(cellSize, cols, rows),

                          // Drop preview ghost & downward light trail
                          if (!isDropping && !isProcessingCascade)
                            _buildDropPreview(cellSize, cols, rows),

                          // Animated Dropping Tile
                          if (isDropping && _droppingCol != null && _droppingTargetRow != null)
                            _buildAnimatedDroppingTile(cellSize, rows),

                          // Blasting particles
                          ..._buildParticlesLayer(cellSize, rows),

                          // Score Popups
                          ..._buildScorePopupsLayer(cellSize, rows),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ─────────────────────────────────────────────
  // SHOOTER POD (Top Slider)
  // ─────────────────────────────────────────────

  Widget _buildShooterPod(double boardWidth, double cellSize, double horizontalInset) {
    final podWidth = max(cellSize, 34.0) + 4;
    final startX = horizontalInset / 2.0;
    final shooterX = startX + selectedCol * cellSize + (cellSize - podWidth) / 2.0;

    return Stack(
      alignment: Alignment.centerLeft,
      children: [
        // Track background line (Golden Brass Track)
        Positioned(
          left: 8,
          right: 8,
          top: 20,
          child: Container(
            height: 5,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF8D5325), Color(0xFFC78F4E), Color(0xFF8D5325)],
              ),
              borderRadius: BorderRadius.circular(2.5),
              border: Border.all(color: const Color(0xFFFFD54F), width: 1.0),
              boxShadow: const [
                BoxShadow(color: Colors.black26, offset: Offset(0, 1), blurRadius: 2),
              ],
            ),
          ),
        ),

        // Upcoming Next Tile Badge (Right Corner)
        Positioned(
          right: 0,
          top: 4,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF8D5325), Color(0xFF5D3312)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFFFD54F), width: 1.2),
              boxShadow: const [
                BoxShadow(color: Color(0xFF2C1605), offset: Offset(0, 2), blurRadius: 0),
                BoxShadow(color: Colors.black26, offset: Offset(0, 2), blurRadius: 3),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'NEXT',
                  style: TextStyle(
                    color: Color(0xFFFFE082),
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(width: 3),
                Image.asset(
                  BlockColorMapper.getAssetPath(nextTile),
                  width: 16,
                  height: 16,
                ),
              ],
            ),
          ),
        ),

        // Sliding Active Tile Holder
        AnimatedPositioned(
          duration: const Duration(milliseconds: 90),
          curve: Curves.easeOut,
          left: shooterX,
          top: 0,
          child: GestureDetector(
            onTap: _dropCurrentTile,
            child: ScaleTransition(
              scale: _pulseAnimation,
              child: Container(
                width: podWidth,
                height: 46,
                padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF8D5325), Color(0xFF5D3312)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFFFD54F), width: 1.8),
                  boxShadow: [
                    BoxShadow(
                      color: BlockColorMapper.getStyle(activeTile).glow.withValues(alpha: 0.6),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        BlockColorMapper.getAssetPath(activeTile),
                        width: 26,
                        height: 26,
                        fit: BoxFit.contain,
                      ),
                      const Icon(
                        Icons.arrow_drop_down_rounded,
                        color: Color(0xFFFFD54F),
                        size: 14,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────
  // GRID CELLS & TILES
  // ─────────────────────────────────────────────

  Widget _buildGridCells(double cellSize, int cols, int rows) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(rows, (gridR) {
        // gridR 0 is displayed at bottom -> matrix row index = (rows - 1 - gridR)
        final rowIdx = rows - 1 - gridR;
        final isDangerRow = (rowIdx == rows - 1);

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(cols, (colIdx) {
            final color = grid[rowIdx][colIdx];
            final isHighlighted = _highlightedCells.contains(Point(rowIdx, colIdx));

            return GestureDetector(
              onTap: () => _onColumnTap(colIdx),
              child: Container(
                width: cellSize,
                height: cellSize,
                decoration: BoxDecoration(
                  color: isDangerRow
                      ? const Color(0xFF5C1C1C).withValues(alpha: 0.85)
                      : const Color(0xFF221105).withValues(alpha: 0.75),
                  border: Border.all(
                    color: isDangerRow
                        ? const Color(0xFFFF5252).withValues(alpha: 0.50)
                        : const Color(0xFF533118).withValues(alpha: 0.50),
                    width: 0.5,
                  ),
                ),
                child: color != null
                    ? _buildPlacedTile(color, cellSize, isHighlighted)
                    : (isDangerRow
                        ? Center(
                            child: Text(
                              '•',
                              style: TextStyle(
                                color: const Color(0xFFFF8A80).withValues(alpha: 0.75),
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          )
                        : null),
              ),
            );
          }),
        );
      }),
    );
  }

  Widget _buildPlacedTile(BlockColor color, double cellSize, bool isHighlighted) {
    final style = BlockColorMapper.getStyle(color);

    return ScaleTransition(
      scale: isHighlighted ? _blastScale : const AlwaysStoppedAnimation(1.0),
      child: Container(
        padding: EdgeInsets.zero,
        decoration: isHighlighted
            ? BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: Colors.white,
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                  BoxShadow(
                    color: style.glow.withValues(alpha: 0.8),
                    blurRadius: 12,
                    spreadRadius: 3,
                  ),
                ],
              )
            : null,
        child: Image.asset(
          BlockColorMapper.getAssetPath(color),
          fit: BoxFit.contain,
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // DROP PREVIEW (Ghost & Light Arrow)
  // ─────────────────────────────────────────────

  Widget _buildDropPreview(double cellSize, int cols, int rows) {
    final targetRow = _getFirstAvailableRow(selectedCol);
    if (targetRow == null) return const SizedBox.shrink();

    // Visual row index (0 = bottom, rows - 1 = top)
    final visualRow = rows - 1 - targetRow;
    final topOffset = visualRow * cellSize;
    final leftOffset = selectedCol * cellSize;

    return Positioned(
      left: leftOffset,
      top: topOffset,
      child: IgnorePointer(
        child: Container(
          width: cellSize,
          height: cellSize,
          decoration: BoxDecoration(
            border: Border.all(
              color: BlockColorMapper.getStyle(activeTile).highlight,
              width: 1.8,
            ),
            boxShadow: [
              BoxShadow(
                color: BlockColorMapper.getStyle(activeTile).glow.withValues(alpha: 0.4),
                blurRadius: 6,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Opacity(
            opacity: 0.45,
            child: Image.asset(
              BlockColorMapper.getAssetPath(activeTile),
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // ANIMATED DROPPING TILE
  // ─────────────────────────────────────────────

  Widget _buildAnimatedDroppingTile(double cellSize, int rows) {
    final visualRow = rows - 1 - _droppingTargetRow!;
    final targetTop = visualRow * cellSize;
    final leftOffset = _droppingCol! * cellSize;

    return AnimatedBuilder(
      animation: _dropAnimation,
      builder: (context, _) {
        final currentTop = -30.0 + _dropAnimation.value * (targetTop + 30.0);

        return Positioned(
          left: leftOffset,
          top: currentTop,
          child: IgnorePointer(
            child: Container(
              width: cellSize,
              height: cellSize,
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: BlockColorMapper.getStyle(_droppingColor!).glow.withValues(alpha: 0.7),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Image.asset(
                BlockColorMapper.getAssetPath(_droppingColor!),
                fit: BoxFit.contain,
              ),
            ),
          ),
        );
      },
    );
  }

  // ─────────────────────────────────────────────
  // PARTICLES & SCORE POPUPS
  // ─────────────────────────────────────────────

  List<Widget> _buildParticlesLayer(double cellSize, int rows) {
    return _particleBursts.map((burst) {
      return _ParticleBurstWidget(
        key: ValueKey(burst.id),
        gridRow: burst.gridRow,
        gridCol: burst.gridCol,
        color: burst.color,
        cellSize: cellSize,
        totalRows: rows,
        onComplete: () {
          if (mounted) {
            setState(() {
              _particleBursts.removeWhere((b) => b.id == burst.id);
            });
          }
        },
      );
    }).toList();
  }

  List<Widget> _buildScorePopupsLayer(double cellSize, int rows) {
    return _scorePopups.map((popup) {
      return _ScorePopupWidget(
        key: ValueKey(popup.id),
        row: popup.row,
        col: popup.col,
        text: popup.text,
        cellSize: cellSize,
        totalRows: rows,
        onComplete: () {
          if (mounted) {
            setState(() {
              _scorePopups.removeWhere((p) => p.id == popup.id);
            });
          }
        },
      );
    }).toList();
  }

  // ─────────────────────────────────────────────
  // COMBO & BOOSTER BANNERS
  // ─────────────────────────────────────────────

  Widget _buildComboBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFD54F), Color(0xFFFF6D00)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white, width: 1.8),
        boxShadow: const [
          BoxShadow(color: Color(0xFFBF360C), offset: Offset(0, 3), blurRadius: 0),
        ],
      ),
      child: Text(
        comboText!,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 15,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.8,
          shadows: [
            Shadow(color: Colors.black54, offset: Offset(0, 2), blurRadius: 3),
          ],
        ),
      ),
    );
  }

  Widget _buildBoosterActiveBanner() {
    String name = 'Booster';
    if (activeBooster == _DropBooster.hammer) name = 'Hammer (Smash 1 Tile)';
    if (activeBooster == _DropBooster.bomb) name = 'Bomb (Blast 3×3 Area)';
    if (activeBooster == _DropBooster.colorBomb) name = 'Color Bomb (Clear Color)';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFF6A1B9A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE1BEE7), width: 1.4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.touch_app, color: Colors.white, size: 14),
          const SizedBox(width: 4),
          Text(
            'Tap tile to use $name  •  Tap to Cancel',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // BOTTOM BOOSTERS BAR
  // ─────────────────────────────────────────────

  Widget _buildBottomBoostersBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF42240E).withValues(alpha: 0.94),
            const Color(0xFF2C1607).withValues(alpha: 0.96),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFD49755), width: 2.0),
        boxShadow: const [
          BoxShadow(color: Color(0xFF1E0D03), offset: Offset(0, 3), blurRadius: 0),
          BoxShadow(color: Colors.black45, offset: Offset(0, 5), blurRadius: 6),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildBoosterItem(
            assetPath: 'assets/images/boosters/hammer.png',
            count: hammerCount,
            isSelected: activeBooster == _DropBooster.hammer,
            onTap: () => _onSelectBooster(_DropBooster.hammer),
          ),
          _buildBoosterItem(
            assetPath: 'assets/images/boosters/bomb.png',
            count: bombCount,
            isSelected: activeBooster == _DropBooster.bomb,
            onTap: () => _onSelectBooster(_DropBooster.bomb),
          ),
          _buildBoosterItem(
            assetPath: 'assets/images/boosters/color_bomb.png',
            count: colorBombCount,
            isSelected: activeBooster == _DropBooster.colorBomb,
            onTap: () => _onSelectBooster(_DropBooster.colorBomb),
          ),
          _buildBoosterItem(
            assetPath: 'assets/images/boosters/shuffle.png',
            count: shuffleCount,
            isSelected: false,
            onTap: _onUseShuffle,
          ),
        ],
      ),
    );
  }

  Widget _buildBoosterItem({
    required String assetPath,
    required int count,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final disabled = count <= 0;

    return GestureDetector(
      onTap: disabled ? null : onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFFFD54F).withValues(alpha: 0.45)
              : const Color(0xFF8D5325).withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFFE65100) : const Color(0xFFC78F4E),
            width: isSelected ? 2.0 : 1.2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFFFFB300).withValues(alpha: 0.6),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Opacity(
              opacity: disabled ? 0.4 : 1.0,
              child: Image.asset(assetPath, width: 34, height: 34),
            ),
            Positioned(
              right: 2,
              bottom: 2,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: const Color(0xFF43A047),
                  borderRadius: BorderRadius.circular(6),
                  boxShadow: const [
                    BoxShadow(color: Colors.black26, offset: Offset(0, 1), blurRadius: 1),
                  ],
                ),
                child: Text(
                  '$count',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // WIN / GAME OVER / PAUSE OVERLAYS
  // ─────────────────────────────────────────────

  Widget _buildLevelCompleteOverlay() {
    return Container(
      color: Colors.black.withValues(alpha: 0.75),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Container(
              width: 290,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFF3E0), Color(0xFFFFE0B2)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFFFB300), width: 3.0),
                boxShadow: const [
                  BoxShadow(color: Colors.black54, offset: Offset(0, 8), blurRadius: 16),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'LEVEL COMPLETE!',
                    style: TextStyle(
                      color: Color(0xFFE65100),
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      shadows: [
                        Shadow(color: Color(0xFFFFCC80), offset: Offset(0, 2), blurRadius: 2),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),

                  // 3 Stars
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(3, (i) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4),
                        child: Icon(Icons.star_rounded, color: Color(0xFFFFD700), size: 40),
                      );
                    }),
                  ),
                  const SizedBox(height: 12),

                  // Score & Reward Box
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF9EC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFFFD54F), width: 1.6),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Column(
                          children: [
                            const Text('SCORE', style: TextStyle(color: Color(0xFF7A4E24), fontSize: 10, fontWeight: FontWeight.w900)),
                            Text('$currentScore', style: const TextStyle(color: Color(0xFF3E200C), fontSize: 16, fontWeight: FontWeight.w900)),
                          ],
                        ),
                        Row(
                          children: [
                            Image.asset('assets/images/icons/icon_coin.png', width: 20, height: 20),
                            const SizedBox(width: 3),
                            const Text('+250', style: TextStyle(color: Color(0xFF3E200C), fontSize: 14, fontWeight: FontWeight.w900)),
                          ],
                        ),
                        Row(
                          children: [
                            Image.asset('assets/images/icons/icon_gem.png', width: 20, height: 20),
                            const SizedBox(width: 3),
                            const Text('+1', style: TextStyle(color: Color(0xFF3E200C), fontSize: 14, fontWeight: FontWeight.w900)),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Buttons
                  Row(
                    children: [
                      Expanded(
                        child: _buildDialogButton(
                          label: 'REPLAY',
                          colors: [const Color(0xFF42A5F5), const Color(0xFF1565C0)],
                          borderColor: const Color(0xFF90CAF9),
                          shadowColor: const Color(0xFF0D47A1),
                          onTap: () => _loadLevel(currentLevelNumber),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildDialogButton(
                          label: 'NEXT',
                          colors: [const Color(0xFF8CE03E), const Color(0xFF439906)],
                          borderColor: const Color(0xFFA5F062),
                          shadowColor: const Color(0xFF286403),
                          onTap: () => _loadLevel(currentLevelNumber + 1),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGameOverOverlay() {
    return Container(
      color: Colors.black.withValues(alpha: 0.75),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Container(
              width: 280,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFECEFF1), Color(0xFFCFD8DC)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFB0BEC5), width: 3.0),
                boxShadow: const [
                  BoxShadow(color: Colors.black54, offset: Offset(0, 8), blurRadius: 16),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'GAME OVER',
                    style: TextStyle(
                      color: Color(0xFFC62828),
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'No moves remaining or board blocked!',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Color(0xFF455A64), fontSize: 12),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildDialogButton(
                          label: 'HOME',
                          colors: [const Color(0xFF78909C), const Color(0xFF455A64)],
                          borderColor: const Color(0xFFB0BEC5),
                          shadowColor: const Color(0xFF263238),
                          onTap: () => Navigator.pop(context),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildDialogButton(
                          label: 'RETRY',
                          colors: [const Color(0xFFFF9800), const Color(0xFFE65100)],
                          borderColor: const Color(0xFFFFCC80),
                          shadowColor: const Color(0xFFBF360C),
                          onTap: () => _loadLevel(currentLevelNumber),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPauseOverlay() {
    return Container(
      color: Colors.black.withValues(alpha: 0.70),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Container(
              width: 260,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF8D5325), Color(0xFF5D3312)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: const Color(0xFFFFD54F), width: 2.5),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'PAUSED',
                    style: TextStyle(
                      color: Color(0xFFFFD54F),
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildDialogButton(
                    label: 'RESUME',
                    colors: [const Color(0xFF8CE03E), const Color(0xFF439906)],
                    borderColor: const Color(0xFFA5F062),
                    shadowColor: const Color(0xFF286403),
                    onTap: () => setState(() => isPaused = false),
                  ),
                  const SizedBox(height: 8),
                  _buildDialogButton(
                    label: 'RESTART',
                    colors: [const Color(0xFF42A5F5), const Color(0xFF1565C0)],
                    borderColor: const Color(0xFF90CAF9),
                    shadowColor: const Color(0xFF0D47A1),
                    onTap: () => _loadLevel(currentLevelNumber),
                  ),
                  const SizedBox(height: 8),
                  _buildDialogButton(
                    label: 'QUIT',
                    colors: [const Color(0xFFE53935), const Color(0xFFB71C1C)],
                    borderColor: const Color(0xFFEF9A9A),
                    shadowColor: const Color(0xFF7F0000),
                    onTap: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDialogButton({
    required String label,
    required List<Color> colors,
    required Color borderColor,
    required Color shadowColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: colors,
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor, width: 1.6),
          boxShadow: [
            BoxShadow(color: shadowColor, offset: const Offset(0, 3), blurRadius: 0),
          ],
        ),
        child: Center(
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w900,
              shadows: [
                Shadow(color: Colors.black38, offset: Offset(0, 1), blurRadius: 2),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// ANIMATED PARTICLES & SCORE POPUP WIDGETS
// ─────────────────────────────────────────────

class _ParticleBurstItem {
  final String id;
  final int gridRow;
  final int gridCol;
  final BlockColor color;

  _ParticleBurstItem({
    required this.id,
    required this.gridRow,
    required this.gridCol,
    required this.color,
  });
}

class _ScorePopupData {
  final String id;
  final double row;
  final double col;
  final String text;

  _ScorePopupData({
    required this.id,
    required this.row,
    required this.col,
    required this.text,
  });
}

class _ParticleBurstWidget extends StatefulWidget {
  final int gridRow;
  final int gridCol;
  final BlockColor color;
  final double cellSize;
  final int totalRows;
  final VoidCallback onComplete;

  const _ParticleBurstWidget({
    super.key,
    required this.gridRow,
    required this.gridCol,
    required this.color,
    required this.cellSize,
    required this.totalRows,
    required this.onComplete,
  });

  @override
  State<_ParticleBurstWidget> createState() => _ParticleBurstWidgetState();
}

class _ParticleBurstWidgetState extends State<_ParticleBurstWidget> {
  late final List<_SparkleParticle> _sparkles;
  static final Random _rnd = Random();

  @override
  void initState() {
    super.initState();
    final style = BlockColorMapper.getStyle(widget.color);
    _sparkles = List.generate(12, (i) {
      final angle = _rnd.nextDouble() * 2 * pi;
      final speed = 25.0 + _rnd.nextDouble() * 60.0;
      return _SparkleParticle(
        vx: cos(angle) * speed,
        vy: sin(angle) * speed,
        size: 3.5 + _rnd.nextDouble() * 4.5,
        color: i % 2 == 0 ? style.glow : style.highlight,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final visualRow = widget.totalRows - 1 - widget.gridRow;
    final centerX = widget.gridCol * widget.cellSize + widget.cellSize / 2.0;
    final centerY = visualRow * widget.cellSize + widget.cellSize / 2.0;

    return Positioned(
      left: centerX,
      top: centerY,
      child: IgnorePointer(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 450),
          onEnd: widget.onComplete,
          builder: (context, val, _) {
            final opacity = (1.0 - val).clamp(0.0, 1.0);
            return Opacity(
              opacity: opacity,
              child: Stack(
                clipBehavior: Clip.none,
                children: _sparkles.map((p) {
                  final px = p.vx * val;
                  final py = p.vy * val + (val * val * 20.0); // subtle gravity
                  final currentSize = (p.size * (1.0 - val * 0.5)).clamp(1.0, 10.0);

                  return Positioned(
                    left: px - currentSize / 2,
                    top: py - currentSize / 2,
                    child: Container(
                      width: currentSize,
                      height: currentSize,
                      decoration: BoxDecoration(
                        color: p.color,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: p.color.withValues(alpha: 0.8),
                            blurRadius: 4,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _SparkleParticle {
  final double vx;
  final double vy;
  final double size;
  final Color color;

  _SparkleParticle({
    required this.vx,
    required this.vy,
    required this.size,
    required this.color,
  });
}

class _ScorePopupWidget extends StatelessWidget {
  final double row;
  final double col;
  final String text;
  final double cellSize;
  final int totalRows;
  final VoidCallback onComplete;

  const _ScorePopupWidget({
    super.key,
    required this.row,
    required this.col,
    required this.text,
    required this.cellSize,
    required this.totalRows,
    required this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    final visualRow = totalRows - 1 - row;
    final x = col * cellSize;
    final y = visualRow * cellSize;

    return Positioned(
      left: x,
      top: y,
      child: IgnorePointer(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 650),
          onEnd: onComplete,
          builder: (context, val, child) {
            final opacity = (1.0 - val * val).clamp(0.0, 1.0);
            final translateY = -32.0 * val;
            final scale = 0.8 + 0.35 * sin(val * pi);

            return Transform.translate(
              offset: Offset(0, translateY),
              child: Transform.scale(
                scale: scale,
                child: Opacity(
                  opacity: opacity,
                  child: child,
                ),
              ),
            );
          },
          child: Text(
            text,
            style: const TextStyle(
              color: Color(0xFFFFD54F),
              fontSize: 16,
              fontWeight: FontWeight.w900,
              shadows: [
                Shadow(color: Color(0xFF3E200C), offset: Offset(0, 2), blurRadius: 4),
                Shadow(color: Colors.black, offset: Offset(0, 2), blurRadius: 4),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
