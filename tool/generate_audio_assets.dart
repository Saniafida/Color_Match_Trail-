// ignore_for_file: avoid_print
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

void main() {
  print('🎵 Starting Audio Assets Generation...');

  final directories = [
    'assets/sounds/ui',
    'assets/sounds/gameplay',
    'assets/sounds/blocks',
    'assets/sounds/blast',
    'assets/sounds/combo',
    'assets/sounds/boosters',
    'assets/sounds/minigames',
    'assets/sounds/events',
    'assets/sounds/music',
  ];

  for (final dir in directories) {
    Directory(dir).createSync(recursive: true);
  }

  // 1. UI SOUNDS
  _saveWav('assets/sounds/ui/btn_click.wav', _generateClick());
  _saveWav('assets/sounds/ui/popup_open.wav', _generateWhooshUp());
  _saveWav('assets/sounds/ui/popup_close.wav', _generateWhooshDown());
  _saveWav('assets/sounds/ui/coin_collect.wav', _generateCoinChime());
  _saveWav('assets/sounds/ui/gem_collect.wav', _generateGemSparkle());
  _saveWav('assets/sounds/ui/chest_open.wav', _generateChestOpen());
  _saveWav('assets/sounds/ui/wheel_spin.wav', _generateWheelTick());
  _saveWav('assets/sounds/ui/wheel_win.wav', _generateJackpotFanfare());
  _saveWav('assets/sounds/ui/shop_buy.wav', _generateShopCash());
  _saveWav('assets/sounds/ui/achievement_unlock.wav', _generateAchievementChime());
  _saveWav('assets/sounds/ui/switch_toggle.wav', _generateSwitchToggle());

  // 2. GAMEPLAY & BLOCKS
  _saveWav('assets/sounds/blocks/tile_tap.wav', _generateSoftTap());
  _saveWav('assets/sounds/gameplay/trail_drag.wav', _generateWaterChime());
  _saveWav('assets/sounds/blocks/match.wav', _generateMatchPop());
  _saveWav('assets/sounds/blast/blast.wav', _generateBlast(isLarge: false));
  _saveWav('assets/sounds/blast/blast_large.wav', _generateBlast(isLarge: true));
  _saveWav('assets/sounds/combo/combo.wav', _generateComboChime());
  _saveWav('assets/sounds/blocks/tile_drop.wav', _generateWoodThud());
  _saveWav('assets/sounds/ui/goal_complete.wav', _generateGoalComplete());
  _saveWav('assets/sounds/events/star_earn.wav', _generateStarEarn());

  // 3. EVENTS (WIN / FAIL)
  _saveWav('assets/sounds/events/success.wav', _generateLevelWin());
  _saveWav('assets/sounds/events/fail.wav', _generateLevelFail());

  // 4. BOOSTERS
  _saveWav('assets/sounds/boosters/booster_hammer.wav', _generateHammerSmash());
  _saveWav('assets/sounds/boosters/booster_bomb.wav', _generateBombExplode());
  _saveWav('assets/sounds/boosters/booster_color_bomb.wav', _generateColorBombRainbow());
  _saveWav('assets/sounds/boosters/booster_shuffle.wav', _generateShuffleWhoosh());
  _saveWav('assets/sounds/boosters/booster_extra_moves.wav', _generatePowerupJingle());

  // 5. MINI-GAMES SFX
  // Tile Swap
  _saveWav('assets/sounds/minigames/swap_slide.wav', _generateFastWhoosh());
  _saveWav('assets/sounds/minigames/swap_invalid.wav', _generateInvalidWobble());
  _saveWav('assets/sounds/minigames/line_blast.wav', _generateLineLaserBlast());
  _saveWav('assets/sounds/minigames/color_bomb_blast.wav', _generateColorBombRainbow());
  // Tile Drop
  _saveWav('assets/sounds/minigames/drop_slide_pod.wav', _generateRatchetTick());
  _saveWav('assets/sounds/minigames/drop_hard_landing.wav', _generateHardLanding());
  _saveWav('assets/sounds/minigames/drop_danger_alert.wav', _generateDangerAlert());
  // Tile Stack
  _saveWav('assets/sounds/minigames/stack_piece_pick.wav', _generateSoftTap());
  _saveWav('assets/sounds/minigames/stack_piece_place.wav', _generateSnapClick());
  _saveWav('assets/sounds/minigames/stack_line_clear.wav', _generateHarmonicGlassClear());
  _saveWav('assets/sounds/minigames/stack_game_over.wav', _generateLevelFail());
  // Tile Sort
  _saveWav('assets/sounds/minigames/tube_cork_open.wav', _generateCorkPop());
  _saveWav('assets/sounds/minigames/liquid_pour.wav', _generateLiquidTrickle());
  _saveWav('assets/sounds/minigames/tube_done_sparkle.wav', _generateGoalComplete());

  // 6. BACKGROUND MUSIC LOOPS
  _saveWav('assets/sounds/music/bgm_home.wav', _generateBgmMelody(type: 0));
  _saveWav('assets/sounds/music/bgm_gameplay.wav', _generateBgmMelody(type: 1));
  _saveWav('assets/sounds/music/bgm_minigames.wav', _generateBgmMelody(type: 2));

  print('✅ Successfully generated all Audio Assets in assets/sounds/!');
}

// ─────────────────────────────────────────────
// WAV FILE WRITER (16-bit PCM Mono, 44.1kHz)
// ─────────────────────────────────────────────

void _saveWav(String path, List<double> samples, {int sampleRate = 44100}) {
  final numSamples = samples.length;
  final byteRate = sampleRate * 2; // 16-bit mono = 2 bytes per sample
  final dataSize = numSamples * 2;
  final fileSize = 36 + dataSize;

  final bytes = ByteData(44 + dataSize);

  // RIFF header
  bytes.setUint8(0, 0x52); // 'R'
  bytes.setUint8(1, 0x49); // 'I'
  bytes.setUint8(2, 0x46); // 'F'
  bytes.setUint8(3, 0x46); // 'F'
  bytes.setUint32(4, fileSize, Endian.little);
  bytes.setUint8(8, 0x57); // 'W'
  bytes.setUint8(9, 0x41); // 'A'
  bytes.setUint8(10, 0x56); // 'V'
  bytes.setUint8(11, 0x45); // 'E'

  // fmt subchunk
  bytes.setUint8(12, 0x66); // 'f'
  bytes.setUint8(13, 0x6D); // 'm'
  bytes.setUint8(14, 0x74); // 't'
  bytes.setUint8(15, 0x20); // ' '
  bytes.setUint32(16, 16, Endian.little); // Subchunk1Size for PCM
  bytes.setUint16(20, 1, Endian.little); // AudioFormat (1 = PCM)
  bytes.setUint16(22, 1, Endian.little); // NumChannels (1 = Mono)
  bytes.setUint32(24, sampleRate, Endian.little);
  bytes.setUint32(28, byteRate, Endian.little);
  bytes.setUint16(32, 2, Endian.little); // BlockAlign
  bytes.setUint16(34, 16, Endian.little); // BitsPerSample

  // data subchunk
  bytes.setUint8(36, 0x64); // 'd'
  bytes.setUint8(37, 0x61); // 'a'
  bytes.setUint8(38, 0x74); // 't'
  bytes.setUint8(39, 0x61); // 'a'
  bytes.setUint32(40, dataSize, Endian.little);

  // Write 16-bit PCM samples
  int offset = 44;
  for (int i = 0; i < numSamples; i++) {
    final clamped = samples[i].clamp(-1.0, 1.0);
    final intSample = (clamped * 32767).toInt();
    bytes.setInt16(offset, intSample, Endian.little);
    offset += 2;
  }

  File(path).writeAsBytesSync(bytes.buffer.asUint8List());
}

// ─────────────────────────────────────────────
// SYNTHESIS GENERATORS
// ─────────────────────────────────────────────

List<double> _generateClick() {
  const sr = 44100;
  const duration = 0.04;
  final count = (sr * duration).toInt();
  final out = List<double>.filled(count, 0.0);

  for (int i = 0; i < count; i++) {
    final t = i / sr;
    final env = exp(-t * 90);
    final freq = 1200.0 - t * 8000;
    out[i] = sin(2 * pi * freq * t) * env * 0.7;
  }
  return out;
}

List<double> _generateSoftTap() {
  const sr = 44100;
  const duration = 0.035;
  final count = (sr * duration).toInt();
  final out = List<double>.filled(count, 0.0);
  final rnd = Random(5678);

  for (int i = 0; i < count; i++) {
    final t = i / sr;
    final env = exp(-t * 120.0);
    final f = 680.0 * exp(-t * 15.0);
    final click = (t < 0.0025) ? (rnd.nextDouble() * 2.0 - 1.0) * 0.25 : 0.0;
    out[i] = (sin(2 * pi * f * t) * 0.7 + click) * env * 0.55;
  }
  return out;
}

List<double> _generateSnapClick() {
  const sr = 44100;
  const duration = 0.045;
  final count = (sr * duration).toInt();
  final out = List<double>.filled(count, 0.0);

  for (int i = 0; i < count; i++) {
    final t = i / sr;
    final env = exp(-t * 80.0);
    final freq = 920.0 * exp(-t * 25.0);
    out[i] = sin(2 * pi * freq * t) * env * 0.65;
  }
  return out;
}

List<double> _generateMatchPop() {
  const sr = 44100;
  const duration = 0.12;
  final count = (sr * duration).toInt();
  final out = List<double>.filled(count, 0.0);

  for (int i = 0; i < count; i++) {
    final t = i / sr;
    final env = exp(-t * 26.0) * (1.0 - exp(-t * 250.0));
    final freq = 520.0 + 380.0 * (1.0 - exp(-t * 35.0)); // Ascending sweet bubble pop
    final tone = sin(2 * pi * freq * t);
    final harmonic = sin(2 * pi * freq * 2.0 * t) * 0.25;
    out[i] = (tone + harmonic) * env * 0.8;
  }
  return out;
}

List<double> _generateBlast({required bool isLarge}) {
  const sr = 44100;
  final duration = isLarge ? 0.35 : 0.22;
  final count = (sr * duration).toInt();
  final out = List<double>.filled(count, 0.0);
  final rnd = Random(42);

  for (int i = 0; i < count; i++) {
    final t = i / sr;
    final env = exp(-t * (isLarge ? 9.0 : 16.0));
    final subFreq = (isLarge ? 70.0 : 110.0) * exp(-t * 5);
    final sub = sin(2 * pi * subFreq * t);
    final noise = (rnd.nextDouble() * 2.0 - 1.0) * exp(-t * 22);
    out[i] = (sub * 0.7 + noise * 0.4) * env * 0.9;
  }
  return out;
}

List<double> _generateComboChime() {
  const sr = 44100;
  const duration = 0.32;
  final count = (sr * duration).toInt();
  final out = List<double>.filled(count, 0.0);

  // Ascending arpeggio (C5 -> E5 -> G5)
  final notes = [523.25, 659.25, 783.99];
  final noteDur = duration / notes.length;

  for (int i = 0; i < count; i++) {
    final t = i / sr;
    final noteIdx = (t / noteDur).floor().clamp(0, notes.length - 1);
    final noteTime = t - noteIdx * noteDur;
    final freq = notes[noteIdx];
    final env = exp(-noteTime * 14.0);
    out[i] = sin(2 * pi * freq * t) * env * 0.75;
  }
  return out;
}

List<double> _generateCoinChime() {
  const sr = 44100;
  const duration = 0.28;
  final count = (sr * duration).toInt();
  final out = List<double>.filled(count, 0.0);

  // Twin bell frequency chime (987.77 Hz B5, 1318.51 Hz E6)
  for (int i = 0; i < count; i++) {
    final t = i / sr;
    final env = exp(-t * 12.0);
    final tone1 = sin(2 * pi * 987.77 * t);
    final tone2 = sin(2 * pi * 1318.51 * t);
    out[i] = (tone1 * 0.5 + tone2 * 0.5) * env * 0.8;
  }
  return out;
}

List<double> _generateGemSparkle() {
  const sr = 44100;
  const duration = 0.25;
  final count = (sr * duration).toInt();
  final out = List<double>.filled(count, 0.0);

  for (int i = 0; i < count; i++) {
    final t = i / sr;
    final env = exp(-t * 15.0);
    final freq = 1760.0 + sin(2 * pi * 25 * t) * 80;
    out[i] = sin(2 * pi * freq * t) * env * 0.7;
  }
  return out;
}

List<double> _generateWhooshUp() {
  const sr = 44100;
  const duration = 0.16;
  final count = (sr * duration).toInt();
  final out = List<double>.filled(count, 0.0);
  final rnd = Random(123);

  for (int i = 0; i < count; i++) {
    final t = i / sr;
    final env = sin(pi * (t / duration));
    final noise = rnd.nextDouble() * 2.0 - 1.0;
    final toneFreq = 200.0 + 800.0 * (t / duration);
    final tone = sin(2 * pi * toneFreq * t);
    out[i] = (tone * 0.5 + noise * 0.3) * env * 0.7;
  }
  return out;
}

List<double> _generateWhooshDown() {
  const sr = 44100;
  const duration = 0.14;
  final count = (sr * duration).toInt();
  final out = List<double>.filled(count, 0.0);
  final rnd = Random(456);

  for (int i = 0; i < count; i++) {
    final t = i / sr;
    final env = sin(pi * (t / duration));
    final noise = rnd.nextDouble() * 2.0 - 1.0;
    final toneFreq = 900.0 - 650.0 * (t / duration);
    final tone = sin(2 * pi * toneFreq * t);
    out[i] = (tone * 0.5 + noise * 0.3) * env * 0.65;
  }
  return out;
}

List<double> _generateFastWhoosh() {
  const sr = 44100;
  const duration = 0.10;
  final count = (sr * duration).toInt();
  final out = List<double>.filled(count, 0.0);
  final rnd = Random(789);

  for (int i = 0; i < count; i++) {
    final t = i / sr;
    final env = sin(pi * (t / duration));
    final noise = rnd.nextDouble() * 2.0 - 1.0;
    out[i] = noise * env * 0.6;
  }
  return out;
}

List<double> _generateInvalidWobble() {
  const sr = 44100;
  const duration = 0.20;
  final count = (sr * duration).toInt();
  final out = List<double>.filled(count, 0.0);

  for (int i = 0; i < count; i++) {
    final t = i / sr;
    final env = exp(-t * 12.0);
    final freq = 140.0 + sin(2 * pi * 30 * t) * 40; // Wobble frequency
    out[i] = sin(2 * pi * freq * t) * env * 0.7;
  }
  return out;
}

List<double> _generateWoodThud() {
  const sr = 44100;
  const duration = 0.055; // Snappy 55ms organic wooden drop
  final count = (sr * duration).toInt();
  final out = List<double>.filled(count, 0.0);
  final rnd = Random(1234);

  for (int i = 0; i < count; i++) {
    final t = i / sr;
    final env = exp(-t * 90.0);
    // Warm woody fundamental + resonant harmonic
    final f1 = 540.0 * (1.0 - 0.2 * (t / duration));
    final tone1 = sin(2 * pi * f1 * t);
    final tone2 = sin(2 * pi * (f1 * 2.15) * t) * 0.3;
    // Crisp tactile micro-click transient in first 3ms
    final click = (t < 0.003) ? (rnd.nextDouble() * 2.0 - 1.0) * (1.0 - t / 0.003) * 0.35 : 0.0;

    out[i] = (tone1 * 0.7 + tone2 + click) * env * 0.7;
  }
  return out;
}

List<double> _generateWaterChime() {
  const sr = 44100;
  const duration = 0.085; // Crisp 85ms harmonic pop chime
  final count = (sr * duration).toInt();
  final out = List<double>.filled(count, 0.0);

  for (int i = 0; i < count; i++) {
    final t = i / sr;
    final env = exp(-t * 40.0) * (1.0 - exp(-t * 300.0));
    final f = 660.0;
    final tone1 = sin(2 * pi * f * t);
    final tone2 = sin(2 * pi * (f * 1.5) * t) * 0.35;
    out[i] = (tone1 + tone2) * env * 0.75;
  }
  return out;
}

List<double> _generateGoalComplete() {
  const sr = 44100;
  const duration = 0.38;
  final count = (sr * duration).toInt();
  final out = List<double>.filled(count, 0.0);

  // Major triad chord (C5, E5, G5, C6)
  final freqs = [523.25, 659.25, 783.99, 1046.50];
  final noteDur = duration / freqs.length;

  for (int i = 0; i < count; i++) {
    final t = i / sr;
    final noteIdx = (t / noteDur).floor().clamp(0, freqs.length - 1);
    final freq = freqs[noteIdx];
    final noteTime = t - noteIdx * noteDur;
    final env = exp(-noteTime * 10.0);
    out[i] = sin(2 * pi * freq * t) * env * 0.7;
  }
  return out;
}

List<double> _generateStarEarn() {
  const sr = 44100;
  const duration = 0.35;
  final count = (sr * duration).toInt();
  final out = List<double>.filled(count, 0.0);

  for (int i = 0; i < count; i++) {
    final t = i / sr;
    final env = exp(-t * 8.0);
    final tone1 = sin(2 * pi * 880.0 * t);
    final tone2 = sin(2 * pi * 1760.0 * t);
    out[i] = (tone1 * 0.6 + tone2 * 0.4) * env * 0.8;
  }
  return out;
}

List<double> _generateChestOpen() {
  const sr = 44100;
  const duration = 0.55;
  final count = (sr * duration).toInt();
  final out = List<double>.filled(count, 0.0);

  final freqs = [392.0, 523.25, 659.25, 783.99, 1046.50];
  final noteDur = duration / freqs.length;

  for (int i = 0; i < count; i++) {
    final t = i / sr;
    final noteIdx = (t / noteDur).floor().clamp(0, freqs.length - 1);
    final freq = freqs[noteIdx];
    final noteTime = t - noteIdx * noteDur;
    final env = exp(-noteTime * 8.0);
    out[i] = sin(2 * pi * freq * t) * env * 0.8;
  }
  return out;
}

List<double> _generateWheelTick() {
  const sr = 44100;
  const duration = 0.035;
  final count = (sr * duration).toInt();
  final out = List<double>.filled(count, 0.0);

  for (int i = 0; i < count; i++) {
    final t = i / sr;
    final env = exp(-t * 120);
    out[i] = sin(2 * pi * 1600 * t) * env * 0.65;
  }
  return out;
}

List<double> _generateJackpotFanfare() {
  const sr = 44100;
  const duration = 0.70;
  final count = (sr * duration).toInt();
  final out = List<double>.filled(count, 0.0);

  final freqs = [523.25, 659.25, 783.99, 1046.50, 1318.51];
  final noteDur = duration / freqs.length;

  for (int i = 0; i < count; i++) {
    final t = i / sr;
    final noteIdx = (t / noteDur).floor().clamp(0, freqs.length - 1);
    final freq = freqs[noteIdx];
    final noteTime = t - noteIdx * noteDur;
    final env = exp(-noteTime * 6.0);
    out[i] = sin(2 * pi * freq * t) * env * 0.85;
  }
  return out;
}

List<double> _generateShopCash() {
  const sr = 44100;
  const duration = 0.30;
  final count = (sr * duration).toInt();
  final out = List<double>.filled(count, 0.0);

  for (int i = 0; i < count; i++) {
    final t = i / sr;
    final env = exp(-t * 10.0);
    final tone1 = sin(2 * pi * 1800 * t);
    final tone2 = sin(2 * pi * 2400 * t);
    out[i] = (tone1 * 0.5 + tone2 * 0.5) * env * 0.75;
  }
  return out;
}

List<double> _generateAchievementChime() {
  const sr = 44100;
  const duration = 0.60;
  final count = (sr * duration).toInt();
  final out = List<double>.filled(count, 0.0);

  final freqs = [440.0, 554.37, 659.25, 880.0];
  final noteDur = duration / freqs.length;

  for (int i = 0; i < count; i++) {
    final t = i / sr;
    final noteIdx = (t / noteDur).floor().clamp(0, freqs.length - 1);
    final freq = freqs[noteIdx];
    final noteTime = t - noteIdx * noteDur;
    final env = exp(-noteTime * 7.0);
    out[i] = sin(2 * pi * freq * t) * env * 0.8;
  }
  return out;
}

List<double> _generateSwitchToggle() {
  const sr = 44100;
  const duration = 0.04;
  final count = (sr * duration).toInt();
  final out = List<double>.filled(count, 0.0);

  for (int i = 0; i < count; i++) {
    final t = i / sr;
    final env = exp(-t * 80);
    out[i] = sin(2 * pi * 900 * t) * env * 0.6;
  }
  return out;
}

List<double> _generateLevelWin() {
  const sr = 44100;
  const duration = 1.20;
  final count = (sr * duration).toInt();
  final out = List<double>.filled(count, 0.0);

  // Victory fanfare: G4 -> C5 -> E5 -> G5 -> C6
  final freqs = [392.0, 523.25, 659.25, 783.99, 1046.50];
  final noteDur = duration / freqs.length;

  for (int i = 0; i < count; i++) {
    final t = i / sr;
    final noteIdx = (t / noteDur).floor().clamp(0, freqs.length - 1);
    final freq = freqs[noteIdx];
    final noteTime = t - noteIdx * noteDur;
    final env = exp(-noteTime * 4.0);
    out[i] = sin(2 * pi * freq * t) * env * 0.85;
  }
  return out;
}

List<double> _generateLevelFail() {
  const sr = 44100;
  const duration = 0.80;
  final count = (sr * duration).toInt();
  final out = List<double>.filled(count, 0.0);

  // Descending sad triad: Eb4 -> D4 -> C4
  final freqs = [311.13, 293.66, 261.63];
  final noteDur = duration / freqs.length;

  for (int i = 0; i < count; i++) {
    final t = i / sr;
    final noteIdx = (t / noteDur).floor().clamp(0, freqs.length - 1);
    final freq = freqs[noteIdx];
    final noteTime = t - noteIdx * noteDur;
    final env = exp(-noteTime * 4.5);
    out[i] = sin(2 * pi * freq * t) * env * 0.75;
  }
  return out;
}

List<double> _generateHammerSmash() {
  const sr = 44100;
  const duration = 0.35;
  final count = (sr * duration).toInt();
  final out = List<double>.filled(count, 0.0);
  final rnd = Random(99);

  for (int i = 0; i < count; i++) {
    final t = i / sr;
    final env = exp(-t * 12.0);
    final woodFreq = 140.0 * exp(-t * 20);
    final woodTone = sin(2 * pi * woodFreq * t);
    final smashNoise = (rnd.nextDouble() * 2.0 - 1.0) * exp(-t * 30);
    out[i] = (woodTone * 0.7 + smashNoise * 0.5) * env * 0.95;
  }
  return out;
}

List<double> _generateBombExplode() {
  const sr = 44100;
  const duration = 0.60;
  final count = (sr * duration).toInt();
  final out = List<double>.filled(count, 0.0);
  final rnd = Random(555);

  for (int i = 0; i < count; i++) {
    final t = i / sr;
    final env = exp(-t * 5.0);
    final rumble = sin(2 * pi * (65.0 * exp(-t * 3)) * t);
    final noise = rnd.nextDouble() * 2.0 - 1.0;
    out[i] = (rumble * 0.8 + noise * 0.6) * env * 0.95;
  }
  return out;
}

List<double> _generateColorBombRainbow() {
  const sr = 44100;
  const duration = 0.55;
  final count = (sr * duration).toInt();
  final out = List<double>.filled(count, 0.0);

  for (int i = 0; i < count; i++) {
    final t = i / sr;
    final env = exp(-t * 5.5);
    final sweepFreq = 300.0 + 1500.0 * (t / duration) + sin(2 * pi * 40 * t) * 60;
    out[i] = sin(2 * pi * sweepFreq * t) * env * 0.8;
  }
  return out;
}

List<double> _generateShuffleWhoosh() {
  const sr = 44100;
  const duration = 0.40;
  final count = (sr * duration).toInt();
  final out = List<double>.filled(count, 0.0);
  final rnd = Random(77);

  for (int i = 0; i < count; i++) {
    final t = i / sr;
    final env = sin(pi * (t / duration));
    final noise = rnd.nextDouble() * 2.0 - 1.0;
    final flutter = sin(2 * pi * 35 * t);
    out[i] = noise * flutter * env * 0.75;
  }
  return out;
}

List<double> _generatePowerupJingle() {
  const sr = 44100;
  const duration = 0.45;
  final count = (sr * duration).toInt();
  final out = List<double>.filled(count, 0.0);

  final freqs = [440.0, 554.37, 659.25, 880.0];
  final noteDur = duration / freqs.length;

  for (int i = 0; i < count; i++) {
    final t = i / sr;
    final noteIdx = (t / noteDur).floor().clamp(0, freqs.length - 1);
    final freq = freqs[noteIdx];
    final noteTime = t - noteIdx * noteDur;
    final env = exp(-noteTime * 9.0);
    out[i] = sin(2 * pi * freq * t) * env * 0.8;
  }
  return out;
}

List<double> _generateLineLaserBlast() {
  const sr = 44100;
  const duration = 0.35;
  final count = (sr * duration).toInt();
  final out = List<double>.filled(count, 0.0);

  for (int i = 0; i < count; i++) {
    final t = i / sr;
    final env = exp(-t * 8.0);
    final freq = 1600.0 * exp(-t * 12) + 200.0;
    out[i] = sin(2 * pi * freq * t) * env * 0.85;
  }
  return out;
}

List<double> _generateRatchetTick() {
  const sr = 44100;
  const duration = 0.04;
  final count = (sr * duration).toInt();
  final out = List<double>.filled(count, 0.0);

  for (int i = 0; i < count; i++) {
    final t = i / sr;
    final env = exp(-t * 90);
    out[i] = sin(2 * pi * 1400 * t) * env * 0.6;
  }
  return out;
}

List<double> _generateHardLanding() {
  const sr = 44100;
  const duration = 0.12;
  final count = (sr * duration).toInt();
  final out = List<double>.filled(count, 0.0);

  for (int i = 0; i < count; i++) {
    final t = i / sr;
    final env = exp(-t * 30);
    final freq = 220.0 * exp(-t * 15);
    out[i] = sin(2 * pi * freq * t) * env * 0.85;
  }
  return out;
}

List<double> _generateDangerAlert() {
  const sr = 44100;
  const duration = 0.25;
  final count = (sr * duration).toInt();
  final out = List<double>.filled(count, 0.0);

  for (int i = 0; i < count; i++) {
    final t = i / sr;
    final env = exp(-t * 10);
    final freq = 880.0 + sin(2 * pi * 20 * t) * 50;
    out[i] = sin(2 * pi * freq * t) * env * 0.6;
  }
  return out;
}

List<double> _generateHarmonicGlassClear() {
  const sr = 44100;
  const duration = 0.45;
  final count = (sr * duration).toInt();
  final out = List<double>.filled(count, 0.0);

  final freqs = [659.25, 783.99, 987.77, 1318.51];
  final noteDur = duration / freqs.length;

  for (int i = 0; i < count; i++) {
    final t = i / sr;
    final noteIdx = (t / noteDur).floor().clamp(0, freqs.length - 1);
    final freq = freqs[noteIdx];
    final noteTime = t - noteIdx * noteDur;
    final env = exp(-noteTime * 7.0);
    out[i] = sin(2 * pi * freq * t) * env * 0.8;
  }
  return out;
}

List<double> _generateCorkPop() {
  const sr = 44100;
  const duration = 0.08;
  final count = (sr * duration).toInt();
  final out = List<double>.filled(count, 0.0);

  for (int i = 0; i < count; i++) {
    final t = i / sr;
    final env = exp(-t * 45);
    final freq = 250.0 + 400.0 * (t / duration);
    out[i] = sin(2 * pi * freq * t) * env * 0.8;
  }
  return out;
}

List<double> _generateLiquidTrickle() {
  const sr = 44100;
  const duration = 0.35;
  final count = (sr * duration).toInt();
  final out = List<double>.filled(count, 0.0);
  final rnd = Random(33);

  for (int i = 0; i < count; i++) {
    final t = i / sr;
    final env = sin(pi * (t / duration));
    final bubbleFreq = 500.0 + rnd.nextDouble() * 600.0;
    out[i] = sin(2 * pi * bubbleFreq * t) * env * 0.6;
  }
  return out;
}

List<double> _generateBgmMelody({required int type}) {
  const sr = 44100;
  const duration = 1.0; // 1 second silent loop
  final count = (sr * duration).toInt();
  return List<double>.filled(count, 0.0); // Completely silent
}
