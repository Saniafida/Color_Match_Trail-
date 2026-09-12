import 'dart:io';
import 'package:image/image.dart' as img;

void main() {
  final resDir = Directory('C:/Users/Sania Fida/.gemini/antigravity-ide/brain/20016690-da3f-4309-89c5-1b81b55b9155/scratch/installed_extracted/res');
  for (final dir in resDir.listSync()) {
    if (dir is Directory && (dir.path.contains('mipmap') || dir.path.contains('drawable'))) {
      for (final f in dir.listSync()) {
        if (f is File && f.path.endsWith('.png')) {
          final bytes = f.readAsBytesSync();
          final image = img.decodeImage(bytes);
          if (image != null) {
            print('${f.path}: ${image.width}x${image.height}, Corner(0,0)=(${image.getPixel(0,0).r}, ${image.getPixel(0,0).g}, ${image.getPixel(0,0).b}, ${image.getPixel(0,0).a})');
          }
        }
      }
    }
  }
}
