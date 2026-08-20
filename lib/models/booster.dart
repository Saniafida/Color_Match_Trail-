enum BoosterType { hammer, shuffle, rowClear, colorClear, extraMoves }

class BoosterInventory {
  final Map<BoosterType, int> quantities;

  const BoosterInventory({
    this.quantities = const {},
  });

  int getQuantity(BoosterType type) => quantities[type] ?? 0;

  BoosterInventory copyWith({
    Map<BoosterType, int>? quantities,
  }) {
    return BoosterInventory(
      quantities: quantities ?? this.quantities,
    );
  }

  BoosterInventory increment(BoosterType type, [int amount = 1]) {
    final newQuantities = Map<BoosterType, int>.from(quantities);
    newQuantities[type] = getQuantity(type) + amount;
    return copyWith(quantities: newQuantities);
  }

  BoosterInventory decrement(BoosterType type, [int amount = 1]) {
    final current = getQuantity(type);
    if (current < amount) {
      throw ArgumentError('Cannot decrement below zero');
    }
    final newQuantities = Map<BoosterType, int>.from(quantities);
    newQuantities[type] = current - amount;
    return copyWith(quantities: newQuantities);
  }

  Map<String, dynamic> toJson() {
    return quantities.map((key, value) => MapEntry(key.name, value));
  }

  factory BoosterInventory.fromJson(Map<String, dynamic> json) {
    final Map<BoosterType, int> loaded = {};
    for (var entry in json.entries) {
      final type = BoosterType.values.firstWhere(
        (e) => e.name == entry.key,
        orElse: () => BoosterType.hammer,
      );
      loaded[type] = entry.value as int;
    }
    return BoosterInventory(quantities: loaded);
  }
}
