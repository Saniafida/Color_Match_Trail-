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

  factory TutorialProgress.fromJson(Map<String, dynamic> json) {
    return TutorialProgress(
      currentTutorialId: json['currentTutorialId'] as String?,
      currentStep: json['currentStep'] as int? ?? 0,
      completedTutorials: (json['completedTutorials'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
      skippedTutorials: (json['skippedTutorials'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
      tutorialVersion: json['tutorialVersion'] as int? ?? 1,
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
