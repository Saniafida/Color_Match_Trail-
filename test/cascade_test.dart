import 'package:flutter_test/flutter_test.dart';
import 'package:color_match_trail/models/models.dart';
import 'package:color_match_trail/game/board/board.dart';
import 'package:color_match_trail/game/blocks/blocks.dart';
import 'package:color_match_trail/game/gravity/gravity.dart';
import 'package:color_match_trail/game/blast/blast.dart';
import 'package:color_match_trail/game/specials/special.dart';
import 'package:color_match_trail/game/cascade/cascade.dart';

void main() {
  group('CascadeController Tests', () {
    late BoardController boardController;
    late Map<String, Block> blocks;
    late GravityController gravityController;
    late BlastController blastController;
    late BoardMatchScanner matchScanner;
    late CascadeController cascadeController;

    void addBlock(Position pos, BlockColor color, {String? id}) {
      var block = BlockFactory.createBlock(color: color, position: pos);
      if (id != null) block = block.copyWith(id: id);
      
      blocks[block.id] = block;
      boardController.setBlockId(pos, block.id);
    }

    void fillSafeBoard() {
      // Use different colors for every cell by forcing 5 different colors diagonally
      final colors = [BlockColor.red, BlockColor.green, BlockColor.blue, BlockColor.yellow, BlockColor.purple];
      for (int r = 0; r < 5; r++) {
        for (int c = 0; c < 5; c++) {
          addBlock(Position(r, c), colors[(r + c) % colors.length]);
        }
      }
    }

    setUp(() {
      boardController = BoardController(rows: 5, columns: 5);
      blocks = {};
      
      gravityController = GravityController(
        boardController: boardController,
        getBlock: (id) => blocks[id],
        onUpdateBlock: (b) => blocks[b.id] = b,
        onCreateBlock: (b) {
          final colors = [BlockColor.red, BlockColor.green, BlockColor.blue, BlockColor.yellow, BlockColor.purple];
          final safeColor = colors[(b.position.row + b.position.column) % colors.length];
          blocks[b.id] = b.copyWith(color: safeColor);
        },
      );

      blastController = BlastController(
        boardController: boardController,
        getBlock: (id) => blocks[id],
        onUpdateBlock: (b) => blocks[b.id] = b,
        onRemoveBlock: (id) => blocks.remove(id),
        specialController: SpecialController(boardController: boardController, getBlock: (id) => blocks[id]),
      );

      matchScanner = BoardMatchScanner(
        boardController: boardController,
        getBlock: (id) => blocks[id],
        minimumConnectionLength: 3,
      );

      cascadeController = CascadeController(
        matchScanner: matchScanner,
        blastController: blastController,
        gravityController: gravityController,
        maxCascadeIterations: 2,
      );
    });

    test('TEST 1: Board has no match', () async {
      fillSafeBoard();
      final result = await cascadeController.startCascade([BlockColor.blue]);
      expect(result.cascadeLevel, 0);
    });

    test('TEST 2: One automatic 3-block match (now disabled)', () async {
      fillSafeBoard();
      addBlock(const Position(0, 0), BlockColor.green);
      addBlock(const Position(0, 1), BlockColor.green);
      addBlock(const Position(0, 2), BlockColor.green);

      final result = await cascadeController.startCascade([BlockColor.red]);
      // Automatic cascades are disabled, so these should be 0
      expect(result.cascadeLevel, 0);
      expect(result.totalDestroyedBlocks, 0);
    });

    test('TEST 5: Multiple independent matches (now disabled)', () async {
      fillSafeBoard();
      
      addBlock(const Position(0, 0), BlockColor.green);
      addBlock(const Position(0, 1), BlockColor.green);
      addBlock(const Position(0, 2), BlockColor.green);
      
      addBlock(const Position(4, 0), BlockColor.green);
      addBlock(const Position(4, 1), BlockColor.green);
      addBlock(const Position(4, 2), BlockColor.green);

      final result = await cascadeController.startCascade([BlockColor.red]);
      // Automatic cascades are disabled, so these should be 0
      expect(result.cascadeLevel, 0);
      expect(result.totalDestroyedBlocks, 0);
    });
  });
}
