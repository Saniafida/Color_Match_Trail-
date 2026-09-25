import 'dart:io';
import 'package:image/image.dart' as img;

void main() async {
  final dir = Directory('assets/images');
  if (!dir.existsSync()) return;

  final files = dir.listSync(recursive: true).whereType<File>().toList();
  print('Found ${files.length} images to check...');

  int savedBytes = 0;

  for (final file in files) {
    final path = file.path.toLowerCase();
    if (!path.endsWith('.png') && !path.endsWith('.jpg') && !path.endsWith('.jpeg')) continue;

    final bytes = await file.readAsBytes();
    final originalSize = bytes.length;
    if (originalSize < 50 * 1024) continue; // Skip files smaller than 50KB

    final image = img.decodeImage(bytes);
    if (image == null) continue;

    img.Image resized = image;

    if (path.contains('icons') || path.contains('boosters') || path.contains('power_ups')) {
      if (image.width > 256 || image.height > 256) {
        resized = img.copyResize(image, width: 256, height: 256, interpolation: img.Interpolation.average);
      }
    } else if (path.contains('home_screen') || path.contains('lose_screen')) {
      if (image.width > 512 || image.height > 512) {
        final maxDim = image.width > image.height ? image.width : image.height;
        final scale = 512 / maxDim;
        resized = img.copyResize(image, width: (image.width * scale).round(), height: (image.height * scale).round(), interpolation: img.Interpolation.average);
      }
    } else if (path.contains('backgrounds')) {
      if (image.width > 1280 || image.height > 1280) {
        final scale = 1280 / (image.width > image.height ? image.width : image.height);
        resized = img.copyResize(image, width: (image.width * scale).round(), height: (image.height * scale).round(), interpolation: img.Interpolation.average);
      }
    } else {
      if (image.width > 512 || image.height > 512) {
        final scale = 512 / (image.width > image.height ? image.width : image.height);
        resized = img.copyResize(image, width: (image.width * scale).round(), height: (image.height * scale).round(), interpolation: img.Interpolation.average);
      }
    }

    List<int> newBytes;
    if (path.endsWith('.jpg') || path.endsWith('.jpeg')) {
      newBytes = img.encodeJpg(resized, quality: 80);
    } else {
      newBytes = img.encodePng(resized, level: 9);
    }

    if (newBytes.length < originalSize) {
      await file.writeAsBytes(newBytes);
      final diff = originalSize - newBytes.length;
      savedBytes += diff;
      print('Compressed ${file.path}: ${(originalSize / 1024).toStringAsFixed(1)} KB -> ${(newBytes.length / 1024).toStringAsFixed(1)} KB (Saved ${(diff / 1024).toStringAsFixed(1)} KB)');
    }
  }

  print('\nTOTAL SAVED: ${(savedBytes / (1024 * 1024)).toStringAsFixed(2)} MB');
}
