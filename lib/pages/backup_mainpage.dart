/* FR IMPORTANT

import 'package:cached_network_image/cached_network_image.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:exif/exif.dart';
import 'package:cubaankedua/components/my_drawer.dart';
import 'package:cubaankedua/services/firestore.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:timeago/timeago.dart' as timeago;




// ADD
import 'package:cubaankedua/classifier.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> with TickerProviderStateMixin {
  final FirestoreService firestore = FirestoreService();
  final picker = ImagePicker();
  File? selectedImage;
  double? latitude;
  double? longitude;

  String? selectedOrganismType;
  final TextEditingController commonNameController = TextEditingController();
  final TextEditingController speciesNameController = TextEditingController();
  bool isUploading = false;

  late TabController _tabController;

  // ADD: classifier instance and classification result
  final Classifier _classifier = Classifier();
  String _classificationResult = "";

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // INIT: Load ML model
    _classifier.loadModel();
  }

  @override
  void dispose() {
    _classifier.dispose(); // ADD
    _tabController.dispose();
    commonNameController.dispose();
    speciesNameController.dispose();
    super.dispose();
  }

  void showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  Future<void> pickImage() async {
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    final bytes = await picked.readAsBytes();
    final tags = await readExifFromBytes(bytes);

    try {
      if (tags.containsKey('GPS GPSLatitude') &&
          tags.containsKey('GPS GPSLatitudeRef') &&
          tags.containsKey('GPS GPSLongitude') &&
          tags.containsKey('GPS GPSLongitudeRef')) {
        final latValues = _extractDMS(tags['GPS GPSLatitude']);
        final lonValues = _extractDMS(tags['GPS GPSLongitude']);
        final latRef = tags['GPS GPSLatitudeRef']!.printable;
        final lonRef = tags['GPS GPSLongitudeRef']!.printable;

        double lat = _convertToDecimal(latValues, latRef);
        double lon = _convertToDecimal(lonValues, lonRef);

        setState(() {
          selectedImage = File(picked.path);
          latitude = lat;
          longitude = lon;
        });

        // ADD: Only classify if Mammal is selected
        if (selectedOrganismType == 'Mammal') {
          final result = await _classifier.classifyImage(File(picked.path));
          setState(() {
            _classificationResult = result;
            speciesNameController.text = result;
          });

          showErrorDialog("Species Identified", "🧠 Predicted Species: $result");
        }

        showErrorDialog("Location Found", "📍 Location: $lat, $lon");
      } else {
        setState(() {
          selectedImage = null;
          latitude = null;
          longitude = null;
        });
        showErrorDialog("Missing Location Info", "❌ This image does not contain GPS location metadata. Please choose another image.");
      }
    } catch (e) {
      showErrorDialog("Error", "⚠️ Failed to read image metadata.\n\nDetails: $e");
    }
  }

  List<double> _extractDMS(IfdTag? tag) {
    if (tag == null) throw const FormatException("GPS tag is null.");
    try {
      final raw = tag.printable;
      final parts = raw.split(',').map((e) => e.trim());

      return parts.map<double>((part) {
        if (part.contains('/')) {
          final nums = part.split('/');
          final num = double.tryParse(nums[0]) ?? 0;
          final denom = double.tryParse(nums[1]) ?? 1;
          return num / denom;
        } else {
          return double.tryParse(part) ?? 0;
        }
      }).toList();
    } catch (e) {
      throw FormatException("Error converting GPS data: $e");
    }
  }

  double _convertToDecimal(List<double> dms, String ref) {
    double decimal = dms[0] + (dms[1] / 60.0) + (dms[2] / 3600.0);
    if (ref == 'S' || ref == 'W') decimal *= -1;
    return decimal;
  }

  Future<void> uploadObservation() async {
    if (selectedImage == null ||
        selectedOrganismType == null ||
        commonNameController.text.isEmpty ||
        speciesNameController.text.isEmpty ||
        latitude == null || longitude == null) {
      showErrorDialog("Incomplete Fields", "⚠️ Please complete all fields and select an image with GPS metadata.");
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          content: Row(
            children: const [
              CircularProgressIndicator(),
              SizedBox(width: 20),
              Text("Uploading...", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
        );
      },
    );

    setState(() => isUploading = true);
    try {
      final fileName = DateTime.now().millisecondsSinceEpoch.toString();
      final ref = FirebaseStorage.instance.ref().child('uploads/$fileName.jpg');
      final uploadTask = ref.putFile(selectedImage!);
      final snapshot = await uploadTask.whenComplete(() => null);
      final imageUrl = await snapshot.ref.getDownloadURL();

      await firestore.addObservation(
        organismType: selectedOrganismType!,
        commonName: commonNameController.text.trim(),
        speciesName: speciesNameController.text.trim(),
        latitude: latitude!,
        longitude: longitude!,
        imageUrl: imageUrl,
      );

      if (mounted) {
        resetForm();
        Navigator.pop(context);
        Navigator.pop(context);
      }
    } catch (e) {
      Navigator.pop(context);
      showErrorDialog("Upload Failed", "❌ Upload failed. Please try again.\n\nDetails: $e");
    }

    setState(() => isUploading = false);
  }

  void resetForm() {
    setState(() {
      selectedOrganismType = null;
      commonNameController.clear();
      speciesNameController.clear();
      selectedImage = null;
      latitude = null;
      longitude = null;
      _classificationResult = "";
    });
  }

  void showUploadForm() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 20, right: 20, top: 20),
        child: SingleChildScrollView(
          child: Column(
            children: [
              const Text("New Observation", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: selectedOrganismType,
                decoration: const InputDecoration(labelText: "Organism Type"),
                items: ['Mammal', 'Plant']
                    .map((type) => DropdownMenuItem(value: type, child: Text(type)))
                    .toList(),
                onChanged: (val) => setState(() => selectedOrganismType = val),
              ),
              TextField(
                controller: commonNameController,
                decoration: const InputDecoration(labelText: "Common Name"),
              ),
              TextField(
                controller: speciesNameController,
                readOnly: selectedOrganismType == 'Mammal', // ADD
                decoration: const InputDecoration(labelText: "Species Name"),
              ),
              const SizedBox(height: 10),
              ElevatedButton.icon(
                icon: const Icon(Icons.image),
                label: const Text("Select Image"),
                onPressed: pickImage,
              ),
              if (selectedImage != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      selectedImage!,
                      height: 250, // Increased height
                      width: double.infinity, // Makes it expand horizontally
                      fit: BoxFit.cover,
                    ),
                  ),
                ),

              const SizedBox(height: 10),
              ElevatedButton.icon(
                icon: const Icon(Icons.upload),
                label: const Text("Upload"),
                onPressed: isUploading ? null : uploadObservation,
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildObservationTab(String type) {
    return StreamBuilder(
      stream: firestore.getObservationsByType(type),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

        final data = snapshot.data!.docs;
        if (data.isEmpty) {
          return const Center(child: Text("No observations found."));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: data.length,
          itemBuilder: (context, index) {
            final obs = data[index];
            final latitude = obs['Latitude'] as double?;
            final longitude = obs['Longitude'] as double?;
            final imageUrl = obs['ImageURL'];

            final timestamp = obs['Timestamp'] as Timestamp?;
            String formattedTime = 'Unknown time';

            if (timestamp != null) {
              final uploadDate = timestamp.toDate();
              final now = DateTime.now();
              final difference = now.difference(uploadDate);

              if (difference.inHours > 23) {
                formattedTime = DateFormat('d MMMM yyyy').format(uploadDate); // e.g., 15 April 2025
              } else {
                formattedTime = timeago.format(uploadDate);
              }
            }


            // tbc
            /*
            final formattedTime = timestamp != null
                ? DateFormat('yyyy-MM-dd – HH:mm').format(timestamp.toDate())
                : 'Unknown Time';
            */

            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "${obs['CommonName']} (${obs['SpeciesName']})",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: CachedNetworkImage(
                            imageUrl: imageUrl,
                            height: 150,
                            width: 150,
                            fit: BoxFit.cover,
                            placeholder: (context, url) =>
                            const Center(child: CircularProgressIndicator()),
                            errorWidget: (context, url, error) => const Icon(Icons.error),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("${obs['OrganismType']}"),
                              Text("${obs['UserEmail']}"),
                              Text(
                                latitude != null && longitude != null
                                    ? "Location: $latitude, $longitude"
                                    : "Location: Not available",
                              ),
                              Text("$formattedTime"
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );

      },
    );
  }

  Future<void> _loadImage(String imageUrl) async {
    try {
      await FirebaseStorage.instance.refFromURL(imageUrl).getDownloadURL();
    } catch (e) {
      throw Exception("Failed to load image: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const MyDrawer(),
      appBar: AppBar(
        title: const Text("Observations"),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Mammals'),
            Tab(text: 'Plants'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          buildObservationTab('Mammal'),
          buildObservationTab('Plant'),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: showUploadForm,
        child: const Icon(Icons.add),
      ),
    );
  }
}

 */

//latest

/*
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:exif/exif.dart';
import 'package:cubaankedua/components/my_drawer.dart';
import 'package:cubaankedua/services/firestore.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:timeago/timeago.dart' as timeago;




// ADD
import 'package:cubaankedua/classifier.dart';
import 'package:url_launcher/url_launcher.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> with TickerProviderStateMixin {
  final FirestoreService firestore = FirestoreService();
  final picker = ImagePicker();
  File? selectedImage;
  double? latitude;
  double? longitude;

  String? selectedOrganismType;
  final TextEditingController commonNameController = TextEditingController();
  final TextEditingController speciesNameController = TextEditingController();
  bool isUploading = false;

  late TabController _tabController;

  // ADD: classifier instance and classification result
  final Classifier _classifier = Classifier();
  String _classificationResult = "";

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // INIT: Load ML model
    _classifier.loadModel();
  }

  @override
  void dispose() {
    _classifier.dispose(); // ADD
    _tabController.dispose();
    commonNameController.dispose();
    speciesNameController.dispose();
    super.dispose();
  }

  void showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  Future<void> pickImage() async {
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    final bytes = await picked.readAsBytes();
    final tags = await readExifFromBytes(bytes);

    try {
      if (tags.containsKey('GPS GPSLatitude') &&
          tags.containsKey('GPS GPSLatitudeRef') &&
          tags.containsKey('GPS GPSLongitude') &&
          tags.containsKey('GPS GPSLongitudeRef')) {
        final latValues = _extractDMS(tags['GPS GPSLatitude']);
        final lonValues = _extractDMS(tags['GPS GPSLongitude']);
        final latRef = tags['GPS GPSLatitudeRef']!.printable;
        final lonRef = tags['GPS GPSLongitudeRef']!.printable;

        double lat = _convertToDecimal(latValues, latRef);
        double lon = _convertToDecimal(lonValues, lonRef);

        setState(() {
          selectedImage = File(picked.path);
          latitude = lat;
          longitude = lon;
        });

        // ADD: Only classify if Mammal is selected
        if (selectedOrganismType == 'Mammal') {
          final result = await _classifier.classifyImage(File(picked.path));
          setState(() {
            _classificationResult = result;
            speciesNameController.text = result;
          });

          showErrorDialog("Species Identified", "🧠 Predicted Species: $result");
        }

        showErrorDialog("Location Found", "📍 Location: $lat, $lon");
      } else {
        setState(() {
          selectedImage = null;
          latitude = null;
          longitude = null;
        });
        showErrorDialog("Missing Location Info", "❌ This image does not contain GPS location metadata. Please choose another image.");
      }
    } catch (e) {
      showErrorDialog("Error", "⚠️ Failed to read image metadata.\n\nDetails: $e");
    }
  }

  List<double> _extractDMS(IfdTag? tag) {
    if (tag == null) throw const FormatException("GPS tag is null.");
    try {
      final raw = tag.printable;
      final parts = raw.split(',').map((e) => e.trim());

      return parts.map<double>((part) {
        if (part.contains('/')) {
          final nums = part.split('/');
          final num = double.tryParse(nums[0]) ?? 0;
          final denom = double.tryParse(nums[1]) ?? 1;
          return num / denom;
        } else {
          return double.tryParse(part) ?? 0;
        }
      }).toList();
    } catch (e) {
      throw FormatException("Error converting GPS data: $e");
    }
  }

  double _convertToDecimal(List<double> dms, String ref) {
    double decimal = dms[0] + (dms[1] / 60.0) + (dms[2] / 3600.0);
    if (ref == 'S' || ref == 'W') decimal *= -1;
    return decimal;
  }

  Future<void> uploadObservation() async {
    if (selectedImage == null ||
        selectedOrganismType == null ||
        commonNameController.text.isEmpty ||
        speciesNameController.text.isEmpty ||
        latitude == null || longitude == null) {
      showErrorDialog("Incomplete Fields", "⚠️ Please complete all fields and select an image with GPS metadata.");
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          content: Row(
            children: const [
              CircularProgressIndicator(),
              SizedBox(width: 20),
              Text("Uploading...", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
        );
      },
    );

    setState(() => isUploading = true);
    try {
      final fileName = DateTime.now().millisecondsSinceEpoch.toString();
      final ref = FirebaseStorage.instance.ref().child('uploads/$fileName.jpg');
      final uploadTask = ref.putFile(selectedImage!);
      final snapshot = await uploadTask.whenComplete(() => null);
      final imageUrl = await snapshot.ref.getDownloadURL();

      await firestore.addObservation(
        organismType: selectedOrganismType!,
        commonName: commonNameController.text.trim(),
        speciesName: speciesNameController.text.trim(),
        latitude: latitude!,
        longitude: longitude!,
        imageUrl: imageUrl,
      );

      if (mounted) {
        resetForm();
        Navigator.pop(context);
        Navigator.pop(context);
      }
    } catch (e) {
      Navigator.pop(context);
      showErrorDialog("Upload Failed", "❌ Upload failed. Please try again.\n\nDetails: $e");
    }

    setState(() => isUploading = false);
  }

  void resetForm() {
    setState(() {
      selectedOrganismType = null;
      commonNameController.clear();
      speciesNameController.clear();
      selectedImage = null;
      latitude = null;
      longitude = null;
      _classificationResult = "";
    });
  }

  void _openInGoogleMaps(double lat, double lon) async {
    final url = Uri.parse("https://www.google.com/maps/search/?api=1&query=$lat,$lon");

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      showErrorDialog("Error", "❌ Could not open Google Maps.");
    }
  }


  void showUploadForm() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 20, right: 20, top: 20),
        child: SingleChildScrollView(
          child: Column(
            children: [
              const Text("New Observation", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: selectedOrganismType,
                decoration: const InputDecoration(labelText: "Organism Type"),
                items: ['Mammal', 'Plant']
                    .map((type) => DropdownMenuItem(value: type, child: Text(type)))
                    .toList(),
                onChanged: (val) => setState(() => selectedOrganismType = val),
              ),
              TextField(
                controller: commonNameController,
                decoration: const InputDecoration(labelText: "Common Name"),
              ),
              TextField(
                controller: speciesNameController,
                readOnly: selectedOrganismType == 'Mammal', // ADD
                decoration: const InputDecoration(labelText: "Species Name"),
              ),
              const SizedBox(height: 10),
              ElevatedButton.icon(
                icon: const Icon(Icons.image),
                label: const Text("Select Image"),
                onPressed: pickImage,
              ),
              if (selectedImage != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      selectedImage!,
                      height: 250, // Increased height
                      width: double.infinity, // Makes it expand horizontally
                      fit: BoxFit.cover,
                    ),
                  ),
                ),

              const SizedBox(height: 10),
              ElevatedButton.icon(
                icon: const Icon(Icons.upload),
                label: const Text("Upload"),
                onPressed: isUploading ? null : uploadObservation,
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildObservationTab(String type) {
    return StreamBuilder(
      stream: firestore.getObservationsByType(type),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

        final data = snapshot.data!.docs;
        if (data.isEmpty) {
          return const Center(child: Text("No observations found."));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: data.length,
          itemBuilder: (context, index) {
            final obs = data[index];
            final latitude = obs['Latitude'] as double?;
            final longitude = obs['Longitude'] as double?;
            final imageUrl = obs['ImageURL'];

            final timestamp = obs['Timestamp'] as Timestamp?;
            String formattedTime = 'Unknown time';

            if (timestamp != null) {
              final uploadDate = timestamp.toDate();
              final now = DateTime.now();
              final difference = now.difference(uploadDate);

              if (difference.inHours > 23) {
                formattedTime = DateFormat('d MMMM yyyy').format(uploadDate); // e.g., 15 April 2025
              } else {
                formattedTime = timeago.format(uploadDate);
              }
            }


            // tbc
            /*
            final formattedTime = timestamp != null
                ? DateFormat('yyyy-MM-dd – HH:mm').format(timestamp.toDate())
                : 'Unknown Time';
            */

            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "${obs['CommonName']} (${obs['SpeciesName']})",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: CachedNetworkImage(
                            imageUrl: imageUrl,
                            height: 150,
                            width: 150,
                            fit: BoxFit.cover,
                            placeholder: (context, url) =>
                            const Center(child: CircularProgressIndicator()),
                            errorWidget: (context, url, error) => const Icon(Icons.error),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("${obs['OrganismType']}"),
                              Text("${obs['UserEmail']}"),
                              Text(
                                latitude != null && longitude != null
                                    ? "Location: $latitude, $longitude"
                                    : "Location: Not available",
                              ),
                              Text("$formattedTime"),
                              const SizedBox(height: 25),
                              if (latitude != null && longitude != null)
                                TextButton.icon(
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    foregroundColor: Theme.of(context).colorScheme.inversePrimary, // text and icon color
                                    backgroundColor: Theme.of(context).colorScheme.primary, // subtle background
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  icon: const Icon(
                                      color: Colors.red,
                                      Icons.location_on
                                  ),
                                  label: const Text(
                                    "Open in Maps",
                                    style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 14,
                                    ),
                                  ),
                                  onPressed: () {
                                    // TODO: Replace with your custom action
                                    _openInGoogleMaps(latitude, longitude);
                                  },
                                ),


                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );

          },
        );

      },
    );
  }

  Future<void> _loadImage(String imageUrl) async {
    try {
      await FirebaseStorage.instance.refFromURL(imageUrl).getDownloadURL();
    } catch (e) {
      throw Exception("Failed to load image: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const MyDrawer(),
      appBar: AppBar(
        title: const Text("Observations"),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Mammals'),
            Tab(text: 'Plants'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          buildObservationTab('Mammal'),
          buildObservationTab('Plant'),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: showUploadForm,
        child: const Icon(Icons.add),
      ),
    );
  }
}
*/


/*


import 'package:cached_network_image/cached_network_image.dart';
import 'package:exif/exif.dart' as exifdart;
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:exif/exif.dart';
import 'package:cubaankedua/components/my_drawer.dart';
import 'package:cubaankedua/services/firestore.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:cubaankedua/classifier.dart';
import 'package:url_launcher/url_launcher.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> with TickerProviderStateMixin {
  final FirestoreService firestore = FirestoreService();
  final picker = ImagePicker();
  File? selectedImage;
  double? latitude;
  double? longitude;

  String? selectedOrganismType;
  final TextEditingController commonNameController = TextEditingController();
  final TextEditingController speciesNameController = TextEditingController();
  bool isUploading = false;

  late TabController _tabController;

  // ADD: classifier instance and classification result
  final Classifier _classifier = Classifier();
  String _classificationResult = "";

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // INIT: Load ML model
    _classifier.loadModel();
  }

  @override
  void dispose() {
    _classifier.dispose(); // ADD
    _tabController.dispose();
    commonNameController.dispose();
    speciesNameController.dispose();
    super.dispose();
  }

  void showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }
  Future<void> pickImage() async {
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    final bytes = await picked.readAsBytes();
    final tags = await readExifFromBytes(bytes);

    print("EXIF Tags: $tags"); // Debug print to check if EXIF is being read

    if (tags.containsKey('GPS GPSLatitude') &&
        tags.containsKey('GPS GPSLatitudeRef') &&
        tags.containsKey('GPS GPSLongitude') &&
        tags.containsKey('GPS GPSLongitudeRef')) {

      final latValues = _extractDMS(tags['GPS GPSLatitude']);
      final lonValues = _extractDMS(tags['GPS GPSLongitude']);
      final latRef = tags['GPS GPSLatitudeRef']!.printable;
      final lonRef = tags['GPS GPSLongitudeRef']!.printable;

      double lat = _convertToDecimal(latValues, latRef);
      double lon = _convertToDecimal(lonValues, lonRef);

      // If GPS is valid, update the state
      if (lat < -90 || lat > 90 || lon < -180 || lon > 180) {
        showErrorDialog("Invalid Location", "⚠️ Extracted coordinates are out of valid range.");
        return;
      }

      setState(() {
        selectedImage = File(picked.path);
        latitude = lat;
        longitude = lon;
      });

     // showErrorDialog("Location Found", "📍 Location: $lat, $lon");

      // ADD: Only classify if Mammal is selected
      if (selectedOrganismType == 'Mammal') {
        final result = await _classifier.classifyImage(File(picked.path));
        setState(() {
          _classificationResult = result;
          speciesNameController.text = result;
        });

        //showErrorDialog("Species Identified", "🧠 Predicted Species: $result");
      }

    } else {
      showErrorDialog("Missing Location Info", "❌ This image does not contain GPS location metadata.");
    }
  }

  Future<void> checkExif(String imagePath) async {
    final bytes = await File(imagePath).readAsBytes();
    final data = await exifdart.readExifFromBytes(bytes);

    print("GPSLatitude: ${data['GPS GPSLatitude']}");
    print("GPSLongitude: ${data['GPS GPSLongitude']}");
  }

// Replace the existing _extractDMS function with this one:
  List<double> _extractDMS(IfdTag? tag) {
    if (tag == null || tag.values.length != 3) {
      throw const FormatException("Invalid GPS DMS tag.");
    }

    final dmsList = <double>[];
    for (var value in tag.values.toList()) {
      final valueStr = value.toString();
      if (valueStr.contains('/')) {
        final parts = valueStr.split('/');
        final numerator = double.tryParse(parts[0]) ?? 0;
        final denominator = double.tryParse(parts[1]) ?? 1;
        dmsList.add(numerator / denominator);
      } else {
        dmsList.add(double.tryParse(valueStr) ?? 0);
      }
    }
    return dmsList;
  }

// And this is your decimal conversion helper (keep as-is or use if needed):
  double _convertDMSToDecimal(double degrees, double minutes, double seconds) {
    return degrees + (minutes / 60.0) + (seconds / 3600.0);
  }

// Convert the DMS values to Decimal Degrees (DD)
  double _convertToDecimal(List<double> dms, String ref) {
    double decimal = dms[0] + (dms[1] / 60.0) + (dms[2] / 3600.0);
    if (ref == 'S' || ref == 'W') decimal *= -1;  // Negate for South and West
    return decimal;
  }


  Future<void> uploadObservation() async {
    if (selectedImage == null ||
        selectedOrganismType == null ||
        commonNameController.text.isEmpty ||
        speciesNameController.text.isEmpty ||
        latitude == null || longitude == null) {
      showErrorDialog("Incomplete Fields", "⚠️ Please complete all fields and select an image with GPS metadata.");
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          content: Row(
            children: const [
              CircularProgressIndicator(),
              SizedBox(width: 20),
              Text("Uploading...", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
        );
      },
    );

    setState(() => isUploading = true);
    try {
      final fileName = DateTime.now().millisecondsSinceEpoch.toString();
      final ref = FirebaseStorage.instance.ref().child('uploads/$fileName.jpg');
      final uploadTask = ref.putFile(selectedImage!);
      final snapshot = await uploadTask.whenComplete(() => null);
      final imageUrl = await snapshot.ref.getDownloadURL();

      await firestore.addObservation(
        organismType: selectedOrganismType!,
        commonName: commonNameController.text.trim(),
        speciesName: speciesNameController.text.trim(),
        latitude: latitude!,
        longitude: longitude!,
        imageUrl: imageUrl,
      );

      if (mounted) {
        resetForm();
        Navigator.pop(context);
        Navigator.pop(context);
      }
    } catch (e) {
      Navigator.pop(context);
      showErrorDialog("Upload Failed", "❌ Upload failed. Please try again.\n\nDetails: $e");
    }

    setState(() => isUploading = false);
  }

  void resetForm() {
    setState(() {
      selectedOrganismType = null;
      commonNameController.clear();
      speciesNameController.clear();
      selectedImage = null;
      latitude = null;
      longitude = null;
      _classificationResult = "";
    });
  }

  void _openInGoogleMaps(double lat, double lon) async {
    final url = Uri.parse("https://www.google.com/maps/search/?api=1&query=$lat,$lon");

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      showErrorDialog("Error", "❌ Could not open Google Maps.");
    }
  }


  void showUploadForm() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 20,
          right: 20,
          top: 20,
        ),
        child: SingleChildScrollView(
          child: Column(
            children: [
              const Text("New Observation", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: selectedOrganismType,
                decoration: const InputDecoration(labelText: "Organism Type"),
                items: ['Mammal', 'Plant']
                    .map((type) => DropdownMenuItem(value: type, child: Text(type)))
                    .toList(),
                onChanged: (val) => setState(() => selectedOrganismType = val),
              ),
              TextField(
                controller: commonNameController,
                decoration: const InputDecoration(labelText: "Common Name"),
              ),
              TextField(
                controller: speciesNameController,
                readOnly: selectedOrganismType == 'Mammal',
                decoration: const InputDecoration(labelText: "Species Name"),
              ),
              const SizedBox(height: 10),
              ElevatedButton.icon(
                icon: const Icon(Icons.image),
                label: const Text("Select Image"),
                onPressed: pickImage,
              ),
              if (selectedImage != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      selectedImage!,
                      height: 250,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              if (latitude != null && longitude != null) ...[
                const SizedBox(height: 10),
                Text(
                  "📍 $latitude, $longitude",
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ],
              const SizedBox(height: 20),
              ElevatedButton.icon(
                icon: const Icon(Icons.upload),
                label: const Text("Upload"),
                onPressed: isUploading ? null : uploadObservation,
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }


  Widget buildObservationTab(String type) {
    return StreamBuilder(
      stream: firestore.getObservationsByType(type),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

        final data = snapshot.data!.docs;
        if (data.isEmpty) {
          return const Center(child: Text("No observations found."));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: data.length,
          itemBuilder: (context, index) {
            final obs = data[index];
            final latitude = obs['Latitude'] as double?;
            final longitude = obs['Longitude'] as double?;
            final imageUrl = obs['ImageURL'];

            final timestamp = obs['Timestamp'] as Timestamp?;
            String formattedTime = 'Unknown time';

            if (timestamp != null) {
              final uploadDate = timestamp.toDate();
              final now = DateTime.now();
              final difference = now.difference(uploadDate);

              if (difference.inHours > 23) {
                formattedTime = DateFormat('d MMMM yyyy').format(uploadDate); // e.g., 15 April 2025
              } else {
                formattedTime = timeago.format(uploadDate);
              }
            }

            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "${obs['CommonName']} (${obs['SpeciesName']})",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: CachedNetworkImage(
                            imageUrl: imageUrl,
                            height: 150,
                            width: 150,
                            fit: BoxFit.cover,
                            placeholder: (context, url) =>
                            const Center(child: CircularProgressIndicator()),
                            errorWidget: (context, url, error) => const Icon(Icons.error),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("${obs['OrganismType']}"),
                              Text("${obs['UserEmail']}"),
                              Text(
                                latitude != null && longitude != null
                                    ? "Location: $latitude, $longitude"
                                    : "Location: Not available",
                              ),
                              Text("$formattedTime"),
                              const SizedBox(height: 25),
                              if (latitude != null && longitude != null)
                                TextButton.icon(
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    foregroundColor: Theme.of(context).colorScheme.inversePrimary, // text and icon color
                                    backgroundColor: Theme.of(context).colorScheme.primary, // subtle background
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  icon: const Icon(
                                      color: Colors.red,
                                      Icons.location_on
                                  ),
                                  label: const Text(
                                    "Open in Maps",
                                    style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 14,
                                    ),
                                  ),
                                  onPressed: () {
                                    // TODO: Replace with your custom action
                                    _openInGoogleMaps(latitude, longitude);
                                  },
                                ),


                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );

          },
        );

      },
    );
  }

  Future<void> _loadImage(String imageUrl) async {
    try {
      await FirebaseStorage.instance.refFromURL(imageUrl).getDownloadURL();
    } catch (e) {
      throw Exception("Failed to load image: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const MyDrawer(),
      appBar: AppBar(
        title: const Text("Observations"),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Mammals'),
            Tab(text: 'Plants'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          buildObservationTab('Mammal'),
          buildObservationTab('Plant'),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: showUploadForm,
        child: const Icon(Icons.add),
      ),
    );
  }
}

 */

/*

import 'package:cached_network_image/cached_network_image.dart';
import 'package:exif/exif.dart' as exifdart;
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:exif/exif.dart';
import 'package:cubaankedua/components/my_drawer.dart';
import 'package:cubaankedua/services/firestore.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:cubaankedua/classifier.dart';
import 'package:url_launcher/url_launcher.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> with TickerProviderStateMixin {
  final FirestoreService firestore = FirestoreService();
  final picker = ImagePicker();
  File? selectedImage;
  double? latitude;
  double? longitude;

  String? selectedOrganismType;
  final TextEditingController commonNameController = TextEditingController();
  final TextEditingController speciesNameController = TextEditingController();
  bool isUploading = false;

  late TabController _tabController;

  // ADD: classifier instance and classification result
  final Classifier _classifier = Classifier();
  String _classificationResult = "";

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // INIT: Load ML model
    _classifier.loadModel();
  }

  @override
  void dispose() {
    _classifier.dispose(); // ADD
    _tabController.dispose();
    commonNameController.dispose();
    speciesNameController.dispose();
    super.dispose();
  }

  void showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }
  Future<void> pickImage() async {
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    final bytes = await picked.readAsBytes();
    final tags = await readExifFromBytes(bytes);

    print("EXIF Tags: $tags"); // Debug print to check if EXIF is being read

    if (tags.containsKey('GPS GPSLatitude') &&
        tags.containsKey('GPS GPSLatitudeRef') &&
        tags.containsKey('GPS GPSLongitude') &&
        tags.containsKey('GPS GPSLongitudeRef')) {

      final latValues = _extractDMS(tags['GPS GPSLatitude']);
      final lonValues = _extractDMS(tags['GPS GPSLongitude']);
      final latRef = tags['GPS GPSLatitudeRef']!.printable;
      final lonRef = tags['GPS GPSLongitudeRef']!.printable;

      double lat = _convertToDecimal(latValues, latRef);
      double lon = _convertToDecimal(lonValues, lonRef);

      // If GPS is valid, update the state
      if (lat < -90 || lat > 90 || lon < -180 || lon > 180) {
        showErrorDialog("Invalid Location", "⚠️ Extracted coordinates are out of valid range.");
        return;
      }

      setState(() {
        selectedImage = File(picked.path);
        latitude = lat;
        longitude = lon;
      });

     // showErrorDialog("Location Found", "📍 Location: $lat, $lon");

      // ADD: Only classify if Mammal is selected
      if (selectedOrganismType == 'Mammal') {
        final result = await _classifier.classifyImage(File(picked.path));
        setState(() {
          _classificationResult = result;
          speciesNameController.text = result;
        });

        //showErrorDialog("Species Identified", "🧠 Predicted Species: $result");
      }

    } else {
      showErrorDialog("Missing Location Info", "❌ This image does not contain GPS location metadata.");
    }
  }

  Future<void> checkExif(String imagePath) async {
    final bytes = await File(imagePath).readAsBytes();
    final data = await exifdart.readExifFromBytes(bytes);

    print("GPSLatitude: ${data['GPS GPSLatitude']}");
    print("GPSLongitude: ${data['GPS GPSLongitude']}");
  }

// Replace the existing _extractDMS function with this one:
  List<double> _extractDMS(IfdTag? tag) {
    if (tag == null || tag.values.length != 3) {
      throw const FormatException("Invalid GPS DMS tag.");
    }

    final dmsList = <double>[];
    for (var value in tag.values.toList()) {
      final valueStr = value.toString();
      if (valueStr.contains('/')) {
        final parts = valueStr.split('/');
        final numerator = double.tryParse(parts[0]) ?? 0;
        final denominator = double.tryParse(parts[1]) ?? 1;
        dmsList.add(numerator / denominator);
      } else {
        dmsList.add(double.tryParse(valueStr) ?? 0);
      }
    }
    return dmsList;
  }

// And this is your decimal conversion helper (keep as-is or use if needed):
  double _convertDMSToDecimal(double degrees, double minutes, double seconds) {
    return degrees + (minutes / 60.0) + (seconds / 3600.0);
  }

// Convert the DMS values to Decimal Degrees (DD)
  double _convertToDecimal(List<double> dms, String ref) {
    double decimal = dms[0] + (dms[1] / 60.0) + (dms[2] / 3600.0);
    if (ref == 'S' || ref == 'W') decimal *= -1;  // Negate for South and West
    return decimal;
  }


  Future<void> uploadObservation() async {
    if (selectedImage == null ||
        selectedOrganismType == null ||
        commonNameController.text.isEmpty ||
        speciesNameController.text.isEmpty ||
        latitude == null || longitude == null) {
      showErrorDialog("Incomplete Fields", "⚠️ Please complete all fields and select an image with GPS metadata.");
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          content: Row(
            children: const [
              CircularProgressIndicator(),
              SizedBox(width: 20),
              Text("Uploading...", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
        );
      },
    );

    setState(() => isUploading = true);
    try {
      final fileName = DateTime.now().millisecondsSinceEpoch.toString();
      final ref = FirebaseStorage.instance.ref().child('uploads/$fileName.jpg');
      final uploadTask = ref.putFile(selectedImage!);
      final snapshot = await uploadTask.whenComplete(() => null);
      final imageUrl = await snapshot.ref.getDownloadURL();

      await firestore.addObservation(
        organismType: selectedOrganismType!,
        commonName: commonNameController.text.trim(),
        speciesName: speciesNameController.text.trim(),
        latitude: latitude!,
        longitude: longitude!,
        imageUrl: imageUrl,
      );

      if (mounted) {
        resetForm();
        Navigator.pop(context);
        Navigator.pop(context);
      }
    } catch (e) {
      Navigator.pop(context);
      showErrorDialog("Upload Failed", "❌ Upload failed. Please try again.\n\nDetails: $e");
    }

    setState(() => isUploading = false);
  }

  void resetForm() {
    setState(() {
      selectedOrganismType = null;
      commonNameController.clear();
      speciesNameController.clear();
      selectedImage = null;
      latitude = null;
      longitude = null;
      _classificationResult = "";
    });
  }

  void _openInGoogleMaps(double lat, double lon) async {
    final url = Uri.parse("https://www.google.com/maps/search/?api=1&query=$lat,$lon");

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      showErrorDialog("Error", "❌ Could not open Google Maps.");
    }
  }


  void showUploadForm() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 20,
          right: 20,
          top: 20,
        ),
        child: SingleChildScrollView(
          child: Column(
            children: [
              const Text("New Observation", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: selectedOrganismType,
                decoration: const InputDecoration(labelText: "Organism Type"),
                items: ['Mammal', 'Plant']
                    .map((type) => DropdownMenuItem(value: type, child: Text(type)))
                    .toList(),
                onChanged: (val) => setState(() => selectedOrganismType = val),
              ),
              TextField(
                controller: commonNameController,
                decoration: const InputDecoration(labelText: "Common Name"),
              ),
              TextField(
                controller: speciesNameController,
                readOnly: selectedOrganismType == 'Mammal',
                decoration: const InputDecoration(labelText: "Species Name"),
              ),
              const SizedBox(height: 10),
              ElevatedButton.icon(
                icon: const Icon(Icons.image),
                label: const Text("Select Image"),
                onPressed: pickImage,
              ),
              if (selectedImage != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      selectedImage!,
                      height: 250,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              if (latitude != null && longitude != null) ...[
                const SizedBox(height: 10),
                Text(
                  "📍 $latitude, $longitude",
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ],
              const SizedBox(height: 20),
              ElevatedButton.icon(
                icon: const Icon(Icons.upload),
                label: const Text("Upload"),
                onPressed: isUploading ? null : uploadObservation,
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }


  Widget buildObservationTab(String type) {
    return StreamBuilder(
      stream: firestore.getObservationsByType(type),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

        final data = snapshot.data!.docs;
        if (data.isEmpty) {
          return const Center(child: Text("No observations found."));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: data.length,
          itemBuilder: (context, index) {
            final obs = data[index];
            final latitude = obs['Latitude'] as double?;
            final longitude = obs['Longitude'] as double?;
            final imageUrl = obs['ImageURL'];

            final timestamp = obs['Timestamp'] as Timestamp?;
            String formattedTime = 'Unknown time';

            if (timestamp != null) {
              final uploadDate = timestamp.toDate();
              final now = DateTime.now();
              final difference = now.difference(uploadDate);

              if (difference.inHours > 23) {
                formattedTime = DateFormat('d MMMM yyyy').format(uploadDate); // e.g., 15 April 2025
              } else {
                formattedTime = timeago.format(uploadDate);
              }
            }

            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "${obs['CommonName']} (${obs['SpeciesName']})",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: CachedNetworkImage(
                            imageUrl: imageUrl,
                            maxHeightDiskCache: 200,  // Cache smaller version
                            maxWidthDiskCache: 200,
                            height: 150,
                            width: 150,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                            errorWidget: (context, url, error) => const Icon(Icons.error),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("${obs['OrganismType']}"),
                              Text("${obs['UserEmail']}"),
                              Text(
                                latitude != null && longitude != null
                                    ? "Location: $latitude, $longitude"
                                    : "Location: Not available",
                              ),
                              Text("$formattedTime"),
                              const SizedBox(height: 25),
                              if (latitude != null && longitude != null)
                                TextButton.icon(
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    foregroundColor: Theme.of(context).colorScheme.inversePrimary, // text and icon color
                                    backgroundColor: Theme.of(context).colorScheme.primary, // subtle background
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  icon: const Icon(
                                      color: Colors.red,
                                      Icons.location_on
                                  ),
                                  label: const Text(
                                    "Open in Maps",
                                    style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 14,
                                    ),
                                  ),
                                  onPressed: () {
                                    // TODO: Replace with your custom action
                                    _openInGoogleMaps(latitude, longitude);
                                  },
                                ),


                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );

          },
        );

      },
    );
  }

  Future<void> _loadImage(String imageUrl) async {
    try {
      await FirebaseStorage.instance.refFromURL(imageUrl).getDownloadURL();
    } catch (e) {
      throw Exception("Failed to load image: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const MyDrawer(),
      appBar: AppBar(
        title: const Text("Observations"),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Mammals'),
            Tab(text: 'Plants'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          buildObservationTab('Mammal'),
          buildObservationTab('Plant'),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: showUploadForm,
        child: const Icon(Icons.add),
      ),
    );
  }
}

 */

/*

import 'package:cached_network_image/cached_network_image.dart';
import 'package:exif/exif.dart' as exifdart;
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:exif/exif.dart';
import 'package:cubaankedua/components/my_drawer.dart';
import 'package:cubaankedua/services/firestore.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:cubaankedua/classifier.dart';
import 'package:url_launcher/url_launcher.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> with TickerProviderStateMixin {
  final FirestoreService firestore = FirestoreService();
  final picker = ImagePicker();
  File? selectedImage;
  double? latitude;
  double? longitude;

  String? selectedOrganismType;
  final TextEditingController commonNameController = TextEditingController();
  final TextEditingController speciesNameController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  bool isUploading = false;

  late TabController _tabController;

  // ADD: classifier instance and classification result
  final Classifier _classifier = Classifier();
  String _classificationResult = "";

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // INIT: Load ML model
    _classifier.loadModel();
  }

  @override
  void dispose() {
    _classifier.dispose(); // ADD
    _tabController.dispose();
    commonNameController.dispose();
    speciesNameController.dispose();
    super.dispose();
  }

  void showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }
  Future<void> pickImage() async {
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    final bytes = await picked.readAsBytes();
    final tags = await readExifFromBytes(bytes);

    print("EXIF Tags: $tags"); // Debug print to check if EXIF is being read

    if (tags.containsKey('GPS GPSLatitude') &&
        tags.containsKey('GPS GPSLatitudeRef') &&
        tags.containsKey('GPS GPSLongitude') &&
        tags.containsKey('GPS GPSLongitudeRef')) {

      final latValues = _extractDMS(tags['GPS GPSLatitude']);
      final lonValues = _extractDMS(tags['GPS GPSLongitude']);
      final latRef = tags['GPS GPSLatitudeRef']!.printable;
      final lonRef = tags['GPS GPSLongitudeRef']!.printable;

      double lat = _convertToDecimal(latValues, latRef);
      double lon = _convertToDecimal(lonValues, lonRef);

      // If GPS is valid, update the state
      if (lat < -90 || lat > 90 || lon < -180 || lon > 180) {
        showErrorDialog("Invalid Location", "⚠️ Extracted coordinates are out of valid range.");
        return;
      }

      setState(() {
        selectedImage = File(picked.path);
        latitude = lat;
        longitude = lon;
      });

     // showErrorDialog("Location Found", "📍 Location: $lat, $lon");

      // ADD: Only classify if Mammal is selected
      if (selectedOrganismType == 'Mammal') {
        final result = await _classifier.classifyImage(File(picked.path));
        setState(() {
          _classificationResult = result;
          speciesNameController.text = result;
        });

        //showErrorDialog("Species Identified", "🧠 Predicted Species: $result");
      }

    } else {
      showErrorDialog("Missing Location Info", "This image does not contain GPS location metadata.");
    }
  }

  Future<void> checkExif(String imagePath) async {
    final bytes = await File(imagePath).readAsBytes();
    final data = await exifdart.readExifFromBytes(bytes);

    print("GPSLatitude: ${data['GPS GPSLatitude']}");
    print("GPSLongitude: ${data['GPS GPSLongitude']}");
  }

// Replace the existing _extractDMS function with this one:
  List<double> _extractDMS(IfdTag? tag) {
    if (tag == null || tag.values.length != 3) {
      throw const FormatException("Invalid GPS DMS tag.");
    }

    final dmsList = <double>[];
    for (var value in tag.values.toList()) {
      final valueStr = value.toString();
      if (valueStr.contains('/')) {
        final parts = valueStr.split('/');
        final numerator = double.tryParse(parts[0]) ?? 0;
        final denominator = double.tryParse(parts[1]) ?? 1;
        dmsList.add(numerator / denominator);
      } else {
        dmsList.add(double.tryParse(valueStr) ?? 0);
      }
    }
    return dmsList;
  }

// And this is your decimal conversion helper (keep as-is or use if needed):
  double _convertDMSToDecimal(double degrees, double minutes, double seconds) {
    return degrees + (minutes / 60.0) + (seconds / 3600.0);
  }

// Convert the DMS values to Decimal Degrees (DD)
  double _convertToDecimal(List<double> dms, String ref) {
    double decimal = dms[0] + (dms[1] / 60.0) + (dms[2] / 3600.0);
    if (ref == 'S' || ref == 'W') decimal *= -1;  // Negate for South and West
    return decimal;
  }


  Future<void> uploadObservation() async {
    if (selectedImage == null ||
        selectedOrganismType == null ||
        commonNameController.text.isEmpty ||
        speciesNameController.text.isEmpty ||
        latitude == null || longitude == null) {
      showErrorDialog("Incomplete Fields", "⚠️ Please complete all fields and select an image with GPS metadata.");
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          content: Row(
            children: const [
              CircularProgressIndicator(),
              SizedBox(width: 20),
              Text("Uploading...", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
        );
      },
    );

    setState(() => isUploading = true);
    try {
      final fileName = DateTime.now().millisecondsSinceEpoch.toString();
      final ref = FirebaseStorage.instance.ref().child('uploads/$fileName.jpg');
      final uploadTask = ref.putFile(selectedImage!);
      final snapshot = await uploadTask.whenComplete(() => null);
      final imageUrl = await snapshot.ref.getDownloadURL();

      await firestore.addObservation(
        organismType: selectedOrganismType!,
        commonName: commonNameController.text.trim(),
        speciesName: speciesNameController.text.trim(),
        latitude: latitude!,
        longitude: longitude!,
        imageUrl: imageUrl,
      );

      if (mounted) {
        resetForm();
        Navigator.pop(context);
        Navigator.pop(context);
      }
    } catch (e) {
      Navigator.pop(context);
      showErrorDialog("Upload Failed", "❌ Upload failed. Please try again.\n\nDetails: $e");
    }

    setState(() => isUploading = false);
  }

  void resetForm() {
    setState(() {
      selectedOrganismType = null;
      commonNameController.clear();
      speciesNameController.clear();
      selectedImage = null;
      latitude = null;
      longitude = null;
      _classificationResult = "";
    });
  }

  void _openInGoogleMaps(double lat, double lon) async {
    final url = Uri.parse("https://www.google.com/maps/search/?api=1&query=$lat,$lon");

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      showErrorDialog("Error", "❌ Could not open Google Maps.");
    }
  }


  void showUploadForm() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Theme.of(context).dialogBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.85,
            minChildSize: 0.5,
            maxChildSize: 0.95,
            builder: (_, scrollController) => SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: StatefulBuilder(
                builder: (context, setModalState) => Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    /// Title and Close Button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "New Observation",
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (dialogContext) => AlertDialog(
                                title: const Text("Discard Observation?"),
                                content: const Text("Are you sure you want to discard this observation?"),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(dialogContext),
                                    child: const Text("No"),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      resetForm();
                                      Navigator.pop(dialogContext);
                                      Navigator.pop(context);
                                    },
                                    child: const Text("Yes"),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    /// Dropdown for Organism
                    DropdownButtonFormField<String>(
                      value: selectedOrganismType,
                      decoration: const InputDecoration(
                        labelText: "Organism Type",
                        prefixIcon: Icon(Icons.category),
                      ),
                      items: ['Mammal', 'Plant']
                          .map((type) => DropdownMenuItem(value: type, child: Text(type)))
                          .toList(),
                      onChanged: (val) {
                        setModalState(() {
                          selectedOrganismType = val;
                        });
                      },
                    ),

                    const SizedBox(height: 16),

                    /// Common Name
                    TextField(
                      controller: commonNameController,
                      decoration: const InputDecoration(
                        labelText: "Common Name",
                        prefixIcon: Icon(Icons.label),
                      ),
                    ),

                    const SizedBox(height: 16),

                    /// Species Name
                    TextField(
                      controller: speciesNameController,
                      readOnly: selectedOrganismType == 'Mammal',
                      decoration: InputDecoration(
                        labelText: "Species Name",
                        prefixIcon: const Icon(Icons.pets),
                        suffixIcon: selectedOrganismType == 'Mammal'
                            ? const Tooltip(message: "Auto-classified", child: Icon(Icons.lock))
                            : null,
                      ),
                    ),

                    const SizedBox(height: 20),

                    /// Select Image
                    ElevatedButton.icon(
                      icon: const Icon(Icons.image),
                      label: const Text("Select Image"),
                      onPressed: () async {
                        await pickImage();
                        setModalState(() {});
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),

                    /// Image Preview
                    if (selectedImage != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12.0),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(
                            selectedImage!,
                            height: 250,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),

                    /// Location Info
                    if (latitude != null && longitude != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Text(
                          "📍 $latitude, $longitude",
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 16,
                          ),
                        ),
                      ),

                    const SizedBox(height: 20),

                    /// Upload Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.upload),
                        label: const Text("Upload Observation"),
                        onPressed: isUploading ? null : uploadObservation,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }




  Widget buildObservationTab(String type) {
    return StreamBuilder<QuerySnapshot>(
      stream: firestore.getObservationsByType(type, _searchController.text),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

        final data = snapshot.data!.docs;
        if (data.isEmpty) {
          return const Center(child: Text("No observations found."));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: data.length,
          itemBuilder: (context, index) {
            final obs = data[index];
            final latitude = obs['Latitude'] as double?;
            final longitude = obs['Longitude'] as double?;
            final imageUrl = obs['ImageURL'];

            final timestamp = obs['Timestamp'] as Timestamp?;
            String formattedTime = 'Unknown time';

            if (timestamp != null) {
              final uploadDate = timestamp.toDate();
              final now = DateTime.now();
              final difference = now.difference(uploadDate);

              if (difference.inHours > 23) {
                formattedTime = DateFormat('d MMMM yyyy').format(uploadDate); // e.g., 15 April 2025
              } else {
                formattedTime = timeago.format(uploadDate);
              }
            }

            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "${obs['CommonName']} (${obs['SpeciesName']})",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: CachedNetworkImage(
                            imageUrl: imageUrl,
                            maxHeightDiskCache: 200,  // Cache smaller version
                            maxWidthDiskCache: 200,
                            height: 170,
                            width: 170,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                            errorWidget: (context, url, error) => const Icon(Icons.error),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("${obs['OrganismType']}"),
                              Text("${obs['UserEmail']}"),
                              Row(
                                children: [
                                  Icon(Icons.location_on, size: 16.0, color: Colors.red[700]),
                                  SizedBox(width: 4.0),
                                  Flexible(
                                    child: Text(
                                      (latitude != null && longitude != null)
                                          ? "${latitude.toStringAsFixed(4)}, ${longitude.toStringAsFixed(4)}"
                                          : "Location: Not available",
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              Text("$formattedTime"),
                              const SizedBox(height: 30),
                              if (latitude != null && longitude != null)
                                TextButton.icon(
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    foregroundColor: Theme.of(context).colorScheme.inversePrimary, // text and icon color
                                    backgroundColor: Theme.of(context).colorScheme.primary, // subtle background
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  icon: const Icon(
                                      color: Colors.red,
                                      Icons.location_on
                                  ),
                                  label: const Text(
                                    "Open in Maps",
                                    style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 14,
                                    ),
                                  ),
                                  onPressed: () {
                                    // TODO: Replace with your custom action
                                    _openInGoogleMaps(latitude, longitude);
                                  },
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }




  Future<void> _showSearchDialog() async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Search by Species"),
          content: TextField(
            controller: _searchController,
            decoration: const InputDecoration(hintText: 'Enter species name'),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  // Trigger a rebuild after updating the search
                });
                Navigator.of(context).pop();
              },
              child: const Text('Search'),
            ),
          ],
        );
      },
    );
  }


  Future<void> _loadImage(String imageUrl) async {
    try {
      await FirebaseStorage.instance.refFromURL(imageUrl).getDownloadURL();
    } catch (e) {
      throw Exception("Failed to load image: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const MyDrawer(),
      appBar: AppBar(
        title: const Text("Observations"),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () async {
              await _showSearchDialog(); // Show a dialog to enter search query
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Mammals'),
            Tab(text: 'Plants'),
          ],
        ),
      ),

      body: TabBarView(
        controller: _tabController,
        children: [
          buildObservationTab('Mammal'),
          buildObservationTab('Plant'),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: showUploadForm,
        child: const Icon(Icons.add),
      ),
    );
  }
}

 */

/*

import 'package:cached_network_image/cached_network_image.dart';
import 'package:exif/exif.dart' as exifdart;
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:exif/exif.dart';
import 'package:cubaankedua/components/my_drawer.dart';
import 'package:cubaankedua/services/firestore.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:cubaankedua/classifier.dart';
import 'package:url_launcher/url_launcher.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> with TickerProviderStateMixin {
  final FirestoreService firestore = FirestoreService();
  final picker = ImagePicker();
  File? selectedImage;
  double? latitude;
  double? longitude;

  String? selectedOrganismType;
  final TextEditingController commonNameController = TextEditingController();
  final TextEditingController speciesNameController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  bool isUploading = false;

  late TabController _tabController;

  // ADD: classifier instance and classification result
  final Classifier _classifier = Classifier();
  String _classificationResult = "";

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);


    // INIT: Load ML model
    _classifier.loadModel();
  }

  @override
  void dispose() {
    _classifier.dispose(); // ADD
    _tabController.dispose();
    commonNameController.dispose();
    speciesNameController.dispose();
    super.dispose();
  }

  void showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }
  Future<void> pickImage() async {
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    final bytes = await picked.readAsBytes();
    final tags = await readExifFromBytes(bytes);

    print("EXIF Tags: $tags"); // Debug print to check if EXIF is being read

    if (tags.containsKey('GPS GPSLatitude') &&
        tags.containsKey('GPS GPSLatitudeRef') &&
        tags.containsKey('GPS GPSLongitude') &&
        tags.containsKey('GPS GPSLongitudeRef')) {

      final latValues = _extractDMS(tags['GPS GPSLatitude']);
      final lonValues = _extractDMS(tags['GPS GPSLongitude']);
      final latRef = tags['GPS GPSLatitudeRef']!.printable;
      final lonRef = tags['GPS GPSLongitudeRef']!.printable;

      double lat = _convertToDecimal(latValues, latRef);
      double lon = _convertToDecimal(lonValues, lonRef);

      // If GPS is valid, update the state
      if (lat < -90 || lat > 90 || lon < -180 || lon > 180) {
        showErrorDialog("Invalid Location", "⚠️ Extracted coordinates are out of valid range.");
        return;
      }

      setState(() {
        selectedImage = File(picked.path);
        latitude = lat;
        longitude = lon;
      });

     // showErrorDialog("Location Found", "📍 Location: $lat, $lon");

      // ADD: Only classify if Mammal is selected
      if (selectedOrganismType == 'Mammal') {
        final result = await _classifier.classifyImage(File(picked.path));
        setState(() {
          _classificationResult = result;
          speciesNameController.text = result;
        });

        //showErrorDialog("Species Identified", "🧠 Predicted Species: $result");
      }

    } else {
      showErrorDialog("Missing Location Info", "This image does not contain GPS location metadata.");
    }
  }

  Future<void> checkExif(String imagePath) async {
    final bytes = await File(imagePath).readAsBytes();
    final data = await exifdart.readExifFromBytes(bytes);

    print("GPSLatitude: ${data['GPS GPSLatitude']}");
    print("GPSLongitude: ${data['GPS GPSLongitude']}");
  }

// Replace the existing _extractDMS function with this one:
  List<double> _extractDMS(IfdTag? tag) {
    if (tag == null || tag.values.length != 3) {
      throw const FormatException("Invalid GPS DMS tag.");
    }

    final dmsList = <double>[];
    for (var value in tag.values.toList()) {
      final valueStr = value.toString();
      if (valueStr.contains('/')) {
        final parts = valueStr.split('/');
        final numerator = double.tryParse(parts[0]) ?? 0;
        final denominator = double.tryParse(parts[1]) ?? 1;
        dmsList.add(numerator / denominator);
      } else {
        dmsList.add(double.tryParse(valueStr) ?? 0);
      }
    }
    return dmsList;
  }

// And this is your decimal conversion helper (keep as-is or use if needed):
  double _convertDMSToDecimal(double degrees, double minutes, double seconds) {
    return degrees + (minutes / 60.0) + (seconds / 3600.0);
  }

// Convert the DMS values to Decimal Degrees (DD)
  double _convertToDecimal(List<double> dms, String ref) {
    double decimal = dms[0] + (dms[1] / 60.0) + (dms[2] / 3600.0);
    if (ref == 'S' || ref == 'W') decimal *= -1;  // Negate for South and West
    return decimal;
  }


  Future<void> uploadObservation() async {
    if (selectedImage == null ||
        selectedOrganismType == null ||
        commonNameController.text.isEmpty ||
        speciesNameController.text.isEmpty ||
        latitude == null || longitude == null) {
      showErrorDialog("Incomplete Fields", "⚠️ Please complete all fields and select an image with GPS metadata.");
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          content: Row(
            children: const [
              CircularProgressIndicator(),
              SizedBox(width: 20),
              Text("Uploading...", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
        );
      },
    );

    setState(() => isUploading = true);
    try {
      final fileName = DateTime.now().millisecondsSinceEpoch.toString();
      final ref = FirebaseStorage.instance.ref().child('uploads/$fileName.jpg');
      final uploadTask = ref.putFile(selectedImage!);
      final snapshot = await uploadTask.whenComplete(() => null);
      final imageUrl = await snapshot.ref.getDownloadURL();

      await firestore.addObservation(
        organismType: selectedOrganismType!,
        commonName: commonNameController.text.trim(),
        speciesName: speciesNameController.text.trim(),
        latitude: latitude!,
        longitude: longitude!,
        imageUrl: imageUrl,
      );

      if (mounted) {
        resetForm();
        Navigator.pop(context);
        Navigator.pop(context);
      }
    } catch (e) {
      Navigator.pop(context);
      showErrorDialog("Upload Failed", "❌ Upload failed. Please try again.\n\nDetails: $e");
    }

    setState(() => isUploading = false);
  }

  void resetForm() {
    setState(() {
      selectedOrganismType = null;
      commonNameController.clear();
      speciesNameController.clear();
      selectedImage = null;
      latitude = null;
      longitude = null;
      _classificationResult = "";
    });
  }

  void _openInGoogleMaps(double lat, double lon) async {
    final url = Uri.parse("https://www.google.com/maps/search/?api=1&query=$lat,$lon");

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      showErrorDialog("Error", "❌ Could not open Google Maps.");
    }
  }


  void showUploadForm() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Theme.of(context).dialogBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.85,
            minChildSize: 0.5,
            maxChildSize: 0.95,
            builder: (_, scrollController) => SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: StatefulBuilder(
                builder: (context, setModalState) => Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    /// Title and Close Button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "New Observation",
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (dialogContext) => AlertDialog(
                                title: const Text("Discard Observation?"),
                                content: const Text("Are you sure you want to discard this observation?"),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(dialogContext),
                                    child: const Text("No"),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      resetForm();
                                      Navigator.pop(dialogContext);
                                      Navigator.pop(context);
                                    },
                                    child: const Text("Yes"),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    /// Dropdown for Organism
                    DropdownButtonFormField<String>(
                      value: selectedOrganismType,
                      decoration: const InputDecoration(
                        labelText: "Organism Type",
                        prefixIcon: Icon(Icons.category),
                      ),
                      items: ['Mammal', 'Plant']
                          .map((type) => DropdownMenuItem(value: type, child: Text(type)))
                          .toList(),
                      onChanged: (val) {
                        setModalState(() {
                          selectedOrganismType = val;
                        });
                      },
                    ),

                    const SizedBox(height: 16),

                    /// Common Name
                    TextField(
                      controller: commonNameController,
                      decoration: const InputDecoration(
                        labelText: "Common Name",
                        prefixIcon: Icon(Icons.label),
                      ),
                    ),

                    const SizedBox(height: 16),

                    /// Species Name
                    TextField(
                      controller: speciesNameController,
                      readOnly: selectedOrganismType == 'Mammal',
                      decoration: InputDecoration(
                        labelText: "Species Name",
                        prefixIcon: const Icon(Icons.pets),
                        suffixIcon: selectedOrganismType == 'Mammal'
                            ? const Tooltip(message: "Auto-classified", child: Icon(Icons.lock))
                            : null,
                      ),
                    ),

                    const SizedBox(height: 20),

                    /// Select Image
                    ElevatedButton.icon(
                      icon: const Icon(Icons.image),
                      label: const Text("Select Image"),
                      onPressed: () async {
                        await pickImage();
                        setModalState(() {});
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),

                    /// Image Preview
                    if (selectedImage != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12.0),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(
                            selectedImage!,
                            height: 250,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),

                    /// Location Info
                    if (latitude != null && longitude != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Text(
                          "📍 $latitude, $longitude",
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 16,
                          ),
                        ),
                      ),

                    const SizedBox(height: 20),

                    /// Upload Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.upload),
                        label: const Text("Upload Observation"),
                        onPressed: isUploading ? null : uploadObservation,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }




  Widget buildObservationTab(String type) {
    return Column(
      children: [
        // Inline search bar
        Padding(
          //Search bar padding
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: TextField(
            controller: _searchController,
            onChanged: (_) => setState(() {}), // Triggers search instantly
            decoration: InputDecoration(
              hintText: 'Search by species name...',
              prefixIcon: Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                icon: Icon(Icons.clear),
                onPressed: () {
                  _searchController.clear();
                  setState(() {}); // Refresh list
                },
              )
                  : null,
              filled: true,
              fillColor: Theme.of(context).colorScheme.surfaceVariant,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),

        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: firestore.getObservationsByType(type, _searchController.text),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final data = snapshot.data!.docs;
              if (data.isEmpty) {
                return const Center(child: Text("No observations found."));
              }

              return RefreshIndicator(
                onRefresh: () async {
                  setState(() {}); // For visual refresh
                },
                child: ListView.builder(
                  //padding: const EdgeInsets.all(16),
                  padding: const EdgeInsets.fromLTRB(16,4, 16, 16), // top padding reduced from 16 → 4
                  itemCount: data.length,
                  itemBuilder: (context, index) {
                    final obs = data[index];
                    final latitude = obs['Latitude'] as double?;
                    final longitude = obs['Longitude'] as double?;
                    final imageUrl = obs['ImageURL'];
                    final timestamp = obs['Timestamp'] as Timestamp?;
                    String formattedTime = 'Unknown time';

                    if (timestamp != null) {
                      final uploadDate = timestamp.toDate();
                      final now = DateTime.now();
                      final difference = now.difference(uploadDate);
                      formattedTime = difference.inHours > 23
                          ? DateFormat('d MMMM yyyy').format(uploadDate)
                          : timeago.format(uploadDate);
                    }

                    return Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      color: Theme.of(context).colorScheme.surface,
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "${obs['CommonName']} (${obs['SpeciesName']})",
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: CachedNetworkImage(
                                    imageUrl: imageUrl,
                                    maxHeightDiskCache: 200,
                                    maxWidthDiskCache: 200,
                                    height: 170,
                                    width: 170,
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) =>
                                    const Center(child: CircularProgressIndicator()),
                                    errorWidget: (context, url, error) =>
                                    const Icon(Icons.error),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(obs['OrganismType'] ?? '',
                                          style: Theme.of(context).textTheme.bodyMedium),
                                      const SizedBox(height: 4),
                                      Text(obs['UserEmail'] ?? '',
                                          style: Theme.of(context).textTheme.bodySmall),
                                      const SizedBox(height: 6),
                                      Row(
                                        crossAxisAlignment: CrossAxisAlignment.center,
                                        children: [
                                          Icon(Icons.location_on,
                                              size: 16,
                                              color: Theme.of(context).colorScheme.primary),
                                          const SizedBox(width: 4),
                                          Flexible(
                                            child: Text(
                                              (latitude != null && longitude != null)
                                                  ? "${latitude.toStringAsFixed(4)}, ${longitude.toStringAsFixed(4)}"
                                                  : "Location: Not available",
                                              style: Theme.of(context).textTheme.bodySmall,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        formattedTime,
                                        style: Theme.of(context).textTheme.bodySmall,
                                      ),
                                      const SizedBox(height: 16),
                                      if (latitude != null && longitude != null)
                                        TextButton.icon(
                                          style: TextButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 12, vertical: 8),
                                            foregroundColor:
                                            Theme.of(context).colorScheme.onPrimary,
                                            backgroundColor:
                                            Theme.of(context).colorScheme.primary,
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                          ),
                                          icon: const Icon(Icons.map, color: Colors.white),
                                          label: const Text(
                                            "Open in Maps",
                                            style: TextStyle(
                                              fontWeight: FontWeight.w500,
                                              fontSize: 14,
                                              color: Colors.white,
                                            ),
                                          ),
                                          onPressed: () {
                                            _openInGoogleMaps(latitude, longitude);
                                          },
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }





  Future<void> _showSearchDialog() async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Search by Species"),
          content: TextField(
            controller: _searchController,
            decoration: const InputDecoration(hintText: 'Enter species name'),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  // Trigger a rebuild after updating the search
                });
                Navigator.of(context).pop();
              },
              child: const Text('Search'),
            ),
          ],
        );
      },
    );
  }


  Future<void> _loadImage(String imageUrl) async {
    try {
      await FirebaseStorage.instance.refFromURL(imageUrl).getDownloadURL();
    } catch (e) {
      throw Exception("Failed to load image: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const MyDrawer(),
      appBar: AppBar(
        title: const Text("Observations"),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () async {
              await _showSearchDialog(); // Show a dialog to enter search query
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Mammals'),
            Tab(text: 'Plants'),
          ],
        ),
      ),

      body: TabBarView(
        controller: _tabController,
        children: [
          buildObservationTab('Mammal'),
          buildObservationTab('Plant'),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: showUploadForm,
        child: const Icon(Icons.add),
      ),
    );
  }
}

 */

/*

import 'package:cached_network_image/cached_network_image.dart';
import 'package:exif/exif.dart' as exifdart;
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:geocoding/geocoding.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:exif/exif.dart';
import 'package:cubaankedua/components/my_drawer.dart';
import 'package:cubaankedua/services/firestore.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:cubaankedua/classifier.dart';
import 'package:url_launcher/url_launcher.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> with TickerProviderStateMixin {
  final FirestoreService firestore = FirestoreService();
  final picker = ImagePicker();
  File? selectedImage;
  double? latitude;
  double? longitude;

  String? selectedOrganismType;
  final TextEditingController commonNameController = TextEditingController();
  final TextEditingController speciesNameController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  bool _isSearchCollapsed = false;
  final ScrollController _scrollController = ScrollController();


  bool isUploading = false;

  late TabController _tabController;

  // ADD: classifier instance and classification result
  final Classifier _classifier = Classifier();
  String _classificationResult = "";

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _scrollController.addListener(_handleScroll);

    // INIT: Load ML model
    _classifier.loadModel();
  }

  @override
  void dispose() {
    _classifier.dispose(); // ADD
    _tabController.dispose();
    commonNameController.dispose();
    speciesNameController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _handleScroll() {
    final direction = _scrollController.position.userScrollDirection;
    if (direction == ScrollDirection.reverse && !_isSearchCollapsed) {
      setState(() => _isSearchCollapsed = true);
    } else if (direction == ScrollDirection.forward && _isSearchCollapsed) {
      setState(() => _isSearchCollapsed = false);
    }
  }



  void showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }
  Future<void> pickImage() async {
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    final bytes = await picked.readAsBytes();
    final tags = await readExifFromBytes(bytes);

    print("EXIF Tags: $tags"); // Debug print to check if EXIF is being read

    if (tags.containsKey('GPS GPSLatitude') &&
        tags.containsKey('GPS GPSLatitudeRef') &&
        tags.containsKey('GPS GPSLongitude') &&
        tags.containsKey('GPS GPSLongitudeRef')) {

      final latValues = _extractDMS(tags['GPS GPSLatitude']);
      final lonValues = _extractDMS(tags['GPS GPSLongitude']);
      final latRef = tags['GPS GPSLatitudeRef']!.printable;
      final lonRef = tags['GPS GPSLongitudeRef']!.printable;

      double lat = _convertToDecimal(latValues, latRef);
      double lon = _convertToDecimal(lonValues, lonRef);

      // If GPS is valid, update the state
      if (lat < -90 || lat > 90 || lon < -180 || lon > 180) {
        showErrorDialog("Invalid Location", "⚠️ Extracted coordinates are out of valid range.");
        return;
      }

      setState(() {
        selectedImage = File(picked.path);
        latitude = lat;
        longitude = lon;
      });

     // showErrorDialog("Location Found", "📍 Location: $lat, $lon");

      // ADD: Only classify if Mammal is selected
      if (selectedOrganismType == 'Mammal') {
        final result = await _classifier.classifyImage(File(picked.path));
        setState(() {
          _classificationResult = result;
          speciesNameController.text = result;
        });

        //showErrorDialog("Species Identified", "🧠 Predicted Species: $result");
      }

    } else {
      showErrorDialog("Missing Location Info", "This image does not contain GPS location metadata.");
    }
  }

  Future<void> checkExif(String imagePath) async {
    final bytes = await File(imagePath).readAsBytes();
    final data = await exifdart.readExifFromBytes(bytes);

    print("GPSLatitude: ${data['GPS GPSLatitude']}");
    print("GPSLongitude: ${data['GPS GPSLongitude']}");
  }

// Replace the existing _extractDMS function with this one:
  List<double> _extractDMS(IfdTag? tag) {
    if (tag == null || tag.values.length != 3) {
      throw const FormatException("Invalid GPS DMS tag.");
    }

    final dmsList = <double>[];
    for (var value in tag.values.toList()) {
      final valueStr = value.toString();
      if (valueStr.contains('/')) {
        final parts = valueStr.split('/');
        final numerator = double.tryParse(parts[0]) ?? 0;
        final denominator = double.tryParse(parts[1]) ?? 1;
        dmsList.add(numerator / denominator);
      } else {
        dmsList.add(double.tryParse(valueStr) ?? 0);
      }
    }
    return dmsList;
  }

// And this is your decimal conversion helper (keep as-is or use if needed):
  double _convertDMSToDecimal(double degrees, double minutes, double seconds) {
    return degrees + (minutes / 60.0) + (seconds / 3600.0);
  }

// Convert the DMS values to Decimal Degrees (DD)
  double _convertToDecimal(List<double> dms, String ref) {
    double decimal = dms[0] + (dms[1] / 60.0) + (dms[2] / 3600.0);
    if (ref == 'S' || ref == 'W') decimal *= -1;  // Negate for South and West
    return decimal;
  }


  Future<void> uploadObservation() async {
    if (selectedImage == null ||
        selectedOrganismType == null ||
        commonNameController.text.isEmpty ||
        speciesNameController.text.isEmpty ||
        latitude == null || longitude == null) {
      showErrorDialog("Incomplete Fields", "⚠️ Please complete all fields and select an image with GPS metadata.");
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          content: Row(
            children: const [
              CircularProgressIndicator(),
              SizedBox(width: 20),
              Text("Uploading...", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
        );
      },
    );

    setState(() => isUploading = true);
    try {
      final fileName = DateTime.now().millisecondsSinceEpoch.toString();
      final ref = FirebaseStorage.instance.ref().child('uploads/$fileName.jpg');
      final uploadTask = ref.putFile(selectedImage!);
      final snapshot = await uploadTask.whenComplete(() => null);
      final imageUrl = await snapshot.ref.getDownloadURL();

      await firestore.addObservation(
        organismType: selectedOrganismType!,
        commonName: commonNameController.text.trim(),
        speciesName: speciesNameController.text.trim(),
        latitude: latitude!,
        longitude: longitude!,
        imageUrl: imageUrl,
      );

      if (mounted) {
        resetForm();
        Navigator.pop(context);
        Navigator.pop(context);
      }
    } catch (e) {
      Navigator.pop(context);
      showErrorDialog("Upload Failed", "❌ Upload failed. Please try again.\n\nDetails: $e");
    }

    setState(() => isUploading = false);
  }

  void resetForm() {
    setState(() {
      selectedOrganismType = null;
      commonNameController.clear();
      speciesNameController.clear();
      selectedImage = null;
      latitude = null;
      longitude = null;
      _classificationResult = "";
    });
  }

  void _openInGoogleMaps(double lat, double lon) async {
    final url = Uri.parse("https://www.google.com/maps/search/?api=1&query=$lat,$lon");

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      showErrorDialog("Error", "❌ Could not open Google Maps.");
    }
  }


  void showUploadForm() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Theme.of(context).dialogBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.85,
            minChildSize: 0.5,
            maxChildSize: 0.95,
            builder: (_, scrollController) => SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: StatefulBuilder(
                builder: (context, setModalState) => Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    /// Title and Close Button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "New Observation",
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (dialogContext) => AlertDialog(
                                title: const Text("Discard Observation?"),
                                content: const Text("Are you sure you want to discard this observation?"),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(dialogContext),
                                    child: const Text("No"),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      resetForm();
                                      Navigator.pop(dialogContext);
                                      Navigator.pop(context);
                                    },
                                    child: const Text("Yes"),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    /// Dropdown for Organism
                    DropdownButtonFormField<String>(
                      value: selectedOrganismType,
                      decoration: const InputDecoration(
                        labelText: "Organism Type",
                        prefixIcon: Icon(Icons.category),
                      ),
                      items: ['Mammal', 'Plant']
                          .map((type) => DropdownMenuItem(value: type, child: Text(type)))
                          .toList(),
                      onChanged: (val) {
                        setModalState(() {
                          selectedOrganismType = val;
                        });
                      },
                    ),

                    const SizedBox(height: 16),

                    /// Common Name
                    TextField(
                      controller: commonNameController,
                      decoration: const InputDecoration(
                        labelText: "Common Name",
                        prefixIcon: Icon(Icons.label),
                      ),
                    ),

                    const SizedBox(height: 16),

                    /// Species Name
                    TextField(
                      controller: speciesNameController,
                      readOnly: selectedOrganismType == 'Mammal',
                      decoration: InputDecoration(
                        labelText: "Species Name",
                        prefixIcon: const Icon(Icons.pets),
                        suffixIcon: selectedOrganismType == 'Mammal'
                            ? const Tooltip(message: "Auto-classified", child: Icon(Icons.lock))
                            : null,
                      ),
                    ),

                    const SizedBox(height: 20),

                    /// Select Image
                    ElevatedButton.icon(
                      icon: const Icon(Icons.image),
                      label: const Text("Select Image"),
                      onPressed: () async {
                        await pickImage();
                        setModalState(() {});
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),

                    /// Image Preview
                    if (selectedImage != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12.0),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(
                            selectedImage!,
                            height: 250,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),

                    /// Location Info
                    if (latitude != null && longitude != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Text(
                          "📍 $latitude, $longitude",
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 16,
                          ),
                        ),
                      ),

                    const SizedBox(height: 20),

                    /// Upload Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.upload),
                        label: const Text("Upload Observation"),
                        onPressed: isUploading ? null : uploadObservation,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }




  Widget buildObservationTab(String type) {
    return Column(
      children: [
        // Inline search bar
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          height: _isSearchCollapsed ? 0 : 55, // Adjust height as needed
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _isSearchCollapsed
              ? null
              : TextField(
            controller: _searchController,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'Search by species name...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  _searchController.clear();
                  setState(() {});
                },
              )
                  : null,
              filled: true,
              fillColor: Theme.of(context).colorScheme.surfaceVariant,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),



        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: firestore.getObservationsByType(type, _searchController.text),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final data = snapshot.data!.docs;
              if (data.isEmpty) {
                return const Center(child: Text("No observations found."));
              }

              return RefreshIndicator(
                onRefresh: () async {
                  setState(() {}); // For visual refresh
                },
                child: ListView.builder(
                  controller: _scrollController,
                  //padding: const EdgeInsets.all(16),
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 16), // top padding reduced from 16 → 4
                  itemCount: data.length,
                  itemBuilder: (context, index) {
                    final obs = data[index];
                    final latitude = obs['Latitude'] as double?;
                    final longitude = obs['Longitude'] as double?;
                    final imageUrl = obs['ImageURL'];
                    final timestamp = obs['Timestamp'] as Timestamp?;
                    String formattedTime = 'Unknown time';

                    if (timestamp != null) {
                      final uploadDate = timestamp.toDate();
                      final now = DateTime.now();
                      final difference = now.difference(uploadDate);
                      formattedTime = difference.inHours > 23
                          ? DateFormat('d MMMM yyyy').format(uploadDate)
                          : timeago.format(uploadDate);
                    }

                    return Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      color: Theme.of(context).colorScheme.surface,
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "${obs['CommonName']} (${obs['SpeciesName']})",
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: CachedNetworkImage(
                                    imageUrl: imageUrl,
                                    maxHeightDiskCache: 200,
                                    maxWidthDiskCache: 200,
                                    height: 170,
                                    width: 170,
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) =>
                                    const Center(child: CircularProgressIndicator()),
                                    errorWidget: (context, url, error) =>
                                    const Icon(Icons.error),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(obs['OrganismType'] ?? '',
                                          style: Theme.of(context).textTheme.bodyMedium),
                                      const SizedBox(height: 4),
                                      Text(obs['UserEmail'] ?? '',
                                          style: Theme.of(context).textTheme.bodySmall),
                                      const SizedBox(height: 6),
                                      Row(
                                        crossAxisAlignment: CrossAxisAlignment.center,
                                        children: [
                                          Icon(Icons.location_on,
                                              size: 16,
                                              color: Theme.of(context).colorScheme.primary),
                                          const SizedBox(width: 4),
                                          Flexible(
                                            child: Text(
                                              (latitude != null && longitude != null)
                                                  ? "${latitude.toStringAsFixed(4)}, ${longitude.toStringAsFixed(4)}"
                                                  : "Location: Not available",
                                              style: Theme.of(context).textTheme.bodySmall,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        formattedTime,
                                        style: Theme.of(context).textTheme.bodySmall,
                                      ),
                                      const SizedBox(height: 16),
                                      if (latitude != null && longitude != null)
                                        TextButton.icon(
                                          style: TextButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 12, vertical: 8),
                                            foregroundColor:
                                            Theme.of(context).colorScheme.onPrimary,
                                            backgroundColor:
                                            Theme.of(context).colorScheme.primary,
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                          ),
                                          icon: const Icon(Icons.map, color: Colors.white),
                                          label: const Text(
                                            "Open in Maps",
                                            style: TextStyle(
                                              fontWeight: FontWeight.w500,
                                              fontSize: 14,
                                              color: Colors.white,
                                            ),
                                          ),
                                          onPressed: () {
                                            _openInGoogleMaps(latitude, longitude);
                                          },
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _showSearchDialog() async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Search by Species"),
          content: TextField(
            controller: _searchController,
            decoration: const InputDecoration(hintText: 'Enter species name'),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  // Trigger a rebuild after updating the search
                });
                Navigator.of(context).pop();
              },
              child: const Text('Search'),
            ),
          ],
        );
      },
    );
  }


  Future<void> _loadImage(String imageUrl) async {
    try {
      await FirebaseStorage.instance.refFromURL(imageUrl).getDownloadURL();
    } catch (e) {
      throw Exception("Failed to load image: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const MyDrawer(),
      appBar: AppBar(
        title: const Text("Observations"),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () async {
              await _showSearchDialog(); // Show a dialog to enter search query
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Mammals'),
            Tab(text: 'Plants'),
          ],
        ),
      ),

      body: TabBarView(
        controller: _tabController,
        children: [
          buildObservationTab('Mammal'),
          buildObservationTab('Plant'),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: showUploadForm,
        child: const Icon(Icons.add),
      ),
    );
  }
}
 */