import 'package:image_picker/image_picker.dart';

class AIHelper {
  Future<void> init() async {}
  
  Future<String?> analyzeImage(XFile? image, String stopName) async {
    // Mock processing delay for Web
    await Future.delayed(const Duration(seconds: 2));
    return stopName; 
  }
  
  void dispose() {}
}
