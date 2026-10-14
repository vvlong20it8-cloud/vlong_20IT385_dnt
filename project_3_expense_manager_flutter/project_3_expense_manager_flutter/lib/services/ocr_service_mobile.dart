import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class OcrService {
  final TextRecognizer _recognizer = TextRecognizer();

  Future<String> recognizeImagePath(String path) async {
    final inputImage = InputImage.fromFilePath(path);
    final result = await _recognizer.processImage(inputImage);
    return result.text;
  }

  Future<void> dispose() async => _recognizer.close();
}
