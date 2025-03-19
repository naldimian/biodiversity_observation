import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:image/image.dart' as img;

void main() {
  runApp(AnimalClassifierApp());
}

class AnimalClassifierApp extends StatefulWidget {
  @override
  _AnimalClassifierAppState createState() => _AnimalClassifierAppState();
}

class _AnimalClassifierAppState extends State<AnimalClassifierApp> {
  late Interpreter _interpreter;
  File? _image;
  final picker = ImagePicker();
  List<String> _labels = ['Cat','Dog']; // Example labels
  String _result = "";

  @override
  void initState() {
    super.initState();
    loadModel();
  }

  Future<void> loadModel() async {
    try {
      _interpreter = await Interpreter.fromAsset('assets/model.tflite');
      print("✅ Model loaded successfully!");

      // Debugging: Check expected input type
      print("🔍 Expected input type: ${_interpreter.getInputTensor(0).type}");
      print("🔍 Expected input shape: ${_interpreter.getInputTensor(0).shape}");
    } catch (e) {
      print("❌ Error loading model: $e");
    }

  }


  Float32List preprocessImage(File image) {
    img.Image? imageDecoded = img.decodeImage(image.readAsBytesSync());
    img.Image resized = img.copyResize(imageDecoded!, width: 224, height: 224);

    // Convert image to RGB (drop alpha channel)
    List<double> normalizedPixels = [];
    for (int y = 0; y < resized.height; y++) {
      for (int x = 0; x < resized.width; x++) {
        img.Pixel pixel = resized.getPixel(x, y);

        // Extract RGB values
        int r = pixel.r.toInt();
        int g = pixel.g.toInt();
        int b = pixel.b.toInt();

        // Normalize values to [0,1]
        normalizedPixels.add(r / 255.0);
        normalizedPixels.add(g / 255.0);
        normalizedPixels.add(b / 255.0);
      }
    }

    print("✅ Processed image pixel count: ${normalizedPixels.length}"); // Debugging
    return Float32List.fromList(normalizedPixels);
  }

  Future<void> classifyImage(File image) async {
    if (_interpreter == null) {
      print("❌ Model is not loaded yet!");
      return;
    }

    print("🔹 Classifying image...");
    Float32List input = preprocessImage(image);
    print("✅ Processed image pixel count: ${input.length}");

    // Ensure input matches model's expected shape
    var reshapedInput = input.reshape([1, 224, 224, 3]);
    print("✅ Final input tensor shape: ${reshapedInput.shape}");

    // Output tensor
    var output = List.filled(1 * _labels.length, 0.0).reshape([1, _labels.length]);

    try {
      _interpreter.run(reshapedInput, output);
      print("🔹 Model inference completed!");
    } catch (e) {
      print("❌ Error running the model: $e");
      return;
    }

    // **Extracting maximum probability and index**
    double maxProbability = output[0].reduce((double a, double b) => a > b ? a : b);
    int maxIndex = output[0].indexWhere((element) => element == maxProbability);

    setState(() {
      _result = "${_labels[maxIndex]} (${(maxProbability * 100).toStringAsFixed(2)}%)";
      print("✅ Classification result: $_result");
    });
  }





  Future<void> getImage(ImageSource source) async {
    final pickedFile = await picker.pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
      await classifyImage(_image!);
    }
  }

  @override
  void dispose() {
    _interpreter.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: Text('Animal Classifier')),
        body: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _image == null
                ? Text('No image selected')
                : Image.file(_image!),
            SizedBox(height: 20),
            _result.isNotEmpty
                ? Text(_result, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black))
                : Text('Processing...', style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic)),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () => getImage(ImageSource.camera),
                  child: Text('Capture Image'),
                ),
                SizedBox(width: 20),
                ElevatedButton(
                  onPressed: () => getImage(ImageSource.gallery),
                  child: Text('Upload Image'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/* Label only
  Future<void> classifyImage(File image) async {
    if (_interpreter == null) {
      print("❌ Model is not loaded yet!");
      return;
    }

    print("🔹 Classifying image...");
    Float32List input = preprocessImage(image);
    print("✅ Processed image pixel count: ${input.length}");

    // Ensure input matches model's expected shape
    var reshapedInput = input.reshape([1, 224, 224, 3]);
    print("✅ Final input tensor shape: ${reshapedInput.shape}");

    // Output tensor
    var output = List.filled(1 * _labels.length, 0.0).reshape([1, _labels.length]);

    try {
      _interpreter.run(reshapedInput, output);
      print("🔹 Model inference completed!");
    } catch (e) {
      print("❌ Error running the model: $e");
      return;
    }

    // **Fix: Ensure reduce() operates on double values**
    int maxIndex = output[0].indexWhere(
          (element) => element == output[0].reduce((double a, double b) => a > b ? a : b),
    );

    setState(() {
      _result = _labels[maxIndex];
      print("✅ Classification result: $_result");
    });
  }
*/
