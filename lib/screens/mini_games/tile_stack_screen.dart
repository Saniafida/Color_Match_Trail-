import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../game/blocks/block_color_mapper.dart';
import '../../game/basket_collect/basket_collect_level_model.dart';
import '../../game/basket_collect/basket_collect_level_generator.dart';
import '../../core/services/service_locator.dart';

class FallingBlock {
  final int id;
  double x; // 0.0 to 1.0 relative screen width
  double y; // 0.0 to 1.0 relative screen height
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

class TileStackScreen extends StatefulWidget {
  final int startingLevel;

  const TileStackScreen({
    super.key,
    this.startingLevel = 5,
  });

  @override
  State<TileStackScreen> createState() => _TileStackScreenState();
}

class _TileStackScreenState extends State<TileStackScreen>
    with SingleTickerProviderStateMixin {
  late int currentLevelNumber;
  late BasketCollectLevel currentLevel;

  // Game Stats
  late int movesRemaining;
  int currentCoins = 1250;
  int currentScore = 2350;
  late int collectedGoalCount;

  // Basket Horizontal Position (-1.0 to 1.0)
  double basketX = 0.0;
  final double basketWidthFraction = 0.58;

  // Falling Blocks Engine
  final List<FallingBlock> _fallingBlocks = [];
  final List<BlockColor> _upcomingQueue = [];
  final List<CaughtBlockItem> _caughtPile = [];
  int _blockIdCounter = 0;

  // Boosters
  int hammerCount = 3;
  int bombCount = 3;
  int colorBombCount = 3;
  int hintCount = 1;
  bool isMagnetActive = false;

  // Combo System
  int comboStreak = 0;
  String? comboText;
  Timer? _comboTimer;

  // Game Loop Ticker
  late AnimationController _gameTicker;
  DateTime? _lastTickTime;
  DateTime? _lastSpawnTime;

  // Win State & Animations
  bool _isLevelComplete = false;
  bool _isBasketBouncing = false;

  @override
  void initState() {
    super.initState();
    currentLevelNumber = widget.startingLevel;
    _gameTicker = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..addListener(_onGameLoopTick);

    _loadLevel(currentLevelNumber);
  }

  @override
  void dispose() {
    _gameTicker.dispose();
    _comboTimer?.cancel();
    super.dispose();
  }

  void _loadLevel(int levelNum) {
    currentLevelNumber = levelNum;
    currentLevel = BasketCollectLevelGenerator.getLevel(levelNum);

    movesRemaining = currentLevel.moves;
    collectedGoalCount = 0;
    _fallingBlocks.clear();
    _caughtPile.clear();
    _upcomingQueue.clear();
    _isLevelComplete = false;
    isMagnetActive = false;
    comboStreak = 0;
    comboText = null;

    // Fill initial upcoming queue
    for (int i = 0; i < 6; i++) {
      _upcomingQueue.add(BasketCollectLevelGenerator.getRandomColor(currentLevel));
    }

    _lastTickTime = DateTime.now();
    _lastSpawnTime = DateTime.now();

    if (!_gameTicker.isAnimating) {
      _gameTicker.repeat();
    }

    if (mounted) setState(() {});
  }

  // ==========================================
  // 🕹️ 60 FPS GAME LOOP & PHYSICS
  // ==========================================
  void _onGameLoopTick() {
    if (_isLevelComplete) return;

    final now = DateTime.now();
    if (_lastTickTime == null) {
      _lastTickTime = now;
      return;
    }

    final double dt = (now.difference(_lastTickTime!).inMicroseconds) / 1000000.0;
    _lastTickTime = now;

    // 1. Spawning New Blocks
    if (_lastSpawnTime == null ||
        now.difference(_lastSpawnTime!).inMilliseconds >= currentLevel.spawnIntervalMs) {
      _spawnNextBlock();
      _lastSpawnTime = now;
    }

    // 2. Updating Falling Blocks
    const double basketTopY = 0.68;
    const double basketBottomY = 0.76;

    for (int i = _fallingBlocks.length - 1; i >= 0; i--) {
      final block = _fallingBlocks[i];

      // Magnet effect if active: pull toward basket
      if (isMagnetActive) {
        final double targetX = (basketX + 1.0) / 2.0;
        block.x += (targetX - block.x) * dt * 4.0;
      }

      // Normal falling motion
      block.y += block.speed * dt;
      block.rotation += 0.4 * dt;

      // 3. Collision Detection with Basket
      final double basketLeft = (basketX + 1.0) / 2.0 - (basketWidthFraction / 2.0) + 0.05;
      final double basketRight = (basketX + 1.0) / 2.0 + (basketWidthFraction / 2.0) - 0.05;

      if (!block.isCaught && !block.isMissed) {
        if (block.y >= basketTopY && block.y <= basketBottomY) {
          if (block.x >= basketLeft && block.x <= basketRight) {
            _catchBlock(block);
            _fallingBlocks.removeAt(i);
            continue;
          }
        }
      }

      // 4. Missed block fell past screen
      if (block.y > 0.88) {
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
    final double randomX = 0.15 + (rng.nextDouble() * 0.70); // Centered horizontal range
    final double baseSpeed = 0.28 * currentLevel.fallSpeedMultiplier;

    _fallingBlocks.add(
      FallingBlock(
        id: _blockIdCounter++,
        x: randomX,
        y: -0.05,
        color: color,
        speed: baseSpeed + (rng.nextDouble() * 0.06),
        rotation: (rng.nextDouble() - 0.5) * 0.4,
      ),
    );
  }

  void _catchBlock(FallingBlock block) {
    block.isCaught = true;
    collectedGoalCount++;
    currentScore += 100 + (comboStreak * 25);
    comboStreak++;

    // Trigger basket bounce
    setState(() {
      _isBasketBouncing = true;
    });
    Future.delayed(const Duration(milliseconds: 140), () {
      if (mounted) setState(() => _isBasketBouncing = false);
    });

    // Add to visually rendered pile in basket
    final rng = Random();
    if (_caughtPile.length < 18) {
      _caughtPile.add(
        CaughtBlockItem(
          color: block.color,
          relativeOffsetX: (rng.nextDouble() - 0.5) * 100,
          relativeOffsetY: (rng.nextDouble() - 0.5) * 35,
          rotation: (rng.nextDouble() - 0.5) * 0.35,
        ),
      );
    }

    // Combo text banner
    if (comboStreak >= 3) {
      _comboTimer?.cancel();
      setState(() {
        comboText = 'COMBO x$comboStreak!';
      });
      _comboTimer = Timer(const Duration(milliseconds: 800), () {
        if (mounted) setState(() => comboText = null);
      });
    }

    // Check Win Condition
    if (collectedGoalCount >= currentLevel.goalTotal) {
      _triggerLevelComplete();
    }
  }

  void _onBlockMissed(FallingBlock block) {
    comboStreak = 0;
  }

  void _triggerLevelComplete() {
    _gameTicker.stop();
    setState(() {
      _isLevelComplete = true;
      currentScore += 1500 + (movesRemaining * 50);
      currentCoins += 250;
    });
    try {
      ServiceLocator.instance.coinManager.addCoins(250);
    } catch (_) {}
  }

  // ==========================================
  // 💣 BOOSTER ACTIONS
  // ==========================================
  void _onUseHammer() {
    if (hammerCount <= 0 || _fallingBlocks.isEmpty) return;
    setState(() {
      hammerCount--;
      _fallingBlocks.removeAt(0);
      currentScore += 150;
    });
  }

  void _onUseBomb() {
    if (bombCount <= 0 || _fallingBlocks.isEmpty) return;
    setState(() {
      bombCount--;
      _fallingBlocks.clear();
      currentScore += 300;
    });
  }

  void _onUseColorBomb() {
    if (colorBombCount <= 0) return;
    setState(() {
      colorBombCount--;
      isMagnetActive = true;
    });
    Timer(const Duration(seconds: 4), () {
      if (mounted) setState(() => isMagnetActive = false);
    });
  }

  void _onUseHint() {
    if (hintCount <= 0 || _fallingBlocks.isEmpty) return;
    setState(() {
      hintCount--;
      // Magnet nearest falling block
      final first = _fallingBlocks.first;
      basketX = (first.x * 2.0) - 1.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Fullscreen Sunny Enchanted Garden Background
          Image.asset(
            'assets/images/backgrounds/bg_garden.jpg',
            fit: BoxFit.cover,
          ),

          // 2. Subtle Vignette
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.black.withAlpha(30),
                  Colors.transparent,
                  Colors.black.withAlpha(60),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),

          // 3. Falling Blocks Canvas Layer
          _buildFallingBlocksLayer(),

          // 4. Interactive Touch Canvas for Basket Dragging
          GestureDetector(
            onHorizontalDragUpdate: (details) {
              final screenWidth = MediaQuery.of(context).size.width;
              setState(() {
                basketX += (details.delta.dx / screenWidth) * 2.2;
                basketX = basketX.clamp(-0.85, 0.85);
              });
            },
            child: Container(color: Colors.transparent),
          ),

          // 5. Main Screen HUD & UI
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 4),

                // TOP HUD: Coins, Goal Banner, Moves, Pause
                _buildTopHud(),

                const SizedBox(height: 6),

                // RIGHT SIDE UPCOMING QUEUE ("NEXT" box)
                Align(
                  alignment: Alignment.topRight,
                  child: _buildUpcomingQueuePanel(),
                ),

                const Spacer(),

                // COMBO BANNER (Floating if active)
                if (comboText != null) _buildComboBanner(),

                // BASKET AT BOTTOM
                _buildPlayerBasketArea(),

                const SizedBox(height: 4),

                // INSTRUCTION PILL: "Catch the blocks! Collect and reach the goal!"
                _buildInstructionPill(),

                const SizedBox(height: 6),

                // BOTTOM BOOSTER CONTROLS: Pause, Hammer, Bomb, Rainbow Pinwheel, Hint
                _buildBottomBoostersBar(),

                const SizedBox(height: 8),
              ],
            ),
          ),

          // 6. LEVEL COMPLETE CELEBRATION OVERLAY
          if (_isLevelComplete) _buildLevelCompleteOverlay(),
        ],
      ),
    );
  }

  // ==========================================
  // 🏆 TOP HUD
  // ==========================================
  Widget _buildTopHud() {
    final double progress = (collectedGoalCount / currentLevel.goalTotal).clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 1. Coins Capsule: 🪙 1,250 (+)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
              children: [
                Image.asset('assets/images/icons/icon_coin.png', width: 22, height: 22),
                const SizedBox(width: 4),
                Text(
                  '$currentCoins',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.all(1.5),
                  decoration: const BoxDecoration(
                    color: Color(0xFF4CAF50),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.add, color: Colors.white, size: 10),
                ),
              ],
            ),
          ),

          // 2. Center Hanging Goal Banner: "GOAL 60" + Progress Bar & 3 Stars
          Container(
            width: 140,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
                    fontSize: 10.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
                  ),
                ),
                Text(
                  '${currentLevel.goalTotal - collectedGoalCount}',
                  style: const TextStyle(
                    color: Color(0xFF3E200C),
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                // Progress Bar with 3 Stars
                Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      height: 7,
                      width: 110,
                      decoration: BoxDecoration(
                        color: const Color(0xFF8D5325),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: progress,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF69F0AE), Color(0xFF00E676)],
                            ),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(3, (i) {
                        final reached = progress >= ((i + 1) / 3.0);
                        return Icon(
                          Icons.star_rounded,
                          color: reached ? const Color(0xFFFFD700) : const Color(0xFFBCAAA4),
                          size: 13,
                        );
                      }),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 3. Moves Box: "MOVES 25" + Pause Button
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF9EC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFFD54F), width: 1.8),
                  boxShadow: const [
                    BoxShadow(color: Color(0xFF8D5325), offset: Offset(0, 2), blurRadius: 0),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'MOVES',
                      style: TextStyle(
                        color: Color(0xFF7A4E24),
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      '$movesRemaining',
                      style: const TextStyle(
                        color: Color(0xFF3E200C),
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 5),
              _buildPurpleCircleBtn(
                icon: Icons.pause_rounded,
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPurpleCircleBtn({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            colors: [Color(0xFFAB47BC), Color(0xFF7B1FA2), Color(0xFF4A148C)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          border: Border.all(color: const Color(0xFFE1BEE7), width: 1.8),
          boxShadow: const [
            BoxShadow(color: Color(0xFF2A0040), offset: Offset(0, 2), blurRadius: 0),
          ],
        ),
        child: Center(
          child: Icon(icon, color: Colors.white, size: 19),
        ),
      ),
    );
  }

  // ==========================================
  // 📦 UPCOMING QUEUE ("NEXT" BOX)
  // ==========================================
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
                  width: 32,
                  height: 32,
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

  // ==========================================
  // ✨ FALLING BLOCKS CANVAS LAYER
  // ==========================================
  Widget _buildFallingBlocksLayer() {
    final size = MediaQuery.of(context).size;

    return IgnorePointer(
      child: Stack(
        children: _fallingBlocks.map((block) {
          final posX = block.x * size.width - 24;
          final posY = block.y * size.height;

          return Positioned(
            left: posX,
            top: posY,
            child: Transform.rotate(
              angle: block.rotation,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Vertical Light Beam Glow Trail
                  Container(
                    width: 4,
                    height: 22,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.white.withAlpha(0),
                          Colors.white.withAlpha(160),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                  // 3D Block
                  Container(
                    width: 48,
                    height: 48,
                    decoration: const BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          offset: Offset(0, 4),
                          blurRadius: 4,
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

  // ==========================================
  // 🧺 PLAYER BASKET AT BOTTOM
  // ==========================================
  Widget _buildPlayerBasketArea() {
    final size = MediaQuery.of(context).size;
    final basketPixelX = (basketX * (size.width / 2.4));

    return Transform.translate(
      offset: Offset(basketPixelX, 0),
      child: AnimatedScale(
        scale: _isBasketBouncing ? 1.08 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: SizedBox(
          width: size.width * basketWidthFraction,
          height: 140,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              // Directional Left & Right Glowing Orange Arrows
              Positioned(
                left: -32,
                child: _buildDirectionalArrow(isLeft: true),
              ),
              Positioned(
                right: -32,
                child: _buildDirectionalArrow(isLeft: false),
              ),

              // 3D Woven Basket Asset
              Image.asset(
                'assets/images/home_screen/basket_woven.png',
                fit: BoxFit.contain,
              ),

              // Collected Blocks Heap Inside Basket
              Positioned(
                bottom: 35,
                child: SizedBox(
                  width: 140,
                  height: 60,
                  child: Stack(
                    alignment: Alignment.center,
                    children: _caughtPile.map((item) {
                      return Transform.translate(
                        offset: Offset(item.relativeOffsetX, item.relativeOffsetY),
                        child: Transform.rotate(
                          angle: item.rotation,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: Image.asset(
                              BlockColorMapper.getAssetPath(item.color),
                              width: 26,
                              height: 26,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDirectionalArrow({required bool isLeft}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!isLeft) const SizedBox(width: 4),
        Icon(
          isLeft ? Icons.arrow_left_rounded : Icons.arrow_right_rounded,
          color: const Color(0xFFFFB300),
          size: 32,
          shadows: const [
            Shadow(color: Color(0xFFE65100), offset: Offset(0, 2), blurRadius: 3),
          ],
        ),
        if (isLeft) const SizedBox(width: 4),
      ],
    );
  }

  Widget _buildComboBanner() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
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

  // ==========================================
  // 💡 INSTRUCTION PILL
  // ==========================================
  Widget _buildInstructionPill() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF311B92).withAlpha(220),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFBA68C8), width: 1.5),
        boxShadow: const [
          BoxShadow(color: Colors.black45, offset: Offset(0, 2), blurRadius: 4),
        ],
      ),
      child: const Column(
        children: [
          Text(
            'Catch the blocks!',
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            'Collect and reach the goal!',
            style: TextStyle(
              color: Color(0xFFFFD54F),
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // 💣 BOTTOM BOOSTERS BAR
  // ==========================================
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
          // 1. Pause Button (Bottom left)
          _buildPurpleCircleBtn(
            icon: Icons.pause_rounded,
            onTap: () => Navigator.pop(context),
          ),

          // 2. Hammer Booster
          _buildBoosterButton(
            assetPath: 'assets/images/boosters/hammer.png',
            count: hammerCount,
            onTap: _onUseHammer,
          ),

          // 3. Bomb Booster
          _buildBoosterButton(
            assetPath: 'assets/images/boosters/bomb.png',
            count: bombCount,
            onTap: _onUseBomb,
          ),

          // 4. Rainbow Pinwheel / Color Bomb Booster
          _buildBoosterButton(
            assetPath: 'assets/images/boosters/color_bomb.png',
            count: colorBombCount,
            onTap: _onUseColorBomb,
          ),

          // 5. Golden Glowing Lightbulb Hint Booster
          _buildHintLightbulbButton(),
        ],
      ),
    );
  }

  Widget _buildBoosterButton({
    required String assetPath,
    required int count,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Container(
            width: 48,
            height: 48,
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
              child: Image.asset(assetPath, width: 30, height: 30, fit: BoxFit.contain),
            ),
          ),
          Positioned(
            bottom: -2,
            right: -2,
            child: Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF81C784), Color(0xFF388E3C)],
                ),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.2),
              ),
              child: Center(
                child: Text(
                  '$count',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHintLightbulbButton() {
    return GestureDetector(
      onTap: _onUseHint,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Container(
            width: 54,
            height: 54,
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
              child: Icon(Icons.lightbulb_rounded, color: Colors.white, size: 30),
            ),
          ),
          Positioned(
            bottom: -2,
            right: -2,
            child: Container(
              width: 18,
              height: 18,
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
                    fontSize: 9.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
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
                        Image.asset('assets/images/icons/icon_coin.png', width: 24, height: 24),
                        const SizedBox(width: 4),
                        const Text(
                          '+250',
                          style: TextStyle(color: Color(0xFF3E200C), fontSize: 16, fontWeight: FontWeight.w900),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Action Buttons: REPLAY & NEXT LEVEL
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
