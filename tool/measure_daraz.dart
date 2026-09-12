import 'dart:io';
import 'package:image/image.dart' as img;

void main() {
  final file = File('C:/Users/Sania Fida/.gemini/antigravity-ide/brain/20016690-da3f-4309-89c5-1b81b55b9155/scratch/daraz_icon.png');
  final image = img.decodeImage(file.readAsBytesSync())!;
  print('Daraz icon size: ${image.width}x${image.height}');

  // Let us find the first non-transparent pixel on row 0, 1, 2, ...
  for (int y = 0; y < 50; y += 2) {
    int firstX = -1;
    for (int x = 0; x < image.width; x++) {
      if (image.getPixel(x, y).a > 128) {
        firstX = x;
        break;
      }
    }
    print('y=$y -> first non-transparent x=$firstX');
  }
}
