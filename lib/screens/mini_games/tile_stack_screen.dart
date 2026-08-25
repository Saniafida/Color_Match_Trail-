import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../game/blocks/block_color_mapper.dart';
import '../../game/basket_collect/basket_collect_level_model.dart';
import '../../game/basket_collect/basket_collect_level_generator.dart';
import '../../core/services/service_locator.dart';

// ─────────────────────────────────────────────
// DATA MODELS
// ─────────────────────────────────────────────

class FallingBlock {
  final int id;
  double x; // 0.0–1.0 relative screen width
  double y; // 0.0–1.0 relative screen height
  final BlockColor color;
  final double speed;
  double rotation;
  bool isCaught;
  bool isMissed;

  FallingBlock({
    required this.id,
    required this.x,
    required this.y,
    required this.color,
    required this.speed,
    this.rotation = 0.0,
    this.isCaught = false,
    this.isMissed = false,
  });
}

class CaughtBlockItem {
  final BlockColor color;
  final double relativeOffsetX;
  final double relativeOffsetY;
  final double rotation;

  CaughtBlockItem({
    required this.color,
    required this.relativeOffsetX,
    required this.relativeOffsetY,
    required this.rotation,
  });
}

// ─────────────────────────────────────────────
// CUSTOM CLIPPER — bottom N% of an image
// Used to paint the basket's front rim ON TOP of
// caught blocks, creating a true 3-D depth illusion
// ─────────────────────────────────────────────
class _BottomFractionClipper extends CustomClipper<Rect> {
  final double fraction; // 0.0–1.0; e.g. 0.38 = bottom 38%

  const _BottomFractionClipper(this.fraction);

  @override
  Rect getClip(Size size) {
    final top = size.height * (1.0 - fraction);
    return Rect.fromLTWH(0, top, size.width, size.height * fraction);
  }

  @override
  bool shouldReclip(_BottomFractionClipper old) => old.fraction != fraction;
}

// ─────────────────────────────────────────────
// SCREEN WIDGET
// ─────────────────────────────────────────────

class TileStackScreen extends StatefulWidget {
  final int startingLevel;

  const TileStackScreen({
    super.key,
    this.startingLevel = 1,
  });

  @override
  State<TileStackScreen> createState() => _TileStackScreenState();
}

class _TileStackScreenState extends State<TileStackScreen>
    with TickerProviderStateMixin {
  // ── Level ──────────────────────────────────
  late int currentLevelNumber;
  late BasketCollectLevel currentLevel;

  // ── Stats ──────────────────────────────────
  late int movesRemaining;
  int currentCoins = 1250;
  int currentScore = 0;

  // ── Per-color goal tracking ────────────────
  late Map<BlockColor, int> _caughtPerColor;

  // ── Lives / miss system ────────────────────
  late int livesRemaining;
  int _lifeAnimatingIndex = -1; // which heart is animating away

  // ── Basket ─────────────────────────────────
  double basketX = 0.0; // –1.0 → +1.0
  final double _baseBasketWidthFraction = 0.45;

  // ── Falling blocks engine ──────────────────
  final List<FallingBlock> _fallingBlocks = [];
  final List<BlockColor> _upcomingQueue = [];
  final List<CaughtBlockItem> _caughtPile = [];
  int _blockIdCounter = 0;

  // ── Boosters ───────────────────────────────
  int hammerCount = 3;
  int bombCount = 3;
  int colorBombCount = 3;
  int hintCount = 1;
  bool isMagnetActive = false;

  // ── Combo ──────────────────────────────────
  int comboStreak = 0;
  String? comboText;
  Timer? _comboTimer;

  // ── Game loop ──────────────────────────────
  late AnimationController _gameTicker;
  DateTime? _lastTickTime;
  DateTime? _lastSpawnTime;

  // ── Flow flags ─────────────────────────────
  bool _isLevelComplete = false;
  bool _isGameOver = false;
  bool _isGameFrozen = false;

  // ── Basket bounce ──────────────────────────
  bool _isBasketBouncing = false;

  // ── Catch sparkle ──────────────────────────
  late AnimationController _sparkleController;
  late Animation<double> _sparkleOpacity;
  BlockColor? _lastCaughtColor;

  // ── Screen shake (on miss) ─────────────────
  late AnimationController _shakeController;
  late Animation<double> _shakeOffset;

  // ── Red flash overlay (on miss) ────────────
  late AnimationController _flashController;
  late Animation<double> _flashOpacity;

  // ── Win confetti ───────────────────────────
  late AnimationController _confettiController;
  final List<_ConfettiParticle> _confettiParticles = [];

  // ─────────────────────────────────────────────
  // LIFECYCLE
  // ─────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    currentLevelNumber = widget.startingLevel;

    // Game loop ticker (60 fps)
    _gameTicker = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..addListener(_onGameLoopTick);

    // Catch sparkle
    _sparkleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _sparkleOpacity = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 70),
    ]).animate(CurvedAnimation(parent: _sparkleController, curve: Curves.easeOut));

    // Screen shake
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );
    _shakeOffset = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -8.0), weight: 15),
      TweenSequenceItem(tween: Tween(begin: -8.0, end: 8.0), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 8.0, end: -6.0), weight: 20),
      TweenSequenceItem(tween: Tween(begin: -6.0, end: 6.0), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 6.0, end: 0.0), weight: 25),
    ]).animate(CurvedAnimation(parent: _shakeController, curve: Curves.linear));

    // Red flash
    _flashController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    _flashOpacity = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 0.35), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 0.35, end: 0.0), weight: 70),
    ]).animate(CurvedAnimation(parent: _flashController, curve: Curves.easeOut));

    // Confetti
    _confettiController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    _loadLevel(currentLevelNumber);
    try {
      ServiceLocator.instance.audioManager.playMiniGamesBgm();
    } catch (_) {}
  }

  @override
  void dispose() {
    _gameTicker.dispose();
    _sparkleController.dispose();
    _shakeController.dispose();
    _flashController.dispose();
    _confettiController.dispose();
    _comboTimer?.cancel();
    super.dispose();
  }

  // ─────────────────────────────────────────────
  // LEVEL MANAGEMENT
  // ─────────────────────────────────────────────

  void _loadLevel(int levelNum) {
    currentLevelNumber = levelNum;
    currentLevel = BasketCollectLevelGenerator.getLevel(levelNum);

    movesRemaining = currentLevel.moves;
    livesRemaining = currentLevel.maxMisses;
    currentScore = 0;
    _isLevelComplete = false;
    _isGameOver = false;
    _isGameFrozen = false;

    // Init per-color counters
    _caughtPerColor = {
      for (final color in currentLevel.targetRequirements.keys) color: 0,
    };

    _fallingBlocks.clear();
    _caughtPile.clear();
    _upcomingQueue.clear();
    _confettiParticles.clear();
    _lifeAnimatingIndex = -1;
    isMagnetActive = false;
    comboStreak = 0;
    comboText = null;

    // Fill upcoming queue
    for (int i = 0; i < 6; i++) {
      _upcomingQueue.add(BasketCollectLevelGenerator.getRandomColor(currentLevel));
    }

    _lastTickTime = DateTime.now();
    _lastSpawnTime = DateTime.now();

    _sparkleController.reset();
    _shakeController.reset();
    _flashController.reset();
    _confettiController.reset();

    if (!_gameTicker.isAnimating) {
      _gameTicker.repeat();
    }

    if (mounted) setState(() {});
  }

  // ─────────────────────────────────────────────
  // GAME LOOP (60 FPS)
  // ─────────────────────────────────────────────

  void _onGameLoopTick() {
    if (_isLevelComplete || _isGameOver || _isGameFrozen) return;

    final now = DateTime.now();
    if (_lastTickTime == null) {
      _lastTickTime = now;
      return;
    }

    final double dt =
        (now.difference(_lastTickTime!).inMicroseconds) / 1_000_000.0;
    _lastTickTime = now;

    // 1. Spawn new block
    if (_lastSpawnTime == null ||
        now.difference(_lastSpawnTime!).inMilliseconds >=
            currentLevel.spawnIntervalMs) {
      // Only one block on screen at a time (per spec)
      if (_fallingBlocks.isEmpty) {
        _spawnNextBlock();
        _lastSpawnTime = now;
      }
    }

    // 2. Update falling blocks
    // Calculate basket mouth position dynamically from screen size
    // so it always matches the basket's actual rendered position.
    final double sh = MediaQuery.of(context).size.height;
    final double sw = MediaQuery.of(context).size.width;

    // Center of basket in screen fraction (0.0 to 1.0)
    final double basketCenterX = 0.5 + basketX / 2.4;

    // Basket top edge (the back rim opening) in 0–1 screen Y fraction:
    // basket top = screen_height - _basketBottomOffset - _basketHeight
    final double basketTopY =
        1.0 - (_basketBottomOffset + _basketHeight) / sh;
    // Catch zone: block enters through the top mouth opening into the interior cavity
    final double catchMouthY = basketTopY + (_basketHeight * 0.18) / sh;
    final double catchDeepY = basketTopY + (_basketHeight * 0.52) / sh;

    // Basket X bounds (fraction of screen width)
    final double bwFrac = _basketWidth(sw) / sw;
    final double basketLeftFrac = basketCenterX - (bwFrac / 2.0) + 0.035;
    final double basketRightFrac = basketCenterX + (bwFrac / 2.0) - 0.035;

    for (int i = _fallingBlocks.length - 1; i >= 0; i--) {
      final block = _fallingBlocks[i];

      // Magnet pull
      if (isMagnetActive) {
        block.x += (basketCenterX - block.x) * dt * 4.0;
      }

      block.y += block.speed * dt;
      block.rotation += 0.35 * dt;

      // Collision with basket opening
      if (!block.isCaught && !block.isMissed) {
        if (block.y >= catchMouthY && block.y <= catchDeepY) {
          if (block.x >= basketLeftFrac && block.x <= basketRightFrac) {
            _catchBlock(block);
            _fallingBlocks.removeAt(i);
            continue;
          }
        }
      }

      // Block missed — fell past catch zone without being caught
      if (block.y > catchDeepY + 0.03) {
        _fallingBlocks.removeAt(i);
        _onBlockMissed(block);
      }
    }

    if (mounted) setState(() {});
  }

  void _spawnNextBlock() {
    if (_upcomingQueue.isEmpty) {
      _upcomingQueue.add(BasketCollectLevelGenerator.getRandomColor(currentLevel));
    }
    final color = _upcomingQueue.removeAt(0);
    _upcomingQueue.add(BasketCollectLevelGenerator.getRandomColor(currentLevel));

    final rng = Random();
    final double randomX = 0.12 + (rng.nextDouble() * 0.76);
    final double baseSpeed = 0.26 * currentLevel.fallSpeedMultiplier;

    _fallingBlocks.add(FallingBlock(
      id: _blockIdCounter++,
      x: randomX,
      y: -0.06,
      color: color,
      speed: baseSpeed + (rng.nextDouble() * 0.04),
      rotation: (rng.nextDouble() - 0.5) * 0.3,
    ));
  }

  // ─────────────────────────────────────────────
  // CATCH
  // ─────────────────────────────────────────────

  void _catchBlock(FallingBlock block) {
    block.isCaught = true;
    _lastCaughtColor = block.color;
    comboStreak++;
    currentScore += 100 + (comboStreak * 25);
    movesRemaining--;
    if (movesRemaining < 0) movesRemaining = 0;

    // Per-color counting
    if (currentLevel.targetRequirements.containsKey(block.color)) {
      _caughtPerColor[block.color] =
          (_caughtPerColor[block.color] ?? 0) + 1;
    }

    // Basket bounce
    setState(() => _isBasketBouncing = true);
    Future.delayed(const Duration(milliseconds: 150),
        () { if (mounted) setState(() => _isBasketBouncing = false); });

    // Sparkle
    _sparkleController.forward(from: 0);

    // Add to pile (max 12 visible) — structured pyramid heap filling the basket mouth
    final rng = Random();
    if (_caughtPile.length >= 12) {
      _caughtPile.removeAt(0);
    }
    const List<Offset> pileSlots = [
      // Base layer inside the rim
      Offset(-28, 14),
      Offset(-10, 16),
      Offset(10, 16),
      Offset(28, 14),
      // Middle layer in the mouth
      Offset(-18, 0),
      Offset(0, 2),
      Offset(18, 0),
      // Upper pyramid peak
      Offset(-11, -14),
      Offset(11, -14),
      Offset(0, -26),
      // Extra fill
      Offset(-22, -9),
      Offset(22, -9),
    ];
    final int idx = _caughtPile.length % pileSlots.length;
    final baseOffset = pileSlots[idx];
    _caughtPile.add(CaughtBlockItem(
      color: block.color,
      relativeOffsetX: baseOffset.dx + (rng.nextDouble() - 0.5) * 3.5,
      relativeOffsetY: baseOffset.dy + (rng.nextDouble() - 0.5) * 3.0,
      rotation: (rng.nextDouble() - 0.5) * 0.18,
    ));

    // Combo banner
    if (comboStreak >= 3) {
      _comboTimer?.cancel();
      setState(() => comboText = 'COMBO ×$comboStreak!');
      _comboTimer = Timer(const Duration(milliseconds: 900),
          () { if (mounted) setState(() => comboText = null); });
    }

    // Win check
    _checkWinCondition();

    // Moves-out check
    if (!_isLevelComplete && movesRemaining <= 0) {
      _triggerGameOver();
    }
  }

  void _checkWinCondition() {
    final allDone = currentLevel.targetRequirements.entries.every(
      (e) => (_caughtPerColor[e.key] ?? 0) >= e.value,
    );
    if (allDone) _triggerLevelComplete();
  }

  // ─────────────────────────────────────────────
  // MISS
  // ─────────────────────────────────────────────

  void _onBlockMissed(FallingBlock block) {
    comboStreak = 0;
    movesRemaining--;
    if (movesRemaining < 0) movesRemaining = 0;
    final lostIndex = livesRemaining - 1;
    livesRemaining--;
    if (livesRemaining < 0) livesRemaining = 0;

    setState(() => _lifeAnimatingIndex = lostIndex);
    _flashController.forward(from: 0);
    _shakeController.forward(from: 0);

    Future.delayed(const Duration(milliseconds: 600),
        () { if (mounted) setState(() => _lifeAnimatingIndex = -1); });

    if (livesRemaining <= 0 || movesRemaining <= 0) {
      // Brief freeze before game-over panel
      setState(() => _isGameFrozen = true);
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) _triggerGameOver();
      });
    }
  }

  // ─────────────────────────────────────────────
  // WIN / LOSE
  // ─────────────────────────────────────────────

  void _triggerLevelComplete() {
    _gameTicker.stop();
    currentScore += 1500 + (movesRemaining * 50);
    try { ServiceLocator.instance.coinManager.addCoins(250); } catch (_) {}
    currentCoins += 250;

    // Generate confetti
    final rng = Random();
    for (int i = 0; i < 20; i++) {
      _confettiParticles.add(_ConfettiParticle(
        x: rng.nextDouble(),
        color: [
          const Color(0xFFFFD700),
          const Color(0xFFFF5252),
          const Color(0xFF69F0AE),
          const Color(0xFF40C4FF),
          const Color(0xFFFF40FB),
        ][rng.nextInt(5)],
        speed: 0.3 + rng.nextDouble() * 0.5,
        size: 6 + rng.nextDouble() * 8,
        rotationSpeed: (rng.nextDouble() - 0.5) * 6,
      ));
    }

    setState(() => _isLevelComplete = true);
    _confettiController.forward();
  }

  void _triggerGameOver() {
    _gameTicker.stop();
    _shakeController.forward(from: 0);
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) setState(() => _isGameOver = true);
    });
  }

  // ─────────────────────────────────────────────
  // BOOSTERS
  // ─────────────────────────────────────────────

  void _onUseHammer() {
    if (hammerCount <= 0 || _fallingBlocks.isEmpty) return;
    setState(() {
      hammerCount--;
      _fallingBlocks.removeAt(0);
      currentScore += 50;
    });
  }

  void _onUseBomb() {
    if (bombCount <= 0 || _fallingBlocks.isEmpty) return;
    setState(() {
      bombCount--;
      _fallingBlocks.clear();
      currentScore += 150;
    });
  }

  void _onUseColorBomb() {
    if (colorBombCount <= 0) return;
    setState(() {
      colorBombCount--;
      isMagnetActive = true;
    });
    Timer(const Duration(seconds: 4),
        () { if (mounted) setState(() => isMagnetActive = false); });
  }

  void _onUseHint() {
    if (hintCount <= 0 || _fallingBlocks.isEmpty) return;
    setState(() {
      hintCount--;
      final first = _fallingBlocks.first;
      basketX = (first.x * 2.0) - 1.0;
    });
  }

  // ─────────────────────────────────────────────
  // HELPERS
  // ─────────────────────────────────────────────

  int get _totalGoal => currentLevel.targetRequirements.values
      .fold(0, (a, b) => a + b);

  int get _totalCaught => _caughtPerColor.values.fold(0, (a, b) => a + b);

  Color _blockColor(BlockColor c) => BlockColorMapper.getStyle(c).main;

  IconData _blockIcon(BlockColor c) =>
      BlockColorMapper.getStyle(c).normalIcon;

  // ─────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_shakeOffset, _flashOpacity]),
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(_shakeOffset.value, 0),
          child: Stack(
            children: [
              child!,
              // Red flash overlay on miss
              if (_flashOpacity.value > 0)
                Positioned.fill(
                  child: IgnorePointer(
                    child: Container(
                      color: Colors.red.withValues(alpha: _flashOpacity.value),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
      child: Scaffold(
        body: Stack(
          fit: StackFit.expand,
          children: [
            // ── 1. Garden background ────────────────────────────────────────
            Image.asset('assets/images/backgrounds/bg_garden.jpg',
                fit: BoxFit.cover),

            // ── 2. Background Dimming & Vignette Overlay ───────────────────
            // Soft dark tint ensures bright colorful blocks pop with clear visibility
            Container(
              color: Colors.black.withValues(alpha: 0.32),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withValues(alpha: 0.40),
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.50),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),

            // ── 3. BASKET BACK WALL (behind falling blocks) ─────────────────
            // The upper portion of the basket image rendered below blocks,
            // so blocks appear to fall IN FRONT of it toward the mouth.
            _buildBasketBackLayer(),

            // ── 4. Falling blocks canvas ─────────────────────────────────────
            // Blocks travel between the back wall (below) and front rim (above),
            // giving the true visual of entering the basket opening.
            _buildFallingBlocksLayer(),

            // ── 5. Caught pile inside basket (behind front rim) ──────────────
            _buildBasketCaughtPile(),

            // ── 6. BASKET FRONT RIM (in front of falling blocks) ────────────
            // The lower woven lip painted ON TOP of blocks — creates the
            // illusion that blocks physically sit INSIDE the basket.
            _buildBasketFrontRimLayer(),

            // ── 7. Basket drag zone ──────────────────────────────────────────
            _buildBasketDragZone(),

            // ── 8. Catch sparkle ─────────────────────────────────────────────
            if (_sparkleController.isAnimating || _sparkleController.value > 0)
              _buildCatchSparkle(),

            // ── 9. Confetti (win) ────────────────────────────────────────────
            if (_isLevelComplete) _buildConfettiLayer(),

            // ── 10. HUD (top bar + upcoming queue + boosters) ────────────────
            // Basket is no longer in this column — it lives as absolute layers.
            SafeArea(
              child: Column(
                children: [
                  const SizedBox(height: 4),
                  _buildTopHud(),
                  const SizedBox(height: 6),
                  Align(
                    alignment: Alignment.topRight,
                    child: _buildUpcomingQueuePanel(),
                  ),
                  const Spacer(),
                  if (comboText != null) _buildComboBanner(),
                  // Reserve space equal to basket height so booster bar
                  // doesn't overlap the basket.
                  const SizedBox(height: 140),
                  _buildBottomBoostersBar(),
                  const SizedBox(height: 8),
                ],
              ),
            ),

            // ── 11. Game Over overlay ────────────────────────────────────────
            if (_isGameOver) _buildGameOverOverlay(),

            // ── 12. Level Complete overlay ───────────────────────────────────
            if (_isLevelComplete) _buildLevelCompleteOverlay(),
          ],
        ),
      ),
    );
  }


  // ─────────────────────────────────────────────
  // TOP HUD
  // ─────────────────────────────────────────────

  Widget _buildTopHud() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Coins
          _buildCoinsCapsule(),
          const SizedBox(width: 8),

          // Center: Per-color goals
          Expanded(child: _buildGoalPanel()),

          const SizedBox(width: 8),

          // Right: Moves + Lives
          _buildMovesAndLivesPanel(),
        ],
      ),
    );
  }

  Widget _buildCoinsCapsule() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF8D5325), Color(0xFF5D3312)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFD54F), width: 1.8),
        boxShadow: const [
          BoxShadow(color: Color(0xFF2C1605), offset: Offset(0, 2), blurRadius: 0),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset('assets/images/icons/icon_coin.png', width: 20, height: 20),
          const SizedBox(width: 4),
          Text(
            '$currentCoins',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalPanel() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFE082), Color(0xFFFFB300), Color(0xFFFFA000)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFFF9EC), width: 2.0),
        boxShadow: const [
          BoxShadow(color: Color(0xFF8D5325), offset: Offset(0, 3), blurRadius: 0),
          BoxShadow(color: Colors.black26, offset: Offset(0, 3), blurRadius: 4),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'GOAL',
            style: TextStyle(
              color: Color(0xFF5D3312),
              fontSize: 9,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 3),
          // Per-color rows
          ...currentLevel.targetRequirements.entries.map((e) {
            final caught = _caughtPerColor[e.key] ?? 0;
            final needed = e.value;
            final done = caught >= needed;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 1.5),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _blockIcon(e.key),
                    color: done
                        ? const Color(0xFF2E7D32)
                        : _blockColor(e.key),
                    size: 13,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '$caught / $needed',
                    style: TextStyle(
                      color: done
                          ? const Color(0xFF1B5E20)
                          : const Color(0xFF3E200C),
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  if (done)
                    const Padding(
                      padding: EdgeInsets.only(left: 3),
                      child: Icon(Icons.check_circle_rounded,
                          color: Color(0xFF2E7D32), size: 11),
                    ),
                ],
              ),
            );
          }),
          // Overall mini progress bar
          const SizedBox(height: 3),
          SizedBox(
            width: double.infinity,
            height: 5,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: (_totalCaught / _totalGoal).clamp(0.0, 1.0),
                backgroundColor: const Color(0xFF8D5325),
                valueColor: const AlwaysStoppedAnimation(Color(0xFF69F0AE)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMovesAndLivesPanel() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF9EC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFD54F), width: 1.8),
        boxShadow: const [
          BoxShadow(color: Color(0xFF8D5325), offset: Offset(0, 2), blurRadius: 0),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Moves
          const Text(
            'MOVES',
            style: TextStyle(
              color: Color(0xFF7A4E24),
              fontSize: 8,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            '$movesRemaining',
            style: TextStyle(
              color: movesRemaining <= 3
                  ? const Color(0xFFD32F2F)
                  : const Color(0xFF3E200C),
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 3),
          // Lives hearts
          const Text(
            'LIVES',
            style: TextStyle(
              color: Color(0xFF7A4E24),
              fontSize: 8,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(currentLevel.maxMisses, (i) {
              final isAlive = i < livesRemaining;
              final isAnimatingOut = i == _lifeAnimatingIndex;
              return AnimatedScale(
                scale: isAnimatingOut ? 0.0 : 1.0,
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeInBack,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 1.0),
                  child: Icon(
                    isAlive ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                    color: isAlive
                        ? const Color(0xFFE53935)
                        : const Color(0xFFBCAAA4),
                    size: 14,
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 3),
          // Pause button
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFAB47BC), Color(0xFF6A1B9A)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.pause_rounded,
                  color: Colors.white, size: 14),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // UPCOMING QUEUE
  // ─────────────────────────────────────────────

  Widget _buildUpcomingQueuePanel() {
    return Container(
      margin: const EdgeInsets.only(right: 10),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF4E2A0E).withAlpha(220),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFD54F), width: 1.8),
        boxShadow: const [
          BoxShadow(color: Color(0xFF2C1605), offset: Offset(0, 3), blurRadius: 0),
          BoxShadow(color: Colors.black38, offset: Offset(0, 4), blurRadius: 6),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'NEXT',
            style: TextStyle(
              color: Color(0xFFFFE082),
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          ...List.generate(min(3, _upcomingQueue.length), (i) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 2.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Image.asset(
                  BlockColorMapper.getAssetPath(_upcomingQueue[i]),
                  width: 30,
                  height: 30,
                  fit: BoxFit.contain,
                ),
              ),
            );
          }),
          const SizedBox(height: 2),
          const Icon(Icons.arrow_drop_down, color: Color(0xFFFFD54F), size: 18),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // FALLING BLOCKS CANVAS
  // ─────────────────────────────────────────────

  Widget _buildFallingBlocksLayer() {
    final size = MediaQuery.of(context).size;

    return IgnorePointer(
      child: Stack(
        children: _fallingBlocks.map((block) {
          final posX = block.x * size.width - 28;
          final posY = block.y * size.height;

          return Positioned(
            left: posX,
            top: posY,
            child: Transform.rotate(
              angle: block.rotation,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Glow trail above block
                  Container(
                    width: 3,
                    height: 18,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.white.withAlpha(0),
                          Colors.white.withAlpha(140),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                  // 3D block PNG
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: BlockColorMapper.getStyle(block.color)
                              .glow
                              .withValues(alpha: 0.65),
                          blurRadius: 14,
                          spreadRadius: 2,
                        ),
                        const BoxShadow(
                          color: Colors.black45,
                          offset: Offset(0, 6),
                          blurRadius: 7,
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.asset(
                        BlockColorMapper.getAssetPath(block.color),
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // BASKET HELPERS — shared geometry
  // ─────────────────────────────────────────────

  double _basketWidth(double sw) =>
      (sw * _baseBasketWidthFraction * currentLevel.basketWidthFactor)
          .clamp(0.0, sw * 0.85);

  double _basketPixelX(double sw) =>
      sw / 2.0 + basketX * (sw / 2.4) - _basketWidth(sw) / 2.0;

  // Pixels from screen bottom where basket sits.
  // SizedBox(height: 140) in the HUD column reserves this space.
  static const double _basketBottomOffset = 90.0;
  static const double _basketHeight = 126.0;

  // ── 3. Basket BACK WALL & SIDE ARROWS (behind falling blocks) ───
  Widget _buildBasketBackLayer() {
    final sw = MediaQuery.of(context).size.width;
    final bw = _basketWidth(sw);
    final bx = _basketPixelX(sw);
    final scale = _isBasketBouncing ? 1.07 : 1.0;

    return Positioned(
      left: bx - 30,
      bottom: _basketBottomOffset,
      width: bw + 60,
      height: _basketHeight,
      child: Transform.scale(
        scale: scale,
        alignment: Alignment.bottomCenter,
        child: IgnorePointer(
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              // Left directional arrow
              Positioned(
                left: 0,
                child: _buildPulsingArrow(isLeft: true),
              ),
              // Right directional arrow
              Positioned(
                right: 0,
                child: _buildPulsingArrow(isLeft: false),
              ),
              // Full Basket texture
              Positioned(
                left: 30,
                right: 30,
                top: 0,
                bottom: 0,
                child: Image.asset(
                  'assets/images/home_screen/basket_woven.png',
                  fit: BoxFit.fill,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPulsingArrow({required bool isLeft}) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFB300).withValues(alpha: 0.5),
            blurRadius: 7,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Icon(
        isLeft ? Icons.arrow_left_rounded : Icons.arrow_right_rounded,
        color: const Color(0xFFFFD54F),
        size: 34,
        shadows: const [
          Shadow(color: Color(0xFFE65100), offset: Offset(0, 2), blurRadius: 3),
        ],
      ),
    );
  }

  // ── 5. Caught pile — inside basket mouth, forming a rich heap ───
  Widget _buildBasketCaughtPile() {
    final sw = MediaQuery.of(context).size.width;
    final bw = _basketWidth(sw);
    final bx = _basketPixelX(sw);
    // The pile sits prominently inside the basket mouth opening
    final pileLeft = bx + bw * 0.05;
    final pileWidth = bw * 0.90;
    final pileBottom = _basketBottomOffset + _basketHeight * 0.38;
    final scale = _isBasketBouncing ? 1.07 : 1.0;

    return Positioned(
      left: pileLeft,
      bottom: pileBottom,
      width: pileWidth,
      height: 84,
      child: Transform.scale(
        scale: scale,
        alignment: Alignment.bottomCenter,
        child: IgnorePointer(
          child: Stack(
            alignment: Alignment.center,
            children: _caughtPile.map((item) {
              return Transform.translate(
                offset: Offset(item.relativeOffsetX, item.relativeOffsetY),
                child: Transform.rotate(
                  angle: item.rotation,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(7),
                      boxShadow: [
                        BoxShadow(
                          color: BlockColorMapper.getStyle(item.color)
                              .glow
                              .withValues(alpha: 0.4),
                          blurRadius: 5,
                          spreadRadius: 1,
                        ),
                        const BoxShadow(
                          color: Colors.black45,
                          offset: Offset(0, 2),
                          blurRadius: 3,
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(7),
                      child: Image.asset(
                        BlockColorMapper.getAssetPath(item.color),
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  // ── 6. Basket FRONT RIM (covers only lower front wall) ──────────
  Widget _buildBasketFrontRimLayer() {
    final sw = MediaQuery.of(context).size.width;
    final bw = _basketWidth(sw);
    final bx = _basketPixelX(sw);
    final scale = _isBasketBouncing ? 1.07 : 1.0;

    return Positioned(
      left: bx,
      bottom: _basketBottomOffset,
      width: bw,
      height: _basketHeight,
      child: Transform.scale(
        scale: scale,
        alignment: Alignment.bottomCenter,
        child: IgnorePointer(
          child: ClipRect(
            clipper: const _BottomFractionClipper(0.44),
            child: Image.asset(
              'assets/images/home_screen/basket_woven.png',
              width: bw,
              height: _basketHeight,
              fit: BoxFit.fill,
              alignment: Alignment.bottomCenter,
            ),
          ),
        ),
      ),
    );
  }

  // ── 7. Drag zone — covers basket and side arrows ─────────────────
  Widget _buildBasketDragZone() {
    final sw = MediaQuery.of(context).size.width;
    final bw = _basketWidth(sw);
    final bx = _basketPixelX(sw);

    return Positioned(
      left: bx - 30,
      bottom: _basketBottomOffset,
      width: bw + 60,
      height: _basketHeight,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanUpdate: (details) {
          setState(() {
            basketX += (details.delta.dx / sw) * 2.0;
            basketX = basketX.clamp(-0.82, 0.82);
          });
        },
        child: const SizedBox.expand(),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // CATCH SPARKLE OVERLAY
  // ─────────────────────────────────────────────

  Widget _buildCatchSparkle() {
    final sw = MediaQuery.of(context).size.width;
    final sh = MediaQuery.of(context).size.height;
    final bx = _basketPixelX(sw) + _basketWidth(sw) / 2.0;
    final by = sh - _basketBottomOffset - _basketHeight * 0.70;

    return Positioned.fill(
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: _sparkleOpacity,
          builder: (ctx, _) {
            return CustomPaint(
              painter: _SparklePainter(
                opacity: _sparkleOpacity.value,
                color: _lastCaughtColor != null
                    ? BlockColorMapper.getStyle(_lastCaughtColor!).glow
                    : const Color(0xFFFFD700),
                centerX: bx,
                centerY: by,
              ),
            );
          },
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // COMBO BANNER
  // ─────────────────────────────────────────────

  Widget _buildComboBanner() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFD54F), Color(0xFFFF6D00)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: const [
          BoxShadow(color: Color(0xFFBF360C), offset: Offset(0, 3), blurRadius: 0),
        ],
      ),
      child: Text(
        comboText!,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.0,
          shadows: [
            Shadow(color: Colors.black54, offset: Offset(0, 2), blurRadius: 3),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // BOTTOM BOOSTERS BAR
  // ─────────────────────────────────────────────

  Widget _buildBottomBoostersBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF8D5325), Color(0xFF5D3312), Color(0xFF3E200C)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFFD54F), width: 2.0),
        boxShadow: const [
          BoxShadow(color: Color(0xFF2C1605), offset: Offset(0, 4), blurRadius: 0),
          BoxShadow(color: Colors.black45, offset: Offset(0, 6), blurRadius: 6),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildBoosterButton(
            assetPath: 'assets/images/boosters/hammer.png',
            count: hammerCount,
            onTap: _onUseHammer,
            label: 'Skip',
          ),
          _buildBoosterButton(
            assetPath: 'assets/images/boosters/bomb.png',
            count: bombCount,
            onTap: _onUseBomb,
            label: 'Clear',
          ),
          _buildBoosterButton(
            assetPath: 'assets/images/boosters/color_bomb.png',
            count: colorBombCount,
            onTap: _onUseColorBomb,
            label: 'Magnet',
          ),
          _buildHintLightbulbButton(),
        ],
      ),
    );
  }

  Widget _buildBoosterButton({
    required String assetPath,
    required int count,
    required VoidCallback onTap,
    required String label,
  }) {
    final bool disabled = count <= 0;
    return GestureDetector(
      onTap: disabled ? null : onTap,
      child: Opacity(
        opacity: disabled ? 0.45 : 1.0,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Color(0xFF9C27B0), Color(0xFF6A1B9A), Color(0xFF4A148C)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    border: Border.all(color: const Color(0xFFE1BEE7), width: 2.0),
                    boxShadow: const [
                      BoxShadow(color: Color(0xFF1A0033), offset: Offset(0, 2), blurRadius: 0),
                    ],
                  ),
                  child: Center(
                    child: Image.asset(assetPath,
                        width: 28, height: 28, fit: BoxFit.contain),
                  ),
                ),
                Positioned(
                  bottom: -2,
                  right: -2,
                  child: Container(
                    width: 17,
                    height: 17,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                          colors: [Color(0xFF81C784), Color(0xFF388E3C)]),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.2),
                    ),
                    child: Center(
                      child: Text(
                        '$count',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w900),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFFFFE082),
                fontSize: 8,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHintLightbulbButton() {
    return GestureDetector(
      onTap: _onUseHint,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFD54F), Color(0xFFFF9800), Color(0xFFE65100)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  border: Border.all(color: const Color(0xFFFFF9EC), width: 2.5),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0xFFFFB300),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(Icons.lightbulb_rounded, color: Colors.white, size: 28),
                ),
              ),
              Positioned(
                bottom: -2,
                right: -2,
                child: Container(
                  width: 17,
                  height: 17,
                  decoration: BoxDecoration(
                    color: const Color(0xFF8E24AA),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.2),
                  ),
                  child: Center(
                    child: Text(
                      '$hintCount',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w900),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          const Text(
            'Aim',
            style: TextStyle(
              color: Color(0xFFFFE082),
              fontSize: 8,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // CONFETTI LAYER
  // ─────────────────────────────────────────────

  Widget _buildConfettiLayer() {
    return AnimatedBuilder(
      animation: _confettiController,
      builder: (ctx, _) {
        final size = MediaQuery.of(ctx).size;
        final t = _confettiController.value;
        return IgnorePointer(
          child: Stack(
            children: _confettiParticles.map((p) {
              final y = -0.1 + (t * p.speed * size.height);
              final x = p.x * size.width;
              return Positioned(
                left: x,
                top: y,
                child: Transform.rotate(
                  angle: t * p.rotationSpeed,
                  child: Container(
                    width: p.size,
                    height: p.size * 0.55,
                    decoration: BoxDecoration(
                      color: p.color,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  // ─────────────────────────────────────────────
  // GAME OVER OVERLAY
  // ─────────────────────────────────────────────

  Widget _buildGameOverOverlay() {
    final progress = '$_totalCaught / $_totalGoal';

    return Container(
      color: Colors.black.withAlpha(170),
      child: Center(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutBack,
          builder: (ctx, v, child) =>
              Transform.scale(scale: v, child: child),
          child: Container(
            width: 290,
            padding: const EdgeInsets.fromLTRB(16, 22, 16, 20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF633A18), Color(0xFF4A2710)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
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
                // Title
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFEF5350), Color(0xFFB71C1C)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFFF8A80), width: 2),
                  ),
                  child: const Text(
                    'GAME OVER',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                      shadows: [
                        Shadow(color: Color(0xFF7F0000), offset: Offset(0, 2), blurRadius: 3),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                // Goal progress
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF9EC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFFD54F), width: 1.8),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Goal Progress',
                        style: TextStyle(
                          color: Color(0xFF7A4E24),
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 6),
                      ...currentLevel.targetRequirements.entries.map((e) {
                        final caught = _caughtPerColor[e.key] ?? 0;
                        final done = caught >= e.value;
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(_blockIcon(e.key),
                                  color: _blockColor(e.key), size: 14),
                              const SizedBox(width: 6),
                              Text(
                                '$caught / ${e.value}',
                                style: TextStyle(
                                  color: done
                                      ? const Color(0xFF2E7D32)
                                      : const Color(0xFF3E200C),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              if (done)
                                const Padding(
                                  padding: EdgeInsets.only(left: 4),
                                  child: Icon(Icons.check_circle_rounded,
                                      color: Color(0xFF2E7D32), size: 13),
                                ),
                            ],
                          ),
                        );
                      }),
                      const SizedBox(height: 4),
                      Text(
                        'Total: $progress',
                        style: const TextStyle(
                          color: Color(0xFF5D3312),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
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
                        label: 'RETRY',
                        colors: [const Color(0xFF42A5F5), const Color(0xFF1565C0)],
                        borderColor: const Color(0xFF90CAF9),
                        shadowColor: const Color(0xFF0D47A1),
                        onTap: () => _loadLevel(currentLevelNumber),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildDialogButton(
                        label: 'HOME',
                        colors: [const Color(0xFFEF9A9A), const Color(0xFFC62828)],
                        borderColor: const Color(0xFFEF5350),
                        shadowColor: const Color(0xFF7F0000),
                        onTap: () => Navigator.pop(context),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // LEVEL COMPLETE OVERLAY
  // ─────────────────────────────────────────────

  Widget _buildLevelCompleteOverlay() {
    return Container(
      color: Colors.black.withAlpha(160),
      child: Center(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 450),
          curve: Curves.elasticOut,
          builder: (ctx, v, child) =>
              Transform.scale(scale: v, child: child),
          child: Container(
            width: 320,
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF633A18), Color(0xFF4A2710)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFF8D5325), width: 5),
              boxShadow: const [
                BoxShadow(color: Color(0x99FFD700), blurRadius: 24, spreadRadius: 2),
                BoxShadow(color: Color(0xFF2C1605), offset: Offset(0, 8), blurRadius: 0),
                BoxShadow(color: Colors.black54, offset: Offset(0, 12), blurRadius: 16),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Banner
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
                    boxShadow: const [
                      BoxShadow(
                          color: Color(0x88FFD700), blurRadius: 12, spreadRadius: 1),
                    ],
                  ),
                  child: Text(
                    'LEVEL $currentLevelNumber COMPLETE!',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.8,
                      shadows: [
                        Shadow(
                            color: Color(0xFF1E5002),
                            offset: Offset(0, 2),
                            blurRadius: 3),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                // 3 Stars
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(3, (i) {
                    return TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: 1.0),
                      duration: Duration(milliseconds: 300 + i * 120),
                      curve: Curves.elasticOut,
                      builder: (ctx, v, _) => Transform.scale(
                        scale: v,
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 4.0),
                          child: Icon(Icons.star_rounded,
                              color: Color(0xFFFFD700), size: 44),
                        ),
                      ),
                    );
                  }),
                ),

                const SizedBox(height: 12),

                // Score & Coins
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
                          const Text('SCORE',
                              style: TextStyle(
                                  color: Color(0xFF7A4E24),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900)),
                          Text('$currentScore',
                              style: const TextStyle(
                                  color: Color(0xFF3E200C),
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900)),
                        ],
                      ),
                      Row(
                        children: [
                          Image.asset('assets/images/icons/icon_coin.png',
                              width: 24, height: 24),
                          const SizedBox(width: 4),
                          const Text('+250',
                              style: TextStyle(
                                  color: Color(0xFF3E200C),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900)),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Action buttons
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
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildDialogButton(
                        label: 'NEXT LEVEL',
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
    );
  }

  // ─────────────────────────────────────────────
  // SHARED DIALOG BUTTON
  // ─────────────────────────────────────────────

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
        height: 48,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: colors,
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: 1.8),
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
// CONFETTI PARTICLE DATA
// ─────────────────────────────────────────────

class _ConfettiParticle {
  final double x;
  final Color color;
  final double speed;
  final double size;
  final double rotationSpeed;

  _ConfettiParticle({
    required this.x,
    required this.color,
    required this.speed,
    required this.size,
    required this.rotationSpeed,
  });
}

// ─────────────────────────────────────────────
// CATCH SPARKLE PAINTER
// Renders a starburst of short radiating lines around the basket
// ─────────────────────────────────────────────

class _SparklePainter extends CustomPainter {
  final double opacity;
  final Color color;
  final double centerX;
  final double centerY;

  _SparklePainter({
    required this.opacity,
    required this.color,
    required this.centerX,
    required this.centerY,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (opacity <= 0) return;

    final paint = Paint()
      ..color = color.withValues(alpha: opacity * 0.85)
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final cx = centerX;
    final cy = centerY;
    const len = 24.0;
    const shortLen = 14.0;

    for (int i = 0; i < 8; i++) {
      final angle = (i / 8.0) * 2 * pi;
      final isLong = i % 2 == 0;
      final endLen = isLong ? len : shortLen;
      final startDist = isLong ? 16.0 : 12.0;

      canvas.drawLine(
        Offset(cx + cos(angle) * startDist, cy + sin(angle) * startDist),
        Offset(cx + cos(angle) * (startDist + endLen),
            cy + sin(angle) * (startDist + endLen)),
        paint,
      );
    }

    // Small glowing circle
    final circlePaint = Paint()
      ..color = Colors.white.withValues(alpha: opacity * 0.7)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(cx, cy), 7 * opacity, circlePaint);
  }

  @override
  bool shouldRepaint(_SparklePainter old) =>
      old.opacity != opacity ||
      old.color != color ||
      old.centerX != centerX ||
      old.centerY != centerY;
}
