class TutorialProgress {
  final String? currentTutorialId;
  final int currentStep;
  final List<String> completedTutorials;
  final List<String> skippedTutorials;
  final int tutorialVersion;

  const TutorialProgress({
    this.currentTutorialId,
    this.currentStep = 0,
    this.completedTutorials = const [],
    this.skippedTutorials = const [],
    this.tutorialVersion = 1,
  });

  static int? _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    return null;
  }

  factory TutorialProgress.fromJson(Map<String, dynamic> json) {
    return TutorialProgress(
      currentTutorialId: json['currentTutorialId'] as String?,
      currentStep: _parseInt(json['currentStep']) ?? 0,
      completedTutorials: (json['completedTutorials'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      skippedTutorials: (json['skippedTutorials'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      tutorialVersion: _parseInt(json['tutorialVersion']) ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'currentTutorialId': currentTutorialId,
      'currentStep': currentStep,
      'completedTutorials': completedTutorials,
      'skippedTutorials': skippedTutorials,
      'tutorialVersion': tutorialVersion,
    };
  }

  TutorialProgress copyWith({
    String? currentTutorialId,
    int? currentStep,
    List<String>? completedTutorials,
    List<String>? skippedTutorials,
    int? tutorialVersion,
    bool clearCurrent = false,
  }) {
    return TutorialProgress(
      currentTutorialId: clearCurrent ? null : (currentTutorialId ?? this.currentTutorialId),
      currentStep: clearCurrent ? 0 : (currentStep ?? this.currentStep),
      completedTutorials: completedTutorials ?? this.completedTutorials,
      skippedTutorials: skippedTutorials ?? this.skippedTutorials,
      tutorialVersion: tutorialVersion ?? this.tutorialVersion,
    );
  }
}
