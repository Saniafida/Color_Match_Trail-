import 'package:intl/intl.dart';

class ScoreFormatter {
  static final _formatter = NumberFormat.decimalPattern();

  static String format(int score) {
    return _formatter.format(score);
  }
}
