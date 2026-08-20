class ColorDefinition {
  final String colorId;
  final String displayNameKey;
  final String visualAsset;
  final bool enabled;

  const ColorDefinition({
    required this.colorId,
    required this.displayNameKey,
    required this.visualAsset,
    this.enabled = true,
  });

  factory ColorDefinition.fromJson(Map<String, dynamic> json) {
    return ColorDefinition(
      colorId: json['colorId'] as String,
      displayNameKey: json['displayNameKey'] as String? ?? '',
      visualAsset: json['visualAsset'] as String? ?? '',
      enabled: json['enabled'] as bool? ?? true,
    );
  }
}
