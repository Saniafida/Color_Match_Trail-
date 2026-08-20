enum OnboardingStep {
  connectColors,
  blast,
  gravity,
  largeMatch,
  cascade,
  goals,
  moves,
  booster,
  complete,
}

extension OnboardingStepExtension on OnboardingStep {
  int get index2 => OnboardingStep.values.indexOf(this);

  String get title {
    switch (this) {
      case OnboardingStep.connectColors: return 'CONNECT MATCHING COLORS';
      case OnboardingStep.blast: return 'BLAST!';
      case OnboardingStep.gravity: return 'NEW BLOCKS FALL IN';
      case OnboardingStep.largeMatch: return 'LONGER MATCH = BIGGER BLAST';
      case OnboardingStep.cascade: return 'CASCADE!';
      case OnboardingStep.goals: return 'COMPLETE THE GOALS TO WIN';
      case OnboardingStep.moves: return 'USE YOUR MOVES CAREFULLY';
      case OnboardingStep.booster: return 'USE BOOSTERS FOR HELP';
      case OnboardingStep.complete: return 'YOU\'RE READY!';
    }
  }

  String get description {
    switch (this) {
      case OnboardingStep.connectColors:
        return 'Tap and drag through blocks of the same color to match them.';
      case OnboardingStep.blast:
        return 'Matched blocks blast away! Clear blocks to earn points.';
      case OnboardingStep.gravity:
        return 'New blocks fall in from above to fill the board.';
      case OnboardingStep.largeMatch:
        return 'Match more blocks at once for a bigger, more powerful blast!';
      case OnboardingStep.cascade:
        return 'New matches can happen automatically after a blast — that\'s a cascade!';
      case OnboardingStep.goals:
        return 'Each level has goals. Clear the right blocks to complete them.';
      case OnboardingStep.moves:
        return 'You have a limited number of moves. Plan carefully!';
      case OnboardingStep.booster:
        return 'Tap a booster then tap a block to remove it instantly.';
      case OnboardingStep.complete:
        return 'Great job! You\'re ready to play Color Match Trail!';
    }
  }
}
