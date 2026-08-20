class LevelValidationResult {
  final bool isValid;
  final List<String> errors;
  final List<String> warnings;

  const LevelValidationResult({
    required this.isValid,
    this.errors = const [],
    this.warnings = const [],
  });

  factory LevelValidationResult.valid() {
    return const LevelValidationResult(isValid: true);
  }

  factory LevelValidationResult.invalid(List<String> errors, [List<String> warnings = const []]) {
    return LevelValidationResult(
      isValid: false,
      errors: errors,
      warnings: warnings,
    );
  }

  @override
  String toString() {
    return 'LevelValidationResult(isValid: $isValid, errors: $errors, warnings: $warnings)';
  }
}
