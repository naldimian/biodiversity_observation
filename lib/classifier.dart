/* latest
import 'package:tflite_flutter/tflite_flutter.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'package:heif_converter/heif_converter.dart';

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

  // Preprocess image and convert HEIF to JPG if necessary
  Future<Float32List> preprocessImage(File image) async {
    img.Image? imageDecoded;

    // Check if the image is HEIF format (checking file extension)
    if (image.path.endsWith('.heif') || image.path.endsWith('.heic')) {
      // Convert HEIF to JPG by saving the bytes to a temporary file
      final tempFile = await _convertHeifToJpg(image);
      imageDecoded = img.decodeImage(tempFile.readAsBytesSync())!;
    } else {
      // Decode non-HEIF images normally
      imageDecoded = img.decodeImage(image.readAsBytesSync())!;
    }

    // Resize the image to match the model's input size
    img.Image resized = img.copyResize(imageDecoded, width: 224, height: 224);

    List<double> normalizedPixels = [];
    for (int y = 0; y < resized.height; y++) {
      for (int x = 0; x < resized.width; x++) {
        img.Pixel pixel = resized.getPixel(x, y);
        normalizedPixels.add(pixel.r / 255.0);
        normalizedPixels.add(pixel.g / 255.0);
        normalizedPixels.add(pixel.b / 255.0);
      }
    }

    // Return the preprocessed image data
    return Float32List.fromList(normalizedPixels);
  }

  // Convert HEIF to JPG and return a temporary file
  Future<File> _convertHeifToJpg(File image) async {
    // Generate a temporary file to store the converted JPG
    final tempFile = File('${Directory.systemTemp.path}/temp.jpg');

    try {
      // Convert the HEIF file to JPG using HeifConverter
      String heicPath = image.path;
      String jpgPath = tempFile.path;

      // Perform the conversion and specify the format (e.g., JPG)
      await HeifConverter.convert(heicPath, output: jpgPath);  // Convert HEIF to JPG

      // Return the file with the converted JPG
      return tempFile;
    } catch (e) {
      print("❌ Error converting HEIF to JPG: $e");
      rethrow;  // Throw error if conversion fails
    }
  }

  // Classify the image after it is preprocessed
  Future<String> classifyImage(File image) async {
    if (_interpreter == null) {
      return "❌ Model is not loaded!";
    }

    // Preprocess the image (convert and resize if needed)
    Float32List input = await preprocessImage(image);
    var reshapedInput = input.reshape([1, 224, 224, 3]);

    // Prepare the output array for classification
    var output = List.filled(1 * _labels.length, 0.0).reshape([1, _labels.length]);
    try {
      _interpreter.run(reshapedInput, output);
    } catch (e) {
      return "❌ Error running the model: $e";
    }

    // Find the class with the highest probability
    double maxProbability = (output[0] as List<double>).reduce((a, b) => a > b ? a : b);

    int maxIndex = output[0].indexWhere((element) => element == maxProbability);

    //without percentage
    return "${_labels[maxIndex]}";

    // with percentage
    //return "${_labels[maxIndex]} (${(maxProbability * 100).toStringAsFixed(2)}%)";
  }

  void dispose() {
    _interpreter.close();
  }
}
*/

/* 1.4.24
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'package:heif_converter/heif_converter.dart';

class Classifier {
  late Interpreter _interpreter;
  List<String> _labels = [];

  Future<void> loadModel() async {
    try {
      // Load model
      _interpreter = await Interpreter.fromAsset('assets/primate_classifier.tflite');
      print("✅ Model loaded successfully!");

      // Load labels from label.txt
      _labels = await _loadLabels('assets/labels.txt');
      print("✅ Labels loaded: $_labels");
    } catch (e) {
      print("❌ Error loading model or labels: $e");
    }
  }

  Future<List<String>> _loadLabels(String path) async {
    final rawLabels = await rootBundle.loadString(path);
    return rawLabels.split('\n').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
  }

  Future<Float32List> preprocessImage(File image) async {
    img.Image? imageDecoded;

    if (image.path.endsWith('.heif') || image.path.endsWith('.heic')) {
      final tempFile = await _convertHeifToJpg(image);
      imageDecoded = img.decodeImage(tempFile.readAsBytesSync())!;
    } else {
      imageDecoded = img.decodeImage(image.readAsBytesSync())!;
    }

    img.Image resized = img.copyResize(imageDecoded, width: 224, height: 224);

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

  Future<File> _convertHeifToJpg(File image) async {
    final tempFile = File('${Directory.systemTemp.path}/temp.jpg');
    try {
      await HeifConverter.convert(image.path, output: tempFile.path);
      return tempFile;
    } catch (e) {
      print("❌ Error converting HEIF to JPG: $e");
      rethrow;
    }
  }

  Future<String> classifyImage(File image) async {
    if (_interpreter == null) {
      return "❌ Model is not loaded!";
    }

    Float32List input = await preprocessImage(image);
    var reshapedInput = input.reshape([1, 224, 224, 3]);

    var output = List.filled(1 * _labels.length, 0.0).reshape([1, _labels.length]);
    try {
      _interpreter.run(reshapedInput, output);
    } catch (e) {
      return "❌ Error running the model: $e";
    }

    double maxProbability = (output[0] as List<double>).reduce((a, b) => a > b ? a : b);
    int maxIndex = output[0].indexWhere((element) => element == maxProbability);
    //return "${_labels[maxIndex]} (${(maxProbability * 100).toStringAsFixed(2)}%)";
    return "${_labels[maxIndex]}";
  }

  void dispose() {
    _interpreter.close();
  }
}
*/

import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'package:heif_converter/heif_converter.dart';

class Classifier {
  late Interpreter _interpreter;
  List<String> _labels = [];
  bool _isModelLoaded = false;

  /// Loads the TFLite model and the labels from assets
  Future<void> loadModel() async {
    try {
      _interpreter = await Interpreter.fromAsset('assets/primate_classifier_float32.tflite');
      _isModelLoaded = true;
      print("✅ Model loaded successfully!");

      _labels = await _loadLabels('assets/labels.txt');
      print("✅ Labels loaded: $_labels");
    } catch (e) {
      print("❌ Error loading model or labels: $e");
    }
  }

  /// Parses the labels text file
  Future<List<String>> _loadLabels(String path) async {
    final rawLabels = await rootBundle.loadString(path);
    return rawLabels.split('\n').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
  }

  /// Converts HEIF/HEIC files to standard JPG format for the image package
  Future<File> _convertHeifToJpg(File image) async {
    final tempFile = File('${Directory.systemTemp.path}/temp.jpg');
    try {
      await HeifConverter.convert(image.path, output: tempFile.path);
      return tempFile;
    } catch (e) {
      print("❌ Error converting HEIF to JPG: $e");
      rethrow;
    }
  }

  /// Prepares the image for the MobileNetV3 model
  Future<Float32List> preprocessImage(File image) async {
    img.Image? imageDecoded;

    // 1. Decode the image
    if (image.path.endsWith('.heif') || image.path.endsWith('.heic')) {
      final tempFile = await _convertHeifToJpg(image);
      imageDecoded = img.decodeImage(tempFile.readAsBytesSync())!;
    } else {
      imageDecoded = img.decodeImage(image.readAsBytesSync())!;
    }

    // 2. Direct Resize (Squish) to 320x320 using Linear Interpolation
    // This perfectly matches the default Keras training pipeline
    img.Image resized = img.copyResize(
        imageDecoded,
        width: 320,
        height: 320,
        interpolation: img.Interpolation.linear
    );

    // 3. Extract raw pixels (0-255) because MobileNetV3 handles its own scaling
    List<double> rawPixels = [];
    for (int y = 0; y < resized.height; y++) {
      for (int x = 0; x < resized.width; x++) {
        img.Pixel pixel = resized.getPixel(x, y);
        rawPixels.add(pixel.r.toDouble());
        rawPixels.add(pixel.g.toDouble());
        rawPixels.add(pixel.b.toDouble());
      }
    }

    return Float32List.fromList(rawPixels);
  }

  /// Runs inference on the provided image and returns the predicted label and confidence
  Future<String> classifyImage(File image) async {
    if (!_isModelLoaded) {
      return "❌ Model is not loaded!";
    }

    try {
      // 1. Preprocess the image
      Float32List input = await preprocessImage(image);

      // 2. Reshape to match model input shape: [BatchSize, Height, Width, Channels]
      var reshapedInput = input.reshape([1, 320, 320, 3]);

      // 3. Prepare the output tensor
      var output = List.filled(1 * _labels.length, 0.0).reshape([1, _labels.length]);

      // 4. Run the model
      _interpreter.run(reshapedInput, output);

      // 5. Parse the output probabilities
      List<double> probabilities = (output[0] as List<dynamic>).cast<double>();

      double maxProbability = probabilities.reduce((a, b) => a > b ? a : b);
      int maxIndex = probabilities.indexWhere((element) => element == maxProbability);

      // Return formatted string with confidence percentage
      return "${_labels[maxIndex]} (${(maxProbability * 100).toStringAsFixed(1)}%)";

    } catch (e) {
      return "❌ Error running the model: $e";
    }
  }

  /// Clean up resources when done
  void dispose() {
    if (_isModelLoaded) {
      _interpreter.close();
    }
  }
}