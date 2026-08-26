import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/models.dart';
import '../../game/blocks/block_color_mapper.dart';
import '../../game/tile_swap/tile_swap_level_model.dart';
import '../../game/tile_swap/tile_swap_level_generator.dart';
import '../../core/services/service_locator.dart';

enum _SwapBooster { hammer, bomb, colorBomb }

class TileSwapScreen extends StatefulWidget {
  final int startingLevel;

  const TileSwapScreen({
    super.key,
    this.startingLevel = 1,
  });

  @override
  State<TileSwapScreen> createState() => _TileSwapScreenState();
}

class _TileSwapScreenState extends State<TileSwapScreen>
    with TickerProviderStateMixin {
  late int currentLevelNumber;
  late TileSwapLevel currentLevel;

  // Game board matrix: grid[row][col], row 0 is bottom, row rows-1 is top
  late List<List<TileSwapCell?>> grid;

  // Game state
  late int movesRemaining;
  int currentScore = 0;
  int userCoins = 1250;
  late Map<BlockColor, int> collectedGoals;
  int comboStreak = 0;

  // Selection & Swap state
  Point<int>? selectedTile;
  Point<int>? _swappingTileA;
  Point<int>? _swappingTileB;
  bool isSwapping = false;
  bool isProcessingCascade = false;
  bool isGameOver = false;
  bool isLevelComplete = false;
  bool isPaused = false;

  // Boosters
  int hammerCount = 3;
  int bombCount = 3;
  int colorBombCount = 3;
  int shuffleCount = 3;
  _SwapBooster? activeBooster;

  // Animation Controllers
  late AnimationController _swapAnimController;
  late Animation<double> _swapAnimation;
  late AnimationController _pulseAnimController;
  late Animation<double> _pulseAnimation;
  late AnimationController _blastAnimController;
  late Animation<double> _blastScale;

  // Matched cells highlighted before blast
  Set<Point<int>> _highlightedCells = {};

  // Active particle bursts & score popups
  final List<_ParticleBurstItem> _particleBursts = [];
  final List<_ScorePopupData> _scorePopups = [];

  // Floating notifications (Combo / Booster banner)
  String? _bannerText;
  Color _bannerColor = const Color(0xFFFFD54F);

  // Drag tracking
  Point<int>? _dragStartTile;
  Offset? _dragStartPos;

  final Random _rng = Random();

  @override
  void initState() {
    super.initState();
    currentLevelNumber = widget.startingLevel;

    _swapAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _swapAnimation = CurvedAnimation(
      parent: _swapAnimController,
      curve: Curves.easeInOutQuad,
    );

    _pulseAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.96, end: 1.05).animate(
      CurvedAnimation(parent: _pulseAnimController, curve: Curves.easeInOut),
    );

    _blastAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    );
    _blastScale = Tween<double>(begin: 1.0, end: 1.25).animate(
      CurvedAnimation(parent: _blastAnimController, curve: Curves.easeOutBack),
    );

    _loadUserCoins();
    _loadLevel(currentLevelNumber);
    try {
      ServiceLocator.instance.audioManager.playMiniGamesBgm();
    } catch (_) {}
  }

  @override
  void dispose() {
    _swapAnimController.dispose();
    _pulseAnimController.dispose();
    _blastAnimController.dispose();
    super.dispose();
  }

  Future<void> _loadUserCoins() async {
    try {
      final coinMgr = ServiceLocator.instance.coinManager;
      setState(() => userCoins = coinMgr.balance);
    } catch (_) {}
  }

  void _loadLevel(int levelNum) {
    currentLevelNumber = levelNum;
    currentLevel = TileSwapLevelGenerator.getLevel(levelNum);

    movesRemaining = currentLevel.moves;
    currentScore = 0;
    comboStreak = 0;
    selectedTile = null;
    _swappingTileA = null;
    _swappingTileB = null;
    isSwapping = false;
    isProcessingCascade = false;
    isGameOver = false;
    isLevelComplete = false;
    isPaused = false;
    activeBooster = null;
    _highlightedCells.clear();
    _particleBursts.clear();
    _scorePopups.clear();

    collectedGoals = {
      for (final c in currentLevel.targetRequirements.keys) c: 0,
    };

    // Initialize board from level initialGrid or clean generation
    final rows = currentLevel.rows;
    final cols = currentLevel.columns;
    grid = List.generate(rows, (r) {
      return List.generate(cols, (c) {
        final color = currentLevel.initialGrid != null &&
                r < currentLevel.initialGrid!.length &&
                c < currentLevel.initialGrid![r].length
            ? currentLevel.initialGrid![r][c]
            : null;
        return TileSwapCell(
          color: color ?? _randomActiveColor(),
        );
      });
    });

    if (mounted) setState(() {});
  }

  BlockColor _randomActiveColor() {
    final colors = currentLevel.activeColors;
    return colors[_rng.nextInt(colors.length)];
  }

  void _showBanner(String text, [Color color = const Color(0xFFFFD54F)]) {
    if (!mounted) return;
    setState(() {
      _bannerText = text;
      _bannerColor = color;
    });
    Future.delayed(const Duration(milliseconds: 1400), () {
      if (mounted && _bannerText == text) {
        setState(() => _bannerText = null);
      }
    });
  }

  // ─────────────────────────────────────────────
  // INTERACTION ENGINE: TAP & SWIPE
  // ─────────────────────────────────────────────

  void _onTileTap(int r, int c) {
    if (isSwapping || isProcessingCascade || isGameOver || isLevelComplete || isPaused) {
      return;
    }

    // Booster handling
    if (activeBooster != null) {
      _handleBoosterUse(r, c);
      return;
    }

    final tapped = Point(r, c);

    if (selectedTile == null) {
      HapticFeedback.selectionClick();
      ServiceLocator.instance.audioManager.playTileTap();
      setState(() => selectedTile = tapped);
      return;
    }

    if (selectedTile == tapped) {
      // Deselect
      setState(() => selectedTile = null);
      return;
    }

    // Check if adjacent
    final dr = (r - selectedTile!.x).abs();
    final dc = (c - selectedTile!.y).abs();
    final isAdjacent = (dr + dc) == 1;

    if (isAdjacent) {
      final first = selectedTile!;
      setState(() => selectedTile = null);
      _executeSwap(first, tapped);
    } else {
      // Switch selection to new tile
      HapticFeedback.selectionClick();
      setState(() => selectedTile = tapped);
    }
  }

  void _onPanStart(DragStartDetails details, double cellSize, int rows, int cols) {
    if (isSwapping || isProcessingCascade || isGameOver || isLevelComplete || isPaused) {
      return;
    }
    final col = (details.localPosition.dx / cellSize).floor().clamp(0, cols - 1);
    final visualRow = (details.localPosition.dy / cellSize).floor().clamp(0, rows - 1);
    final row = rows - 1 - visualRow;

    _dragStartTile = Point(row, col);
    _dragStartPos = details.localPosition;
  }

  void _onPanUpdate(DragUpdateDetails details, double cellSize, int rows, int cols) {
    if (_dragStartTile == null || _dragStartPos == null) return;
    if (isSwapping || isProcessingCascade || isGameOver || isLevelComplete || isPaused) {
      return;
    }

    final dx = details.localPosition.dx - _dragStartPos!.dx;
    final dy = details.localPosition.dy - _dragStartPos!.dy;
    const threshold = 16.0;

    if (dx.abs() > threshold || dy.abs() > threshold) {
      int targetR = _dragStartTile!.x;
      int targetC = _dragStartTile!.y;

      if (dx.abs() > dy.abs()) {
        // Horizontal swipe
        targetC += dx > 0 ? 1 : -1;
      } else {
        // Vertical swipe (dy > 0 is downwards in visual coords -> lower row in matrix)
        targetR += dy > 0 ? -1 : 1;
      }

      final startTile = _dragStartTile!;
      _dragStartTile = null;
      _dragStartPos = null;
      setState(() => selectedTile = null);

      if (targetR >= 0 && targetR < rows && targetC >= 0 && targetC < cols) {
        _executeSwap(startTile, Point(targetR, targetC));
      }
    }
  }

  void _onPanEnd(DragEndDetails details) {
    _dragStartTile = null;
    _dragStartPos = null;
  }

  // ─────────────────────────────────────────────
  // SWAP EXECUTION & VALIDATION
  // ─────────────────────────────────────────────

  Future<void> _executeSwap(Point<int> a, Point<int> b) async {
    if (isSwapping || isProcessingCascade) return;

    final cellA = grid[a.x][a.y];
    final cellB = grid[b.x][b.y];
    if (cellA == null || cellB == null) return;

    setState(() {
      isSwapping = true;
      _swappingTileA = a;
      _swappingTileB = b;
    });

    HapticFeedback.lightImpact();
    try {
      ServiceLocator.instance.audioManager.playSwapSlide();
    } catch (_) {}

    // 1. Forward swap animation
    await _swapAnimController.forward(from: 0);

    // Apply swap in grid
    grid[a.x][a.y] = cellB;
    grid[b.x][b.y] = cellA;

    // 2. Check for Special Tile Combinations (e.g. Color Bomb swap)
    final isSpecialCombo = _checkSpecialSwap(a, b, cellA, cellB);

    // 3. Find 3+ matches
    final matches = _findMatches();

    if (matches.isNotEmpty || isSpecialCombo) {
      // Valid Swap!
      movesRemaining--;
      comboStreak = 0;

      setState(() {
        isSwapping = false;
        _swappingTileA = null;
        _swappingTileB = null;
      });

      // Process match cascade
      await _processMatchesAndCascade(swapPoint: b);
    } else {
      // Invalid Swap -> Revert back with gentle shake
      HapticFeedback.mediumImpact();
      try {
        ServiceLocator.instance.audioManager.playSwapInvalid();
      } catch (_) {}

      await _swapAnimController.reverse();

      // Revert swap in grid
      grid[a.x][a.y] = cellA;
      grid[b.x][b.y] = cellB;

      setState(() {
        isSwapping = false;
        _swappingTileA = null;
        _swappingTileB = null;
      });
    }
  }

  bool _checkSpecialSwap(Point<int> a, Point<int> b, TileSwapCell cellA, TileSwapCell cellB) {
    // 1. Double Color Bomb -> Clear entire board!
    if (cellA.special == TileSpecialType.colorBomb && cellB.special == TileSpecialType.colorBomb) {
      _triggerFullBoardBlast();
      return true;
    }

    // 2. Color Bomb + Normal/Special -> Clear all tiles of that color
    if (cellA.special == TileSpecialType.colorBomb) {
      _triggerColorBombBlast(b, cellB.color);
      grid[a.x][a.y] = null; // consume color bomb
      return true;
    }
    if (cellB.special == TileSpecialType.colorBomb) {
      _triggerColorBombBlast(a, cellA.color);
      grid[b.x][b.y] = null; // consume color bomb
      return true;
    }

    // 3. Line + Line -> Cross Blast
    final isLineA = cellA.special == TileSpecialType.lineHorizontal || cellA.special == TileSpecialType.lineVertical;
    final isLineB = cellB.special == TileSpecialType.lineHorizontal || cellB.special == TileSpecialType.lineVertical;
    if (isLineA && isLineB) {
      _triggerCrossBlast(b);
      grid[a.x][a.y] = null;
      grid[b.x][b.y] = null;
      return true;
    }

    return false;
  }

  void _triggerColorBombBlast(Point<int> origin, BlockColor targetColor) {
    final rows = currentLevel.rows;
    final cols = currentLevel.columns;
    final matchedPoints = <Point<int>>{};

    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        if (grid[r][c]?.color == targetColor) {
          matchedPoints.add(Point(r, c));
        }
      }
    }

    _showBanner('COLOR BLAST!', BlockColorMapper.getStyle(targetColor).glow);
    _clearMatchedCluster(matchedPoints, targetColor);
  }

  void _triggerCrossBlast(Point<int> origin) {
    final rows = currentLevel.rows;
    final cols = currentLevel.columns;
    final matchedPoints = <Point<int>>{};

    for (int c = 0; c < cols; c++) {
      matchedPoints.add(Point(origin.x, c));
    }
    for (int r = 0; r < rows; r++) {
      matchedPoints.add(Point(r, origin.y));
    }

    _showBanner('CROSS BLAST!', const Color(0xFFFFD54F));
    _clearMatchedCluster(matchedPoints, grid[origin.x][origin.y]?.color ?? BlockColor.red);
  }

  void _triggerFullBoardBlast() {
    final rows = currentLevel.rows;
    final cols = currentLevel.columns;
    final matchedPoints = <Point<int>>{};

    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        matchedPoints.add(Point(r, c));
      }
    }

    _showBanner('MEGA BOARD BLAST!', const Color(0xFFFF4081));
    _clearMatchedCluster(matchedPoints, BlockColor.purple);
  }

  // ─────────────────────────────────────────────
  // MATCH DETECTION (Horizontal & Vertical)
  // ─────────────────────────────────────────────

  List<List<Point<int>>> _findMatches() {
    final rows = currentLevel.rows;
    final cols = currentLevel.columns;
    final matchedSets = <Set<Point<int>>>[];

    // 1. Horizontal Matches
    for (int r = 0; r < rows; r++) {
      int matchLen = 1;
      for (int c = 0; c < cols; c++) {
        final current = grid[r][c];
        final next = (c + 1 < cols) ? grid[r][c + 1] : null;

        if (current != null && next != null && current.color == next.color) {
          matchLen++;
        } else {
          if (matchLen >= 3) {
            final group = <Point<int>>{};
            for (int k = 0; k < matchLen; k++) {
              group.add(Point(r, c - k));
            }
            matchedSets.add(group);
          }
          matchLen = 1;
        }
      }
    }

    // 2. Vertical Matches
    for (int c = 0; c < cols; c++) {
      int matchLen = 1;
      for (int r = 0; r < rows; r++) {
        final current = grid[r][c];
        final next = (r + 1 < rows) ? grid[r + 1][c] : null;

        if (current != null && next != null && current.color == next.color) {
          matchLen++;
        } else {
          if (matchLen >= 3) {
            final group = <Point<int>>{};
            for (int k = 0; k < matchLen; k++) {
              group.add(Point(r - k, c));
            }
            matchedSets.add(group);
          }
          matchLen = 1;
        }
      }
    }

    return matchedSets.map((s) => s.toList()).toList();
  }

  // ─────────────────────────────────────────────
  // CASCADE & GRAVITY ENGINE
  // ─────────────────────────────────────────────

  Future<void> _processMatchesAndCascade({Point<int>? swapPoint}) async {
    if (!mounted) return;
    setState(() => isProcessingCascade = true);

    bool hasMatches = true;

    while (hasMatches && mounted) {
      final matchGroups = _findMatches();
      if (matchGroups.isEmpty) {
        hasMatches = false;
        break;
      }

      comboStreak++;
      if (comboStreak >= 2) {
        final text = comboStreak >= 4
            ? 'MEGA COMBO x$comboStreak!'
            : (comboStreak == 3 ? 'SUPER COMBO x3!' : 'COMBO x2!');
        _showBanner(text, const Color(0xFFFFD54F));
      }

      // Combine matched points & check for Special Tile creations (Match 4 / 5)
      final allMatchedPoints = <Point<int>>{};
      Point<int>? specialCreatePoint;
      TileSpecialType? specialTypeToCreate;
      BlockColor? specialColor;

      for (final group in matchGroups) {
        allMatchedPoints.addAll(group);
        final color = grid[group.first.x][group.first.y]?.color;
        if (color == null) continue;

        // Match 5 -> Color Bomb
        if (group.length >= 5) {
          specialTypeToCreate = TileSpecialType.colorBomb;
          specialColor = color;
          specialCreatePoint = group.contains(swapPoint) ? swapPoint : group[2];
        }
        // Match 4 -> Line Blast
        else if (group.length == 4 && specialTypeToCreate == null) {
          // Check if horizontal or vertical
          final isHorizontal = group.first.x == group.last.x;
          specialTypeToCreate = isHorizontal
              ? TileSpecialType.lineHorizontal
              : TileSpecialType.lineVertical;
          specialColor = color;
          specialCreatePoint = group.contains(swapPoint) ? swapPoint : group[1];
        }

        // Trigger Line Blast effects if matched group contained special tile
        for (final p in group) {
          final cell = grid[p.x][p.y];
          if (cell?.special == TileSpecialType.lineHorizontal) {
            for (int c = 0; c < currentLevel.columns; c++) {
              allMatchedPoints.add(Point(p.x, c));
            }
          } else if (cell?.special == TileSpecialType.lineVertical) {
            for (int r = 0; r < currentLevel.rows; r++) {
              allMatchedPoints.add(Point(r, p.y));
            }
          }
        }
      }

      // 1. Highlight phase
      HapticFeedback.lightImpact();
      try {
        if (comboStreak > 1) {
          ServiceLocator.instance.audioManager.playCombo(comboStreak);
        } else {
          ServiceLocator.instance.audioManager.playMatch(allMatchedPoints.length);
        }
        ServiceLocator.instance.audioManager.playBlast(isLarge: allMatchedPoints.length >= 5);
      } catch (_) {}

      setState(() {
        _highlightedCells = allMatchedPoints;
      });
      await _blastAnimController.forward(from: 0);

      // 2. Score & Goal updates
      int pointsEarned = 0;
      for (final p in allMatchedPoints) {
        final cell = grid[p.x][p.y];
        if (cell != null) {
          _spawnParticlesAt(p.x, p.y, cell.color);
          if (collectedGoals.containsKey(cell.color)) {
            collectedGoals[cell.color] = (collectedGoals[cell.color]! + 1);
          }
          pointsEarned += 60 * comboStreak;
        }
      }

      currentScore += pointsEarned;
      if (allMatchedPoints.isNotEmpty) {
        final centerRow = allMatchedPoints.fold(0, (s, p) => s + p.x) / allMatchedPoints.length;
        final centerCol = allMatchedPoints.fold(0, (s, p) => s + p.y) / allMatchedPoints.length;
        _addScorePopup(centerRow, centerCol, '+$pointsEarned');
      }

      // 3. Clear matched cells
      for (final p in allMatchedPoints) {
        grid[p.x][p.y] = null;
      }

      // If special tile was earned, place it!
      if (specialCreatePoint != null && specialTypeToCreate != null && specialColor != null) {
        grid[specialCreatePoint.x][specialCreatePoint.y] = TileSwapCell(
          color: specialColor,
          special: specialTypeToCreate,
        );
      }

      setState(() {
        _highlightedCells = {};
      });

      await Future.delayed(const Duration(milliseconds: 100));

      // 4. Apply Gravity (tiles fall down into empty cells)
      _applyGravity();
      setState(() {});
      await Future.delayed(const Duration(milliseconds: 140));

      // 5. Refill empty cells from top
      _refillEmptyCells();
      setState(() {});
      await Future.delayed(const Duration(milliseconds: 160));
    }

    if (!mounted) return;
    setState(() => isProcessingCascade = false);

    // Check Win / Loss condition
    _checkGameEndState();
  }

  void _clearMatchedCluster(Set<Point<int>> points, BlockColor fallbackColor) {
    for (final p in points) {
      final cell = grid[p.x][p.y];
      final color = cell?.color ?? fallbackColor;
      _spawnParticlesAt(p.x, p.y, color);
      if (collectedGoals.containsKey(color)) {
        collectedGoals[color] = (collectedGoals[color]! + 1);
      }
      grid[p.x][p.y] = null;
    }
    currentScore += points.length * 80;
    setState(() {});
    _applyGravity();
    _refillEmptyCells();
    _processMatchesAndCascade();
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

  void _refillEmptyCells() {
    final rows = currentLevel.rows;
    final cols = currentLevel.columns;

    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        if (grid[r][c] == null) {
          grid[r][c] = TileSwapCell(
            color: _randomActiveColor(),
          );
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
    }
  }

  void _triggerWin() {
    if (isLevelComplete || isGameOver) return;
    HapticFeedback.heavyImpact();
    try {
      ServiceLocator.instance.audioManager.playLevelComplete();
    } catch (_) {}

    final bonusCoins = 100 + (movesRemaining * 10);
    userCoins += bonusCoins;

    setState(() {
      isLevelComplete = true;
      currentScore += movesRemaining * 100;
    });

    try {
      ServiceLocator.instance.coinManager.addCoins(bonusCoins);
    } catch (_) {}
  }

  void _triggerGameOver() {
    if (isLevelComplete || isGameOver) return;
    HapticFeedback.heavyImpact();
    try {
      ServiceLocator.instance.audioManager.playLevelFail();
    } catch (_) {}

    setState(() {
      isGameOver = true;
    });
  }

  // ─────────────────────────────────────────────
  // BOOSTERS IMPLEMENTATION
  // ─────────────────────────────────────────────

  void _onSelectBooster(_SwapBooster booster) {
    if (isSwapping || isProcessingCascade || isGameOver || isLevelComplete) return;

    setState(() {
      if (activeBooster == booster) {
        activeBooster = null; // deselect
      } else {
        activeBooster = booster;
        selectedTile = null;
      }
    });

    if (activeBooster != null) {
      HapticFeedback.selectionClick();
      try {
        ServiceLocator.instance.audioManager.playButtonClick();
      } catch (_) {}
      _showBanner(
        activeBooster == _SwapBooster.hammer
            ? 'Tap a tile to smash!'
            : (activeBooster == _SwapBooster.bomb
                ? 'Tap a tile to blast 3x3 area!'
                : 'Tap a color tile to clear all!'),
        const Color(0xFFFFD54F),
      );
    }
  }

  void _handleBoosterUse(int r, int c) {
    final booster = activeBooster;
    if (booster == null) return;

    final cell = grid[r][c];
    if (cell == null) return;

    setState(() => activeBooster = null);

    switch (booster) {
      case _SwapBooster.hammer:
        if (hammerCount <= 0) return;
        setState(() => hammerCount--);
        HapticFeedback.heavyImpact();
        try {
          ServiceLocator.instance.audioManager.playHammer();
        } catch (_) {}
        _spawnParticlesAt(r, c, cell.color);
        if (collectedGoals.containsKey(cell.color)) {
          collectedGoals[cell.color] = (collectedGoals[cell.color]! + 1);
        }
        grid[r][c] = null;
        _applyGravity();
        _refillEmptyCells();
        _processMatchesAndCascade();
        break;

      case _SwapBooster.bomb:
        if (bombCount <= 0) return;
        setState(() => bombCount--);
        HapticFeedback.heavyImpact();
        try {
          ServiceLocator.instance.audioManager.playBomb();
        } catch (_) {}
        final points = <Point<int>>{};
        for (int dr = -1; dr <= 1; dr++) {
          for (int dc = -1; dc <= 1; dc++) {
            final nr = r + dr;
            final nc = c + dc;
            if (nr >= 0 && nr < currentLevel.rows && nc >= 0 && nc < currentLevel.columns) {
              points.add(Point(nr, nc));
            }
          }
        }
        _clearMatchedCluster(points, cell.color);
        break;

      case _SwapBooster.colorBomb:
        if (colorBombCount <= 0) return;
        setState(() => colorBombCount--);
        HapticFeedback.heavyImpact();
        try {
          ServiceLocator.instance.audioManager.playColorBomb();
        } catch (_) {}
        _triggerColorBombBlast(Point(r, c), cell.color);
        break;
    }
  }

  void _onUseShuffle() {
    if (isSwapping || isProcessingCascade || isGameOver || isLevelComplete || shuffleCount <= 0) {
      return;
    }

    setState(() {
      shuffleCount--;
      activeBooster = null;
      selectedTile = null;
    });

    HapticFeedback.mediumImpact();
    try {
      ServiceLocator.instance.audioManager.playShuffle();
    } catch (_) {}
    _showBanner('SHUFFLE!', const Color(0xFF64B5F6));

    final rows = currentLevel.rows;
    final cols = currentLevel.columns;
    final allCells = <TileSwapCell>[];

    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        if (grid[r][c] != null) allCells.add(grid[r][c]!);
      }
    }

    allCells.shuffle(_rng);

    int idx = 0;
    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        if (idx < allCells.length) {
          grid[r][c] = allCells[idx++];
        }
      }
    }

    setState(() {});
    _processMatchesAndCascade();
  }

  // ─────────────────────────────────────────────
  // PARTICLE & POPUP SPAWNERS
  // ─────────────────────────────────────────────

  void _spawnParticlesAt(int row, int col, BlockColor color) {
    final id = '${row}_${col}_${DateTime.now().microsecondsSinceEpoch}';
    _particleBursts.add(_ParticleBurstItem(
      id: id,
      gridRow: row,
      gridCol: col,
      color: color,
    ));
  }

  void _addScorePopup(double row, double col, String text) {
    final id = '${row}_${col}_${DateTime.now().microsecondsSinceEpoch}';
    _scorePopups.add(_ScorePopupData(
      id: id,
      row: row,
      col: col,
      text: text,
    ));
  }

  // ─────────────────────────────────────────────
  // BUILD METHOD
  // ─────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E2A38),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── 1. Garden Background ──────────────────────────────────────────
          Image.asset(
            'assets/images/backgrounds/bg_garden.jpg',
            fit: BoxFit.cover,
          ),

          // ── 2. Subtle Lighting Vignette ───────────────────────────────────
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

          // ── 3. Main Gameplay Layout ───────────────────────────────────────
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 2),
                _buildTopBar(),
                const SizedBox(height: 2),
                _buildGoalAndMovesRow(),
                const SizedBox(height: 2),
                _buildTileSwapPlaqueHeader(),
                const SizedBox(height: 2),

                // Central Large Board Area
                Expanded(
                  child: Center(
                    child: _buildBoardArea(),
                  ),
                ),

                const SizedBox(height: 4),

                // Bottom Boosters Row
                _buildBottomBoostersBar(),

                const SizedBox(height: 6),
              ],
            ),
          ),

          // ── Floating Combo / Notification Banner ──────────────────────────
          if (_bannerText != null)
            Positioned(
              top: 145,
              left: 20,
              right: 20,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF8D5325), Color(0xFF5D3312)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _bannerColor, width: 2.0),
                    boxShadow: [
                      BoxShadow(
                        color: _bannerColor.withValues(alpha: 0.6),
                        blurRadius: 10,
                        spreadRadius: 1,
                      ),
                      const BoxShadow(
                        color: Colors.black54,
                        offset: Offset(0, 4),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                  child: Text(
                    _bannerText!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: _bannerColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      shadows: const [
                        Shadow(color: Colors.black, offset: Offset(0, 2), blurRadius: 4),
                      ],
                    ),
                  ),
                ),
              ),
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

          // Wooden Header Crest "TILE SWAP • LVL X"
          Expanded(
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF8D5325), Color(0xFF5D3312), Color(0xFF3E200C)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFFFD54F), width: 1.8),
                    boxShadow: const [
                      BoxShadow(color: Color(0xFF2C1605), offset: Offset(0, 3), blurRadius: 0),
                      BoxShadow(color: Colors.black45, offset: Offset(0, 4), blurRadius: 5),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.swap_horiz_rounded, color: Color(0xFFFFD54F), size: 16),
                      const SizedBox(width: 5),
                      Text(
                        'TILE SWAP • LVL $currentLevelNumber',
                        style: const TextStyle(
                          color: Color(0xFFFFE082),
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.8,
                          shadows: [
                            Shadow(color: Color(0xFF2C1605), offset: Offset(0, 2), blurRadius: 2),
                          ],
                        ),
                      ),
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
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF8D5325), Color(0xFF5D3312)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.circular(10),
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
  // SUB-BANNER PLAQUE: "TILE SWAP"
  // ─────────────────────────────────────────────

  Widget _buildTileSwapPlaqueHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 3),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF29B6F6), Color(0xFF0288D1)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white70, width: 1.5),
          boxShadow: const [
            BoxShadow(color: Colors.black26, offset: Offset(0, 2), blurRadius: 3),
          ],
        ),
        child: const Text(
          'Swap to match 3 or more same colored tiles!',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            fontSize: 10.5,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.2,
            shadows: [
              Shadow(color: Colors.black45, offset: Offset(0, 1), blurRadius: 2),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // GAMEPLAY BOARD AREA
  // ─────────────────────────────────────────────

  Widget _buildBoardArea() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cols = currentLevel.columns;
        final rows = currentLevel.rows;

        const boardBorderWidth = 2.5;
        const boardPadding = 4.0;
        const horizontalInset = (boardPadding + boardBorderWidth) * 2; // 13.0
        const verticalInset = (boardPadding + boardBorderWidth) * 2;   // 13.0

        final maxW = constraints.maxWidth - 16;
        final maxH = constraints.maxHeight - 12;

        final cellW = (maxW - horizontalInset) / cols;
        final cellH = (maxH - verticalInset) / rows;
        final cellSize = min(cellW, cellH).clamp(24.0, 52.0);

        final innerBoardWidth = cellSize * cols;
        final innerBoardHeight = cellSize * rows;
        final boardWidth = innerBoardWidth + horizontalInset;
        final boardHeight = innerBoardHeight + verticalInset;

        return SizedBox(
          width: boardWidth,
          height: boardHeight,
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
              child: GestureDetector(
                onPanStart: (details) => _onPanStart(details, cellSize, rows, cols),
                onPanUpdate: (details) => _onPanUpdate(details, cellSize, rows, cols),
                onPanEnd: _onPanEnd,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // Grid background & placed tiles
                    _buildGridCells(cellSize, cols, rows),

                    // Blasting particles
                    ..._buildParticlesLayer(cellSize, rows),

                    // Score Popups
                    ..._buildScorePopupsLayer(cellSize, rows),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ─────────────────────────────────────────────
  // GRID CELLS & TILES
  // ─────────────────────────────────────────────

  Widget _buildGridCells(double cellSize, int cols, int rows) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(rows, (gridR) {
        // matrix row index = (rows - 1 - gridR)
        final rowIdx = rows - 1 - gridR;

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(cols, (colIdx) {
            final cell = grid[rowIdx][colIdx];
            final point = Point(rowIdx, colIdx);
            final isSelected = selectedTile == point;
            final isHighlighted = _highlightedCells.contains(point);

            // Swap animation offsets
            Offset swapOffset = Offset.zero;
            if (isSwapping && _swappingTileA != null && _swappingTileB != null) {
              if (point == _swappingTileA) {
                final dx = (_swappingTileB!.y - _swappingTileA!.y) * cellSize;
                // Matrix row diff -> Visual row diff = -(rowB - rowA)
                final dy = -(_swappingTileB!.x - _swappingTileA!.x) * cellSize;
                swapOffset = Offset(dx, dy) * _swapAnimation.value;
              } else if (point == _swappingTileB) {
                final dx = (_swappingTileA!.y - _swappingTileB!.y) * cellSize;
                final dy = -(_swappingTileA!.x - _swappingTileB!.x) * cellSize;
                swapOffset = Offset(dx, dy) * _swapAnimation.value;
              }
            }

            return GestureDetector(
              onTap: () => _onTileTap(rowIdx, colIdx),
              child: Container(
                width: cellSize,
                height: cellSize,
                decoration: BoxDecoration(
                  color: const Color(0xFF221105).withValues(alpha: 0.75),
                  border: Border.all(
                    color: const Color(0xFF533118).withValues(alpha: 0.50),
                    width: 0.5,
                  ),
                ),
                child: cell != null
                    ? Transform.translate(
                        offset: swapOffset,
                        child: _buildPlacedTile(
                          cell,
                          cellSize,
                          isSelected,
                          isHighlighted,
                        ),
                      )
                    : null,
              ),
            );
          }),
        );
      }),
    );
  }

  Widget _buildPlacedTile(
    TileSwapCell cell,
    double cellSize,
    bool isSelected,
    bool isHighlighted,
  ) {
    final style = BlockColorMapper.getStyle(cell.color);

    return ScaleTransition(
      scale: isHighlighted
          ? _blastScale
          : (isSelected ? _pulseAnimation : const AlwaysStoppedAnimation(1.0)),
      child: Container(
        padding: EdgeInsets.zero,
        decoration: isSelected
            ? BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: const Color(0xFFFFD54F), width: 2.2),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFFD54F).withValues(alpha: 0.8),
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
                ],
              )
            : (isHighlighted
                ? BoxDecoration(
                    boxShadow: [
                      const BoxShadow(
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
                : null),
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (cell.special == TileSpecialType.lineHorizontal || cell.special == TileSpecialType.lineVertical)
              Image.asset(
                'assets/images/power_ups/powerup_4_rocket.png',
                width: cellSize * 0.95,
                height: cellSize * 0.95,
                fit: BoxFit.contain,
              )
            else if (cell.special == TileSpecialType.colorBomb)
              Image.asset(
                'assets/images/power_ups/powerup_7_color_bomb.png',
                width: cellSize * 0.95,
                height: cellSize * 0.95,
                fit: BoxFit.contain,
              )
            else
              // 3D Normal Block Image
              Image.asset(
                BlockColorMapper.getAssetPath(cell.color),
                fit: BoxFit.contain,
              ),
          ],
        ),
      ),
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
            isSelected: activeBooster == _SwapBooster.hammer,
            onTap: () => _onSelectBooster(_SwapBooster.hammer),
          ),
          _buildBoosterItem(
            assetPath: 'assets/images/boosters/bomb.png',
            count: bombCount,
            isSelected: activeBooster == _SwapBooster.bomb,
            onTap: () => _onSelectBooster(_SwapBooster.bomb),
          ),
          _buildBoosterItem(
            assetPath: 'assets/images/boosters/color_bomb.png',
            count: colorBombCount,
            isSelected: activeBooster == _SwapBooster.colorBomb,
            onTap: () => _onSelectBooster(_SwapBooster.colorBomb),
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
      color: Colors.black.withValues(alpha: 0.70),
      child: Center(
        child: Container(
          width: 290,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFFF8E7), Color(0xFFFFE0B2)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0xFFFFD54F), width: 3.0),
            boxShadow: const [
              BoxShadow(color: Colors.black54, blurRadius: 16, offset: Offset(0, 8)),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Stars
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(3, (i) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4),
                    child: Icon(Icons.star_rounded, color: Color(0xFFFFD54F), size: 38),
                  );
                }),
              ),
              const SizedBox(height: 10),
              const Text(
                'LEVEL COMPLETE!',
                style: TextStyle(
                  color: Color(0xFF5D3312),
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Score: $currentScore',
                style: const TextStyle(
                  color: Color(0xFF8D5325),
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset('assets/images/icons/icon_coin.png', width: 22, height: 22),
                  const SizedBox(width: 5),
                  Text(
                    '+${100 + (movesRemaining * 10)} Coins',
                    style: const TextStyle(
                      color: Color(0xFF2E7D32),
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildDialogButton(
                      text: 'HOME',
                      color: const Color(0xFF78909C),
                      onTap: () => Navigator.pop(context),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildDialogButton(
                      text: 'NEXT',
                      color: const Color(0xFF43A047),
                      onTap: () => _loadLevel(currentLevelNumber + 1),
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

  Widget _buildGameOverOverlay() {
    return Container(
      color: Colors.black.withValues(alpha: 0.70),
      child: Center(
        child: Container(
          width: 280,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFFF8E7), Color(0xFFFFCDD2)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0xFFE53935), width: 2.5),
            boxShadow: const [
              BoxShadow(color: Colors.black54, blurRadius: 16, offset: Offset(0, 8)),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.sentiment_dissatisfied_rounded, color: Color(0xFFE53935), size: 48),
              const SizedBox(height: 10),
              const Text(
                'OUT OF MOVES!',
                style: TextStyle(
                  color: Color(0xFFB71C1C),
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Don\'t give up! Try again.',
                style: TextStyle(color: Color(0xFF5D3312), fontSize: 13),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildDialogButton(
                      text: 'HOME',
                      color: const Color(0xFF78909C),
                      onTap: () => Navigator.pop(context),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildDialogButton(
                      text: 'RETRY',
                      color: const Color(0xFFE53935),
                      onTap: () => _loadLevel(currentLevelNumber),
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

  Widget _buildPauseOverlay() {
    return Container(
      color: Colors.black.withValues(alpha: 0.70),
      child: Center(
        child: Container(
          width: 270,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFFF8E7), Color(0xFFFFE0B2)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0xFFFFD54F), width: 2.5),
            boxShadow: const [
              BoxShadow(color: Colors.black54, blurRadius: 16, offset: Offset(0, 8)),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'PAUSED',
                style: TextStyle(
                  color: Color(0xFF5D3312),
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 16),
              _buildDialogButton(
                text: 'RESUME',
                color: const Color(0xFF43A047),
                onTap: () => setState(() => isPaused = false),
              ),
              const SizedBox(height: 8),
              _buildDialogButton(
                text: 'RESTART',
                color: const Color(0xFFFB8C00),
                onTap: () => _loadLevel(currentLevelNumber),
              ),
              const SizedBox(height: 8),
              _buildDialogButton(
                text: 'EXIT',
                color: const Color(0xFFE53935),
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDialogButton({
    required String text,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.4),
              offset: const Offset(0, 3),
              blurRadius: 4,
            ),
          ],
        ),
        child: Center(
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 13,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// PARTICLE & SCORE POPUP WIDGETS
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
                  final py = p.vy * val + (val * val * 20.0);
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
