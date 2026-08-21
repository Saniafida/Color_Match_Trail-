abstract class AchievementEvent {
  const AchievementEvent();
}

class BlockBlastEvent extends AchievementEvent {
  final int count;
  final bool isMegaBlast;
  const BlockBlastEvent(this.count, {this.isMegaBlast = false});
}

class ComboEvent extends AchievementEvent {
  final int comboMultiplier;
  const ComboEvent(this.comboMultiplier);
}

class LevelCompletedEvent extends AchievementEvent {
  final String levelId;
  final int stars;
  const LevelCompletedEvent(this.levelId, this.stars);
}

class BoosterUsedEvent extends AchievementEvent {
  final String boosterId;
  const BoosterUsedEvent(this.boosterId);
}

class ChallengeCompletedEvent extends AchievementEvent {
  final String challengeId;
  const ChallengeCompletedEvent(this.challengeId);
}

class WorldCompletedEvent extends AchievementEvent {
  final String worldId;
  const WorldCompletedEvent(this.worldId);
}
