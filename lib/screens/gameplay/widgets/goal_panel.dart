import 'package:flutter/material.dart';
import '../../../game/goals/goal_controller.dart';
import '../../../game/goals/goal_state.dart';
import '../../../models/models.dart';
import '../../../game/blocks/block_widget.dart';
import '../../../game/boosters/booster_definition.dart';

class GoalPanel extends StatelessWidget {
  final GoalController goalController;

  const GoalPanel({
    super.key,
    required this.goalController,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: goalController,
      builder: (context, child) {
        final stateList = goalController.states;
        if (stateList.isEmpty) return const SizedBox.shrink();

        return Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.topCenter,
          children: [
            // Foliage leaves and two white jasmine flowers on top corners
            Positioned(
              top: -8,
              left: 4,
              right: 4,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildFlowerCluster(),
                  _buildFlowerCluster(isFlipped: true),
                ],
              ),
            ),

            // Main Carved Wood Signboard
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(6, 4, 6, 6),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF6B3A18),
                    Color(0xFF45220A),
                    Color(0xFF2B1304),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFFFFD54F),
                  width: 2.0,
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0xFF1E0C02),
                    offset: Offset(0, 3),
                    blurRadius: 0,
                  ),
                  BoxShadow(
                    color: Colors.black54,
                    offset: Offset(0, 4),
                    blurRadius: 6,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header text: "Goal"
                  const Text(
                    'Goal',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.6,
                      shadows: [
                        Shadow(color: Color(0xFF1A0A02), offset: Offset(0, 1.5), blurRadius: 2),
                        Shadow(color: Colors.black54, offset: Offset(0, 2), blurRadius: 3),
                      ],
                    ),
                  ),

                  const SizedBox(height: 3),

                  // Goal items row: wrapped in FittedBox for 100% responsiveness
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: stateList.map((goalState) {
                        final def = goalController.getDefinition(goalState.goalId);
                        return GoalItemWidget(
                          key: ValueKey(goalState.goalId),
                          def: def,
                          goalState: goalState,
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFlowerCluster({bool isFlipped = false}) {
    return Transform.scale(
      scaleX: isFlipped ? -1 : 1,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Green leaves
          Transform.rotate(
            angle: -0.35,
            child: const Icon(Icons.eco_rounded, color: Color(0xFF66BB6A), size: 15),
          ),
          // White flower blossom with yellow center
          Transform.translate(
            offset: const Offset(-3, -1),
            child: Container(
              width: 14,
              height: 14,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    offset: Offset(0, 1),
                    blurRadius: 2,
                  ),
                ],
              ),
              child: Center(
                child: Container(
                  width: 5.5,
                  height: 5.5,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFD54F),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ),
          Transform.rotate(
            angle: 0.35,
            child: const Icon(Icons.eco_rounded, color: Color(0xFF43A047), size: 13),
          ),
        ],
      ),
    );
  }
}

class GoalItemWidget extends StatefulWidget {
  final GoalDefinition def;
  final GoalState goalState;

  const GoalItemWidget({
    super.key,
    required this.def,
    required this.goalState,
  });

  @override
  State<GoalItemWidget> createState() => _GoalItemWidgetState();
}

class _GoalItemWidgetState extends State<GoalItemWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _bounceController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.18).chain(CurveTween(curve: Curves.easeOutQuad)),
        weight: 45,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.18, end: 1.0).chain(CurveTween(curve: Curves.easeInQuad)),
        weight: 55,
      ),
    ]).animate(_bounceController);
  }

  @override
  void didUpdateWidget(covariant GoalItemWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.goalState.currentAmount != oldWidget.goalState.currentAmount ||
        widget.goalState.completed != oldWidget.goalState.completed) {
      _bounceController.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _bounceController.dispose();
    super.dispose();
  }

  Widget _buildTargetVisual() {
    final def = widget.def;
    const double blockSize = 24.0;

    // 1. Color blocks (Real Game Block)
    if (def.type == GoalType.clearColor && def.color != null) {
      return BlockWidget(
        block: Block(
          id: 'goal_block_${def.id}',
          color: def.color!,
          position: const Position(0, 0),
        ),
        size: blockSize,
      );
    }

    // 2. Clear any blocks
    if (def.type == GoalType.clearBlocks) {
      return BlockWidget(
        block: Block(
          id: 'goal_block_${def.id}',
          color: def.color ?? BlockColor.yellow,
          position: const Position(0, 0),
        ),
        size: blockSize,
      );
    }

    // 3. Special power-up block
    if (def.type == GoalType.createSpecial ||
        def.type == GoalType.activateSpecial ||
        def.type == GoalType.destroySpecial ||
        def.specialType != null) {
      final specialType = def.specialType ?? SpecialBlockType.smallArea;
      return BlockWidget(
        block: Block(
          id: 'goal_special_${def.id}',
          color: def.color ?? BlockColor.red,
          position: const Position(0, 0),
          type: BlockType.rocket,
          specialType: specialType,
        ),
        size: blockSize,
      );
    }

    // 4. Booster usage
    if (def.type == GoalType.useBooster && def.boosterType != null) {
      final boosterDef = BoosterDefinition.registry[def.boosterType!];
      return Icon(
        boosterDef?.icon ?? Icons.auto_fix_high_rounded,
        color: Colors.amberAccent,
        size: 22,
      );
    }

    // 5. Score goal
    if (def.type == GoalType.score) {
      return const Icon(
        Icons.stars_rounded,
        color: Color(0xFFFFD700),
        size: 22,
      );
    }

    // 6. Cascade combo goal
    if (def.type == GoalType.reachCascade) {
      return const Icon(
        Icons.bolt_rounded,
        color: Colors.cyanAccent,
        size: 22,
      );
    }

    return const Icon(
      Icons.flag_rounded,
      color: Colors.amber,
      size: 22,
    );
  }

  @override
  Widget build(BuildContext context) {
    final progress = widget.goalState.currentAmount;
    final target = widget.goalState.targetAmount;
    final isCompleted = widget.goalState.completed;

    return ScaleTransition(
      scale: _scaleAnimation,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 2.5),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isCompleted
                ? const [Color(0xFF1B3D20), Color(0xFF0F2412)]
                : const [Color(0xFF261205), Color(0xFF140A03)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isCompleted
                ? const Color(0xFF69F0AE)
                : const Color(0xFF8D5325),
            width: 1.3,
          ),
          boxShadow: isCompleted
              ? const [
                  BoxShadow(
                    color: Color(0x6669F0AE),
                    blurRadius: 5,
                    spreadRadius: 1,
                  ),
                ]
              : const [
                  BoxShadow(
                    color: Colors.black45,
                    offset: Offset(0, 1.5),
                    blurRadius: 2.5,
                  ),
                ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Real block with optional completion badge
            Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                _buildTargetVisual(),
                if (isCompleted)
                  Positioned(
                    right: -3,
                    bottom: -3,
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF1B140E),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.greenAccent, width: 1.5),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.greenAccent,
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(1.2),
                      child: const Icon(
                        Icons.check_rounded,
                        color: Colors.greenAccent,
                        size: 9.5,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 4.5),
            Text(
              isCompleted ? 'DONE' : '$progress / $target',
              style: TextStyle(
                color: isCompleted ? const Color(0xFF69F0AE) : Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 12.0,
                letterSpacing: 0.3,
                shadows: const [
                  Shadow(
                    color: Colors.black,
                    offset: Offset(0, 1),
                    blurRadius: 2,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
