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



/*
//Latest code

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cubaankedua/services/firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:geolocator/geolocator.dart';
import 'package:path/path.dart' as path;
import 'package:exif/exif.dart';

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

  //try new mthod
  /*
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
*/



  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      File imageFile = File(pickedFile.path);
      _extractLocationFromImage(imageFile); // Extract GPS data
      setState(() {
        _image = imageFile;
      });
    } else {
      print("No image selected.");
    }
  }

  Future<void> _captureImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      File imageFile = File(pickedFile.path);
      _extractLocationFromImage(imageFile); // Extract GPS data
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
        locationController.text = "$latitude, $longitude";
      });

      print("Extracted GPS: $latitude, $longitude");
    } else {
      print("No GPS data found in image.");
    }
  }

// Convert EXIF GPS format to decimal degrees
  double _convertExifGpsToDecimal(List<dynamic> values, String? ref) {
    if (values.length != 3) return 0.0; // Ensure there are 3 values (degrees, minutes, seconds)

    double degrees = values[0].toDouble();
    double minutes = values[1].toDouble();
    double seconds = values[2].toDouble();

    double decimal = degrees + (minutes / 60) + (seconds / 3600);

    // Adjust for N/S or E/W reference
    if (ref == 'S' || ref == 'W') {
      decimal = -decimal;
    }

    return decimal;
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
//try
               /* return Card(
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
                );*/
                return Card(
                  child: ListTile(
                    leading: observationImage != null
                        ? Image.network(
                      observationImage,
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return CircularProgressIndicator();
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(Icons.image_not_supported, size: 50);
                      },
                    )
                        : const Icon(Icons.image, size: 50),  // Placeholder if no image

                    title: Text(observationText),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(observationLocation), // Display location from Firestore
                        if (observationImage != null) Text("📍 Image GPS: $observationLocation"),
                      ],
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
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
*/

//not working

/*
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cubaankedua/services/firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:exif/exif.dart';

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

  //just added
  @override
  void dispose() {
    textController.dispose();
    locationController.dispose(); // Prevent memory leaks
    super.dispose();
  }


  void openNoteBox({String? docID, String? existingText, String? existingImageUrl}) {
    textController.text = existingText ?? "";
    _image = null;
    imageUrl = existingImageUrl;
    imageLocation = null;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
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
                    IconButton(icon: const Icon(Icons.photo_library), onPressed: _pickImage),
                    IconButton(icon: const Icon(Icons.camera_alt), onPressed: _captureImage),
                  ],
                ),
                if (_image != null) Image.file(_image!, height: 100),
                if (imageUrl != null) Image.network(imageUrl!, height: 100),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
              ElevatedButton(
                onPressed: (textController.text.isNotEmpty && _image != null)
                    ? () async {
                  String? finalImageUrl = await _uploadImage(_image!);
                  if (docID == null) {
                    firestoreService.addObservation(
                        textController.text,
                        locationController.text,
                        finalImageUrl ?? "" // Ensure a non-null string is passed
                    );

                  } else {
                    firestoreService.updateObservation(
                        docID,
                        textController.text,
                        locationController.text,
                        finalImageUrl ?? "" // Ensure a non-null string is passed
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
                    leading: data['image'] != null ? Image.network(data['image'], width: 50, height: 50, fit: BoxFit.cover) : const Icon(Icons.image),
                    title: Text(data['name'] ?? "No Name"),
                    subtitle: Text(data['location'] ?? "No location available"),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
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
}*/

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cubaankedua/services/firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:exif/exif.dart';

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

  /*
  void openNoteBox({String? docID, String? existingText, String? existingImageUrl, String? existingLocation}) {
    textController.text = existingText ?? "";
    _image = null;
    imageUrl = existingImageUrl;
    imageLocation = existingLocation;

    bool isSaveEnabled = textController.text.isNotEmpty && (_image != null || imageUrl != null);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          void updateSaveButtonState() {
            setState(() {
              isSaveEnabled = textController.text.isNotEmpty && (_image != null || imageUrl != null);
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
                  String? finalImageUrl = _image != null ? await _uploadImage(_image!) : imageUrl;
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
*/

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
                    leading: data['image'] != null ? Image.network(data['image'], width: 50, height: 50, fit: BoxFit.cover) : const Icon(Icons.image),
                    title: Text(data['name'] ?? "No Name"),
                    subtitle: Text(data['location'] ?? "No location available"),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
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

