import '../../moves/move_controller.dart';

class ExtraMovesEffect {
  static Future<void> execute(MoveController moveController) async {
    moveController.addMoves(5);
    await Future.delayed(const Duration(milliseconds: 300));
  }
}
