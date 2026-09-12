import 'dart:io';
import 'package:image/image.dart' as img;

void main() {
  final userMasterPath = 'C:/Users/Sania Fida/.gemini/antigravity-ide/brain/20016690-da3f-4309-89c5-1b81b55b9155/.user_uploaded/media_1789159053490.png';
  final darazIconPath = 'C:/Users/Sania Fida/.gemini/antigravity-ide/brain/20016690-da3f-4309-89c5-1b81b55b9155/scratch/daraz_icon.png';
  final darazRoundPath = 'C:/Users/Sania Fida/.gemini/antigravity-ide/brain/20016690-da3f-4309-89c5-1b81b55b9155/scratch/daraz_round.png';

  final masterFile = File(userMasterPath);
  if (!masterFile.existsSync()) {
    print('Master file not found!');
    return;
  }

  // Update assets/images/game_luncher_iccon.png
  masterFile.copySync('assets/images/game_luncher_iccon.png');
  print('Copied master to assets/images/game_luncher_iccon.png');

  final masterImage = img.decodeImage(masterFile.readAsBytesSync())!;
  final darazIcon = img.decodeImage(File(darazIconPath).readAsBytesSync())!;
  final darazRound = img.decodeImage(File(darazRoundPath).readAsBytesSync())!;

  final densities = {
    'mdpi': 48,
    'hdpi': 72,
    'xhdpi': 96,
    'xxhdpi': 144,
    'xxxhdpi': 192,
  };

  for (final entry in densities.entries) {
    final density = entry.key;
    final size = entry.value;

    final targetDir = Directory('android/app/src/main/res/mipmap-$density');
    if (!targetDir.existsSync()) {
      targetDir.createSync(recursive: true);
    }

    // 1. Generate Squircle ic_launcher.png using Daraz squircle mask
    final scaledMaster = img.copyResize(masterImage, width: size, height: size, interpolation: img.Interpolation.cubic);
    final scaledDarazIcon = img.copyResize(darazIcon, width: size, height: size, interpolation: img.Interpolation.cubic);

    final squircleIcon = img.Image(width: size, height: size, numChannels: 4);
    for (int y = 0; y < size; y++) {
      for (int x = 0; x < size; x++) {
        final p = scaledMaster.getPixel(x, y);
        final maskPixel = scaledDarazIcon.getPixel(x, y);
        final alpha = maskPixel.a;
        squircleIcon.setPixelRgba(x, y, p.r, p.g, p.b, alpha);
      }
    }

    final squircleOut = File('${targetDir.path}/ic_launcher.png');
    squircleOut.writeAsBytesSync(img.encodePng(squircleIcon));
    print('Generated ${squircleOut.path} (${size}x$size)');

    // 2. Generate Round ic_launcher_round.png using Daraz round mask
    final scaledDarazRound = img.copyResize(darazRound, width: size, height: size, interpolation: img.Interpolation.cubic);
    final roundIcon = img.Image(width: size, height: size, numChannels: 4);
    for (int y = 0; y < size; y++) {
      for (int x = 0; x < size; x++) {
        final p = scaledMaster.getPixel(x, y);
        final maskPixel = scaledDarazRound.getPixel(x, y);
        final alpha = maskPixel.a;
        roundIcon.setPixelRgba(x, y, p.r, p.g, p.b, alpha);
      }
    }

    final roundOut = File('${targetDir.path}/ic_launcher_round.png');
    roundOut.writeAsBytesSync(img.encodePng(roundIcon));
    print('Generated ${roundOut.path} (${size}x$size)');
  }

  // Delete mipmap-anydpi-v26 if it exists
  final anydpiDir = Directory('android/app/src/main/res/mipmap-anydpi-v26');
  if (anydpiDir.existsSync()) {
    anydpiDir.deleteSync(recursive: true);
    print('Deleted android/app/src/main/res/mipmap-anydpi-v26');
  }

  // Delete drawable-* ic_launcher_* files
  final resDir = Directory('android/app/src/main/res');
  for (final entity in resDir.listSync()) {
    if (entity is Directory && entity.path.contains('drawable-')) {
      for (final f in entity.listSync()) {
        if (f is File && f.path.contains('ic_launcher')) {
          f.deleteSync();
          print('Deleted ${f.path}');
        }
      }
    }
  }

  print('All Daraz-style icons generated successfully!');
}
