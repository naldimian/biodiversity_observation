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

//Latest code

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cubaankedua/services/firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:geolocator/geolocator.dart';
import 'package:path/path.dart' as path;

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

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    } else {
      print("No image selected.");
    }
  }


  Future<void> _captureImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  Future<void> _getCurrentLocation() async {
    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    setState(() {
      locationController.text = "${position.latitude}, ${position.longitude}";
    });
  }

  Future<String?> _uploadImage(File image) async {
    try {
      print("Uploading image...");

      final ref = FirebaseStorage.instance
          .ref()
          .child('images')
          .child('observations/${DateTime.now().millisecondsSinceEpoch}.jpg');

      UploadTask uploadTask = ref.putFile(image);
      TaskSnapshot snapshot = await uploadTask;

      String downloadUrl = await snapshot.ref.getDownloadURL();
      print("Image uploaded: $downloadUrl");  // ✅ Debugging

      return downloadUrl;
    } catch (e) {
      print("Error uploading image: $e");
      return null;
    }
  }



  void openNoteBox({String? docID, String? existingText, String? existingLocation, String? existingImageUrl}) {
    if (existingText != null) {
      textController.text = existingText;
    } else {
      textController.clear();
    }

    if (existingLocation != null) {
      locationController.text = existingLocation;
    } else {
      locationController.clear();
    }

    _image = null;
    imageUrl = existingImageUrl;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
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
            TextField(
              controller: locationController,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                hintText: "Enter or fetch location",
                suffixIcon: IconButton(
                  icon: const Icon(Icons.location_on),
                  onPressed: _getCurrentLocation,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  icon: const Icon(Icons.photo_library),
                  onPressed: _pickImage,
                ),
                IconButton(
                  icon: const Icon(Icons.camera_alt),
                  onPressed: _captureImage,
                ),
              ],
            ),
            if (_image != null) ...[
              const SizedBox(height: 10),
              Image.file(_image!, height: 100),
            ] else if (imageUrl != null) ...[
              const SizedBox(height: 10),
              Image.network(imageUrl!, height: 100),
            ],
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel")
          ),
          ElevatedButton(
            onPressed: () async {
              String? finalImageUrl = imageUrl;

              if (_image != null) {
                finalImageUrl = await _uploadImage(_image!);
              }

              if (docID == null) {
                firestoreService.addObservation(
                    textController.text,
                    locationController.text,
                    finalImageUrl  // ✅ Make sure this is not null
                );
              } else {
                firestoreService.updateObservation(
                    docID,
                    textController.text,
                    locationController.text,
                    finalImageUrl
                );
              }

              textController.clear();
              locationController.clear();
              imageUrl = null;
              Navigator.pop(context);
            }
,
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
                DocumentSnapshot document = observationsList[index];
                String docID = document.id;
                Map<String, dynamic> data = document.data() as Map<String, dynamic>;
                String observationText = data['name'] ?? "No data available";
                String observationLocation = data['location'] ?? "No location available";
                String? observationImage = data['image'];

                return Card(
                  child: ListTile(
                    leading: data['image'] != null
                        ? Image.network(
                      data['image'],
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return CircularProgressIndicator();
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(Icons.image_not_supported, size: 50);
                      },
                    )
                        : Icon(Icons.image, size: 50),  // Show placeholder if no image

                    title: Text(data['name'] ?? "No Name"),
                    subtitle: Text(data['location'] ?? "No Location"),
                    trailing: IconButton(
                      icon: Icon(Icons.delete, color: Colors.red),
                      onPressed: () => firestoreService.deleteObservation(docID),
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
