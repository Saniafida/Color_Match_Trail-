import 'audio_priority.dart';
import 'audio_type.dart';

class SoundDefinition {
  final String id;
  final String assetPath;
  final AudioType type;
  final double volume;
  final double pitch;
  final bool loop;
  final AudioPriority priority;

  const SoundDefinition({
    required this.id,
    required this.assetPath,
    required this.type,
    this.volume = 1.0,
    this.pitch = 1.0,
    this.loop = false,
    this.priority = AudioPriority.normal,
  });

  SoundDefinition copyWith({
    String? id,
    String? assetPath,
    AudioType? type,
    double? volume,
    double? pitch,
    bool? loop,
    AudioPriority? priority,
  }) {
    return SoundDefinition(
      id: id ?? this.id,
      assetPath: assetPath ?? this.assetPath,
      type: type ?? this.type,
      volume: volume ?? this.volume,
      pitch: pitch ?? this.pitch,
      loop: loop ?? this.loop,
      priority: priority ?? this.priority,
    );
  }
}
