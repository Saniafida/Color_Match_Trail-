// ignore_for_file: avoid_print
import 'dart:io';

void main() {
  final files = Directory('assets/sounds')
      .listSync(recursive: true)
      .whereType<File>()
      .toList();
  print('Total sound files: ${files.length}');
  for (final f in files) {
    print('${f.path}: ${f.lengthSync()} bytes');
  }
}
