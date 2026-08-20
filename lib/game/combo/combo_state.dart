class ComboState {
  final int level;
  final double multiplier;
  final DateTime? lastEventTime;
  
  const ComboState({
    this.level = 0,
    this.multiplier = 1.0,
    this.lastEventTime,
  });
  
  bool get isActive => level > 0;
}
