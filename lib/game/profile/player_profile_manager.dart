import 'dart:math';
import 'package:flutter/foundation.dart';

import 'player_profile.dart';
import 'player_statistics.dart';
import 'profile_validator.dart';
import 'player_xp_manager.dart';
import 'avatar_definition.dart';
import '../../core/storage/game_save_manager.dart';
import '../../core/services/analytics/analytics_manager.dart';

/// Manages the player's profile identity and statistics.
class PlayerProfileManager extends ChangeNotifier {
  final GameSaveManager saveManager;
  final AnalyticsManager analyticsManager;

  late PlayerProfile _profile;
  PlayerProfile get profile => _profile;

  final List<AvatarDefinition> _availableAvatars = const [
    AvatarDefinition(avatarId: 'default', assetPath: 'assets/avatars/default.png', isDefault: true),
    AvatarDefinition(avatarId: 'star_player', assetPath: 'assets/avatars/star.png', unlockDescriptionKey: 'Reach Level 10'),
    AvatarDefinition(avatarId: 'champion', assetPath: 'assets/avatars/champion.png', unlockDescriptionKey: 'Win 50 Games', rarity: 3),
  ];

  List<AvatarDefinition> get availableAvatars => _availableAvatars;

  PlayerProfileManager({
    required this.saveManager,
    required this.analyticsManager,
  });

  void initialize() {
    _loadFromStorage();
  }

  void _loadFromStorage() {
    final rawProfileMap = saveManager.playerData.profile;
    
    if (rawProfileMap.isEmpty) {
      _createNewProfile();
    } else {
      _profile = PlayerProfile(
        playerId: rawProfileMap['playerId'] as String? ?? _generateId(),
        displayName: rawProfileMap['displayName'] as String? ?? _generateDefaultName(),
        avatarId: rawProfileMap['avatarId'] as String? ?? 'default',
        playerLevel: rawProfileMap['playerLevel'] as int? ?? 1,
        xp: rawProfileMap['xp'] as int? ?? 0,
        createdAt: rawProfileMap['createdAt'] != null ? DateTime.parse(rawProfileMap['createdAt'] as String) : DateTime.now(),
        updatedAt: rawProfileMap['updatedAt'] != null ? DateTime.parse(rawProfileMap['updatedAt'] as String) : DateTime.now(),
        statistics: PlayerStatistics.fromMap(saveManager.playerData.statistics),
      );
    }
    
    // Ensure data is valid on load
    _profile = _profile.copyWith(
      displayName: ProfileValidator.sanitizeDisplayName(_profile.displayName, _generateDefaultName()),
      statistics: ProfileValidator.validateStatistics(_profile.statistics),
      playerLevel: PlayerXPManager.calculateLevel(_profile.xp),
    );
  }

  void _createNewProfile() {
    _profile = PlayerProfile(
      playerId: _generateId(),
      displayName: _generateDefaultName(),
      avatarId: 'default',
      createdAt: DateTime.now().toUtc(),
      updatedAt: DateTime.now().toUtc(),
    );
    _saveToStorage();
  }

  String _generateId() {
    final rand = Random();
    return 'p_${DateTime.now().millisecondsSinceEpoch}_${rand.nextInt(9999)}';
  }

  String _generateDefaultName() {
    return 'Player${Random().nextInt(9999).toString().padLeft(4, '0')}';
  }

  Future<void> updateIdentity({String? newName, String? newAvatarId}) async {
    String cleanName = _profile.displayName;
    if (newName != null) {
      cleanName = ProfileValidator.sanitizeDisplayName(newName, _profile.displayName);
      analyticsManager.logEvent('display_name_changed');
    }

    String finalAvatarId = _profile.avatarId;
    if (newAvatarId != null) {
      finalAvatarId = newAvatarId;
      analyticsManager.logEvent('avatar_changed', parameters: {'id': newAvatarId});
    }

    _profile = _profile.copyWith(
      displayName: cleanName,
      avatarId: finalAvatarId,
      updatedAt: DateTime.now().toUtc(),
    );
    
    notifyListeners();
    await _saveToStorage();
    analyticsManager.logEvent('profile_edited');
  }

  /// Called by gameplay systems to increment statistics safely.
  Future<void> updateStatistics(PlayerStatistics Function(PlayerStatistics current) updater, {int addedXp = 0}) async {
    PlayerStatistics newStats = updater(_profile.statistics);
    newStats = ProfileValidator.validateStatistics(newStats);
    
    int newXp = _profile.xp + addedXp;
    int newLevel = PlayerXPManager.calculateLevel(newXp);

    _profile = _profile.copyWith(
      statistics: newStats,
      xp: newXp,
      playerLevel: newLevel,
      updatedAt: DateTime.now().toUtc(),
    );

    notifyListeners();
    await _saveToStorage();
  }

  Future<void> _saveToStorage() async {
    // Convert to maps
    final profileMap = {
      'playerId': _profile.playerId,
      'displayName': _profile.displayName,
      'avatarId': _profile.avatarId,
      'playerLevel': _profile.playerLevel,
      'xp': _profile.xp,
      'createdAt': _profile.createdAt.toIso8601String(),
      'updatedAt': _profile.updatedAt.toIso8601String(),
    };
    
    final statsMap = _profile.statistics.toMap();

    // The single authoritative truth is GameSaveManager.
    // It writes atomically and hashes the payload automatically (Module 40).
    saveManager.updateFullData(
      saveManager.playerData.copyWith(
        profile: profileMap,
        statistics: statsMap,
      )
    );
  }
}
