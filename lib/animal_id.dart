/*import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'classifier.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final picker = ImagePicker();
  File? _image;
  String _result = "";
  final Classifier _classifier = Classifier();

  @override
  void initState() {
    super.initState();
    _classifier.loadModel();
  }

  Future<void> getImage(ImageSource source) async {
    final pickedFile = await picker.pickImage(source: source);
    if (pickedFile != null) {
      File imageFile = File(pickedFile.path);
      setState(() {
        _image = imageFile;
      });
      setState(() {
        _result = "Processing...";
      });

      String result = await _classifier.classifyImage(imageFile);

      setState(() {
        _result = result;
      });

    }
  }

  @override
  void dispose() {
    _classifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Animal Classifier')),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _image == null ? const Text('No image selected') : Image.file(_image!),
          const SizedBox(height: 20),
          _result.isNotEmpty
              ? Text(_result, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black))
              : const Text('Processing...', style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic)),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () => getImage(ImageSource.camera),
                child: const Text('Capture Image'),
              ),
              const SizedBox(width: 20),
              ElevatedButton(
                onPressed: () => getImage(ImageSource.gallery),
                child: const Text('Upload Image'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
*/

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'classifier.dart';

class AnimalId extends StatefulWidget {
  const AnimalId({super.key});

  @override
  _AnimalIdState createState() => _AnimalIdState();
}

class _AnimalIdState extends State<AnimalId> {
  final picker = ImagePicker();
  File? _image;
  String _result = "";
  final Classifier _classifier = Classifier();

  @override
  void initState() {
    super.initState();
    _classifier.loadModel();
  }

  Future<void> getImage(ImageSource source) async {
    final pickedFile = await picker.pickImage(source: source);
    if (pickedFile != null) {
      File imageFile = File(pickedFile.path);
      setState(() {
        _image = imageFile;
      });
      setState(() {
        _result = "Processing...";
      });

      String result = await _classifier.classifyImage(imageFile);

      setState(() {
        _result = result;
      });

    }
  }

  @override
  void dispose() {
    _classifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Animal Classifier')),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _image == null ? const Text('No image selected') : Image.file(_image!),
          const SizedBox(height: 20),
          _result.isNotEmpty
              ? Text(_result, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black))
              : const Text('Processing...', style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic)),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () => getImage(ImageSource.camera),
                child: const Text('Capture Image'),
              ),
              const SizedBox(width: 20),
              ElevatedButton(
                onPressed: () => getImage(ImageSource.gallery),
                child: const Text('Upload Image'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}