import 'dart:io';
import 'package:image/image.dart' as img;

void main() {
  final file = File('C:/Users/Sania Fida/.gemini/antigravity-ide/brain/20016690-da3f-4309-89c5-1b81b55b9155/.user_uploaded/media_1789192337143.png');
  final image = img.decodeImage(file.readAsBytesSync())!;

  // Let's crop just the Color Match icon: roughly x from 60 to 105, y from 0 to 45
  final cropped = img.copyCrop(image, x: 58, y: 0, width: 48, height: 48);
  File('C:/Users/Sania Fida/.gemini/antigravity-ide/brain/20016690-da3f-4309-89c5-1b81b55b9155/scratch/color_match_cropped.png')
    .writeAsBytesSync(img.encodePng(cropped));

  final darazCrop = img.copyCrop(image, x: 8, y: 0, width: 48, height: 48);
  File('C:/Users/Sania Fida/.gemini/antigravity-ide/brain/20016690-da3f-4309-89c5-1b81b55b9155/scratch/daraz_cropped.png')
    .writeAsBytesSync(img.encodePng(darazCrop));

  print('Saved crops');
}
