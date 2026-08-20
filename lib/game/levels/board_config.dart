class BoardConfig {
  final int rows;
  final int columns;

  const BoardConfig({
    required this.rows,
    required this.columns,
  });

  factory BoardConfig.fromJson(Map<String, dynamic> json) {
    return BoardConfig(
      rows: json['rows'] as int? ?? 6,
      columns: json['columns'] as int? ?? 6,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'rows': rows,
      'columns': columns,
    };
  }
}
