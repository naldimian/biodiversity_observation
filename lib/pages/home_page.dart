/*import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cubaankedua/services/firestore.dart';
import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
//test
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // Firestores
  final FirestoreService firestoreService = FirestoreService();

  // Text Controller
  final TextEditingController textController = TextEditingController();

  // Open a dialog box to add or update a note
  void openNoteBox({String? docID, String? existingText}) {
    if (existingText != null) {
      textController.text = existingText; // Pre-fill text field for editing
    } else {
      textController.clear();
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(docID == null ? "Add Observation" : "Edit Observation"),
        content: TextField(
          controller: textController,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: "Enter your observation",
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel")
          ),
          ElevatedButton(
            onPressed: () {
              if (docID == null) {
                firestoreService.addObservation(textController.text);
              } else {
                firestoreService.updateObservation(docID, textController.text);
              }
              textController.clear();
              Navigator.pop(context);
            },
            child: const Text("Save"),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Observations"),
        backgroundColor: Colors.blue,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => openNoteBox(),
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: firestoreService.getObservationsStream(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            List observationsList = snapshot.data!.docs;

            return ListView.builder(
              itemCount: observationsList.length,
              padding: const EdgeInsets.all(8),
              itemBuilder: (context, index) {
                // Get each individual document
                DocumentSnapshot document = observationsList[index];
                String docID = document.id;

                // Extract observation text with a null check
                Map<String, dynamic> data = document.data() as Map<String, dynamic>;
                String observationText = data['name'] ?? "No data available";

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: const BorderSide(color: Colors.grey, width: 0.5),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 8, horizontal: 16,
                    ),
                    title: Text(
                      observationText,
                      style: const TextStyle(fontSize: 16),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          onPressed: () => openNoteBox(docID: docID, existingText: observationText),
                          icon: const Icon(Icons.edit, color: Colors.blue),
                        ),
                        IconButton(
                          onPressed: () => firestoreService.deleteObservation(docID),
                          icon: const Icon(Icons.delete, color: Colors.red),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          } else {
            return const Center(child: Text("No observations available."));
          }
        },
      ),
    );
  }
}
*/

//before optimization
/*
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cubaankedua/services/firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:exif/exif.dart';
import 'package:url_launcher/url_launcher.dart';

import 'google_map_screen.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final FirestoreService firestoreService = FirestoreService();
  final TextEditingController textController = TextEditingController();
  final TextEditingController locationController = TextEditingController();

  File? _image;
  String? imageUrl;
  String? imageLocation;

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      File imageFile = File(pickedFile.path);
      _extractLocationFromImage(imageFile);
      setState(() {
        _image = imageFile;
      });
    }
  }

  Future<void> _captureImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      File imageFile = File(pickedFile.path);
      _extractLocationFromImage(imageFile);
      setState(() {
        _image = imageFile;
      });
    }
  }

  Future<void> _extractLocationFromImage(File imageFile) async {
    final bytes = await imageFile.readAsBytes();
    final data = await readExifFromBytes(bytes);

    if (data.containsKey('GPS GPSLatitude') && data.containsKey('GPS GPSLongitude')) {
      final latValues = data['GPS GPSLatitude']!.values.toList();
      final lonValues = data['GPS GPSLongitude']!.values.toList();

      final latitude = _convertExifGpsToDecimal(latValues, data['GPS GPSLatitudeRef']?.printable);
      final longitude = _convertExifGpsToDecimal(lonValues, data['GPS GPSLongitudeRef']?.printable);

      setState(() {
        imageLocation = "$latitude, $longitude";
      });
    } else {
      setState(() {
        imageLocation = null;
      });
    }
  }

  double _convertExifGpsToDecimal(List<dynamic> values, String? ref) {
    if (values.length != 3) return 0.0;
    double degrees = values[0].toDouble();
    double minutes = values[1].toDouble();
    double seconds = values[2].toDouble();
    double decimal = degrees + (minutes / 60) + (seconds / 3600);
    if (ref == 'S' || ref == 'W') decimal = -decimal;
    return decimal;
  }

  Future<String?> _uploadImage(File image) async {
    try {
      final ref = FirebaseStorage.instance
          .ref()
          .child('images')
          .child('observations/${DateTime.now().millisecondsSinceEpoch}.jpg');
      UploadTask uploadTask = ref.putFile(image);
      TaskSnapshot snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      return null;
    }
  }

  @override
  void dispose() {
    textController.dispose();
    locationController.dispose();
    super.dispose();
  }

  void _openGoogleMaps(String location) {
    List<String> latLng = location.split(',');
    double latitude = double.parse(latLng[0].trim());
    double longitude = double.parse(latLng[1].trim());

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GoogleMapScreen(latitude: latitude, longitude: longitude),
      ),
    );
  }

  void openNoteBox({String? docID, String? existingText, String? existingImageUrl, String? existingLocation}) {
    textController.text = existingText ?? "";
    _image = null;
    imageUrl = existingImageUrl;
    imageLocation = existingLocation;

    bool isSaveEnabled = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          void updateSaveButtonState() {
            setState(() {
              isSaveEnabled = textController.text.isNotEmpty && _image != null && imageLocation != null;
            });
          }

          Future<void> handleImageSelection(Future<void> Function() imagePickerFunction) async {
            await imagePickerFunction();
            if (_image != null) {
              await _extractLocationFromImage(_image!);
              setState(() {}); // Ensure UI updates with location
            }
            updateSaveButtonState();
          }

          return AlertDialog(
            title: Text(docID == null ? "Add Observation" : "Edit Observation"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: textController,
                  onChanged: (value) => updateSaveButtonState(),
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: "Enter your observation",
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.photo_library),
                      onPressed: () => handleImageSelection(_pickImage),
                    ),
                    IconButton(
                      icon: const Icon(Icons.camera_alt),
                      onPressed: () => handleImageSelection(_captureImage),
                    ),
                  ],
                ),
                if (_image != null) Image.file(_image!, height: 100),
                if (imageUrl != null) Image.network(imageUrl!, height: 100),
                const SizedBox(height: 10),
                if (imageLocation != null)
                  Text(
                    "Location: $imageLocation",
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  )
                else
                  const Text(
                    "Note: Please only select images with location data",
                    style: TextStyle(color: Colors.red, fontSize: 12),
                  ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: isSaveEnabled
                    ? () async {
                  String? finalImageUrl = await _uploadImage(_image!);
                  if (docID == null) {
                    firestoreService.addObservation(
                      textController.text,
                      imageLocation ?? "No location",
                      finalImageUrl ?? "",
                    );
                  } else {
                    firestoreService.updateObservation(
                      docID,
                      textController.text,
                      imageLocation ?? "No location",
                      finalImageUrl ?? "",
                    );
                  }
                  textController.clear();
                  imageUrl = null;
                  Navigator.pop(context);
                }
                    : null,
                child: const Text("Save"),
              )
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Observations"),
        backgroundColor: Colors.blue,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => openNoteBox(),
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: firestoreService.getObservationsStream(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            List observationsList = snapshot.data!.docs;
            return ListView.builder(
              itemCount: observationsList.length,
              itemBuilder: (context, index) {
                DocumentSnapshot document = observationsList[index];
                String docID = document.id;
                Map<String, dynamic> data = document.data() as Map<String, dynamic>;

                return Card(
                  child: ListTile(
                    leading: data['image'] != null
                        ? Image.network(data['image'], width: 50, height: 50, fit: BoxFit.cover)
                        : const Icon(Icons.image),
                    title: Text(data['name'] ?? "No Name"),
                    subtitle: Text(data['location'] ?? "No location available"),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (data['location'] != null && data['location']!.contains(','))
                          IconButton(
                            icon: const Icon(Icons.map, color: Colors.blue),
                            onPressed: () {
                              _openGoogleMaps(data['location']);
                            },
                          ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => firestoreService.deleteObservation(docID),
                        ),
                      ],
                    ),
                  ),
                );

              },
            );
          } else {
            return const Center(child: Text("No observations available."));
          }
        },
      ),
    );
  }
}
*/
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cubaankedua/services/firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:exif/exif.dart';
import 'google_map_screen.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final FirestoreService firestoreService = FirestoreService();
  final TextEditingController textController = TextEditingController();
  File? _image;
  String? imageUrl;
  String? imageLocation;
  bool isUploading = false;

  Future<void> _pickImage(ImageSource source, StateSetter setState) async {
    final pickedFile = await ImagePicker().pickImage(source: source);
    if (pickedFile == null) return;

    File imageFile = File(pickedFile.path);
    await _extractLocationFromImage(imageFile, setState); // Pass setState here

    setState(() => _image = imageFile);
  }



  Future<void> _extractLocationFromImage(File imageFile, StateSetter setState) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final data = await readExifFromBytes(bytes);

      if (data.containsKey('GPS GPSLatitude') && data.containsKey('GPS GPSLongitude')) {
        final latValues = data['GPS GPSLatitude']!.values.toList();
        final lonValues = data['GPS GPSLongitude']!.values.toList();
        final latitude = _convertExifGpsToDecimal(latValues, data['GPS GPSLatitudeRef']?.printable);
        final longitude = _convertExifGpsToDecimal(lonValues, data['GPS GPSLongitudeRef']?.printable);

        setState(() => imageLocation = "$latitude, $longitude");
      } else {
        setState(() => imageLocation = null);
      }
    } catch (e) {
      debugPrint("Error extracting location: $e");
      setState(() => imageLocation = null);
    }
  }


  double _convertExifGpsToDecimal(List<dynamic> values, String? ref) {
    if (values.length != 3) return 0.0;
    double decimal = values[0].toDouble() + (values[1].toDouble() / 60) + (values[2].toDouble() / 3600);
    return (ref == 'S' || ref == 'W') ? -decimal : decimal;
  }

  Future<String?> _uploadImage(File image) async {
    try {
      setState(() => isUploading = true);
      final ref = FirebaseStorage.instance.ref().child('images/observations/${DateTime.now().millisecondsSinceEpoch}.jpg');
      UploadTask uploadTask = ref.putFile(image);
      TaskSnapshot snapshot = await uploadTask;
      setState(() => isUploading = false);
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      debugPrint("Error uploading image: $e");
      setState(() => isUploading = false);
      return null;
    }
  }

  void _openGoogleMaps(String location) {
    final latLng = location.split(',');
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GoogleMapScreen(
          latitude: double.parse(latLng[0].trim()),
          longitude: double.parse(latLng[1].trim()),
        ),
      ),
    );
  }

  void _openNoteDialog({String? docID, String? existingText, String? existingImageUrl, String? existingLocation}) {
    textController.text = existingText ?? "";
    _image = null;
    imageUrl = existingImageUrl;
    imageLocation = existingLocation;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, StateSetter setState) { // Correct way to define StateSetter
            return AlertDialog(
              title: Text(docID == null ? "Add Observation" : "Edit Observation"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: textController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: "Enter your observation",
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.photo_library),
                        onPressed: () async {
                          await _pickImage(ImageSource.gallery, setState);
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.camera_alt),
                        onPressed: () async {
                          await _pickImage(ImageSource.camera, setState);
                        },
                      ),

                    ],
                  ),
                  if (_image != null) Image.file(_image!, height: 100),
                  if (imageUrl != null) Image.network(imageUrl!, height: 100),
                  if (imageLocation != null)
                    Text("Location: $imageLocation", style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  if (isUploading) const CircularProgressIndicator(),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: textController.text.isNotEmpty && _image != null && imageLocation != null
                      ? () async {
                    setState(() => isUploading = true);
                    String? finalImageUrl = await _uploadImage(_image!);
                    if (finalImageUrl != null) {
                      firestoreService.addObservation(
                        textController.text,
                        imageLocation ?? "No location",
                        finalImageUrl,
                      );
                    }
                    setState(() => isUploading = false);
                    Navigator.pop(context);
                  }
                      : null,
                  child: const Text("Save"),
                ),
              ],
            );
          },
        );
      },
    );

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Observations"), backgroundColor: Colors.blue),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openNoteDialog(),
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: firestoreService.getObservationsStream(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          return ListView(
            children: snapshot.data!.docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10), // More margin for spacing
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), // Rounded corners
                elevation: 2, // Adds shadow for better look
                child: Padding(
                  padding: const EdgeInsets.all(10), // More padding inside card
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      if (data['image'] != null)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10), // Rounded image
                          child: Image.network(
                            data['image'],
                            width: 100,
                            height: 100,
                            fit: BoxFit.cover,
                          ),
                        )
                      else
                        const Icon(Icons.image, size: 80, color: Colors.grey), // Placeholder icon if no image

                      const SizedBox(width: 10), // Spacing between image and text

                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              data['name'] ?? "No Name",
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              data['location'] ?? "No location available",
                              style: const TextStyle(fontSize: 14, color: Colors.black54),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 10), // Spacing before buttons

                      Column(
                        children: [
                          if (data['location'] != null)
                            IconButton(
                              icon: const Icon(Icons.map, color: Colors.blue, size: 25),
                              onPressed: () {
                                _openGoogleMaps(data['location']!);
                              },
                            ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red, size: 25),
                            onPressed: () => firestoreService.deleteObservation(doc.id),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}

