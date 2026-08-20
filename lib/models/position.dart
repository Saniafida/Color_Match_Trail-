class Position {
  final int row;
  final int column;

  const Position(this.row, this.column)
      : assert(row >= 0, 'row cannot be negative'),
        assert(column >= 0, 'column cannot be negative');

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Position && other.row == row && other.column == column;
  }

  @override
  int get hashCode => row.hashCode ^ column.hashCode;

  Position copyWith({
    int? row,
    int? column,
  }) {
    return Position(
      row ?? this.row,
      column ?? this.column,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'row': row,
      'column': column,
    };
  }

  factory Position.fromJson(Map<String, dynamic> json) {
    return Position(
      json['row'] as int,
      json['column'] as int,
    );
  }

  @override
  String toString() => 'Position($row, $column)';
}
