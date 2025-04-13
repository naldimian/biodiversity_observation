import 'package:tflite_flutter/tflite_flutter.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:image/image.dart' as img;

class Classifier {
  late Interpreter _interpreter;
  final List<String> _labels = ['Cat', 'Dog'];

  Future<void> loadModel() async {
    try {
      _interpreter = await Interpreter.fromAsset('assets/model_unquant.tflite');
      print("✅ Model loaded successfully!");
    } catch (e) {
      print("❌ Error loading model: $e");
    }
  }

  Float32List preprocessImage(File image) {
    img.Image? imageDecoded = img.decodeImage(image.readAsBytesSync());
    img.Image resized = img.copyResize(imageDecoded!, width: 224, height: 224);

    List<double> normalizedPixels = [];
    for (int y = 0; y < resized.height; y++) {
      for (int x = 0; x < resized.width; x++) {
        img.Pixel pixel = resized.getPixel(x, y);
        normalizedPixels.add(pixel.r / 255.0);
        normalizedPixels.add(pixel.g / 255.0);
        normalizedPixels.add(pixel.b / 255.0);
      }
    }
    return Float32List.fromList(normalizedPixels);
  }

  Future<String> classifyImage(File image) async {
    if (_interpreter == null) {
      return "❌ Model is not loaded!";
    }

    Float32List input = preprocessImage(image);
    var reshapedInput = input.reshape([1, 224, 224, 3]);

    var output = List.filled(1 * _labels.length, 0.0).reshape([1, _labels.length]);
    try {
      _interpreter.run(reshapedInput, output);
    } catch (e) {
      return "❌ Error running the model: $e";
    }

    double maxProbability = (output[0] as List<double>).reduce((a, b) => a > b ? a : b);

    int maxIndex = output[0].indexWhere((element) => element == maxProbability);

    return "${_labels[maxIndex]} (${(maxProbability * 100).toStringAsFixed(2)}%)";
  }

  void dispose() {
    _interpreter.close();
  }
}
