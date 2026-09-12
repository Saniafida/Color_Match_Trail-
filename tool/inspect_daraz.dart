import 'dart:io';
import 'package:image/image.dart' as img;

void main() {
  var file = File('C:/Users/Sania Fida/.gemini/antigravity-ide/brain/20016690-da3f-4309-89c5-1b81b55b9155/scratch/daraz_extracted/res/mipmap-xxxhdpi-v4/ic_launcher.webp');
  var image = img.decodeImage(file.readAsBytesSync())!;
  File('C:/Users/Sania Fida/.gemini/antigravity-ide/brain/20016690-da3f-4309-89c5-1b81b55b9155/scratch/daraz_icon.png')
    .writeAsBytesSync(img.encodePng(image));

  var roundFile = File('C:/Users/Sania Fida/.gemini/antigravity-ide/brain/20016690-da3f-4309-89c5-1b81b55b9155/scratch/daraz_extracted/res/mipmap-xxxhdpi-v4/ic_launcher_round.webp');
  var roundImage = img.decodeImage(roundFile.readAsBytesSync())!;
  File('C:/Users/Sania Fida/.gemini/antigravity-ide/brain/20016690-da3f-4309-89c5-1b81b55b9155/scratch/daraz_round.png')
    .writeAsBytesSync(img.encodePng(roundImage));
  print('Saved daraz_icon.png and daraz_round.png');
}
