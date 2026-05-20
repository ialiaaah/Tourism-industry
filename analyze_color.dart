import 'dart:io';
import 'package:image/image.dart' as img;

void main() {
  analyze('assets/monuments/sphinx.jpg');
  for (var i = 0; i < 8; i++) {
    analyze('assets/monuments/sphinx_ref$i.jpg');
  }
  // Also check the user provided image
  analyze('/Users/ialiaaah/.gemini/antigravity/brain/0a44a0d9-75eb-4cf8-bb83-64153234c6b7/media__1779047596854.jpg');
}

void analyze(String path) {
  try {
    final bytes = File(path).readAsBytesSync();
    final image = img.decodeImage(bytes);
    if (image == null) return;
    
    final resized = img.copyResize(image, width: 1, height: 1);
    final pixel = resized.getPixel(0, 0);
    print('$path average color: R=${pixel.r.toInt()}, G=${pixel.g.toInt()}, B=${pixel.b.toInt()}');
  } catch (e) {
    print('Error analyzing $path: $e');
  }
}

