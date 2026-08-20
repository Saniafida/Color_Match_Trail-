/// Defines an unlockable avatar.
class AvatarDefinition {
  final String avatarId;
  final String assetPath;
  final bool isDefault;
  final String unlockDescriptionKey;
  final int rarity; // e.g. 1 = Common, 5 = Legendary

  const AvatarDefinition({
    required this.avatarId,
    required this.assetPath,
    this.isDefault = false,
    this.unlockDescriptionKey = 'avatar_default',
    this.rarity = 1,
  });
}
