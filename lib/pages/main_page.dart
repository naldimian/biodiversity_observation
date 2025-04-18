/*
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cubaankedua/components/my_drawer.dart';
import 'package:cubaankedua/components/my_list_tile.dart';
import 'package:cubaankedua/components/my_post_button.dart';
import 'package:cubaankedua/components/my_textfield.dart';
import 'package:cubaankedua/services/firestore.dart';
import 'package:flutter/material.dart';

class MainPage extends StatelessWidget {
  MainPage({super.key});

  // firestore access
  final FirestoreService database = FirestoreService();

  //TEXT CONTROLLER
  final TextEditingController newPostController = TextEditingController();

  // post message
  void postMessage(){
    if(newPostController.text.isNotEmpty){
      String message = newPostController.text;
      database.addPost(message);
    }

    // clear the controller
    newPostController.clear();
  }





  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: Text(
          "H O M E",
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        foregroundColor: Theme.of(context).colorScheme.inversePrimary,
        elevation: 0,

      ),
      drawer: const MyDrawer(),
      body: Column(
        children: [

          //TEXTFIELD BOX FOR USER TO TYPE
          Padding(
            padding: const EdgeInsets.all(25.0),
            child: Row(
              children: [
                //text field
                Expanded(
                  child: MyTextfield(
                      hintText: "Upload something..",
                      obscureText: false,
                      controller: newPostController,
                  ),
                ),
                
                // post button
                PostButton(
                  onTap: postMessage,
                )
              ],
            ),
          ),

          //OBSERVATIONS
          StreamBuilder(
              stream: database.getPostsStream(),
              builder: (context, snapshot) {
                // show loading circle
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(),
                  );
                }

                // get all posts
                  final posts = snapshot.data!.docs;

                // no data?
                if (snapshot.data == null || posts.isEmpty) {
                  return const Center(
                    child: Padding(
                        padding: EdgeInsets.all(25),
                        child: Text("No posts.. Upload something"),

                    ),
                  );
                }

                // return as a list
                return Expanded(
                    child: ListView.builder(
                      itemCount: posts.length,
                        itemBuilder: (context, index){
                        // get each individual post
                          final post = posts[index];

                          // get data from each post
                          String message = post['PostMessage'];
                          String userEmail = post['UserEmail'];
                          Timestamp timestamp = post['Timestamp'];
                          
                          //return as list tile
                          return MyListTile(title: message, subTitle: userEmail);
                        },
                    )
                );

                // return as a list
              },
          )
        ],
      ),


    );
  }
}
*/

/*
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:exif/exif.dart';
import 'package:cubaankedua/components/my_drawer.dart';
import 'package:cubaankedua/services/firestore.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  final FirestoreService firestore = FirestoreService();
  final picker = ImagePicker();
  File? selectedImage;
  double? latitude;
  double? longitude;

  String? selectedOrganismType;
  final TextEditingController commonNameController = TextEditingController();
  final TextEditingController speciesNameController = TextEditingController();
  bool isUploading = false;

  // Pick image and read EXIF location
  Future<void> pickImage() async {
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    final bytes = await picked.readAsBytes();
    final tags = await readExifFromBytes(bytes);

    print("EXIF GPSLatitude: ${tags['GPS GPSLatitude']?.values}");
    print("EXIF GPSLongitude: ${tags['GPS GPSLongitude']?.values}");


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

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('📍 Location found: $lat, $lon')),
        );
      } else {
        setState(() {
          selectedImage = null;
          latitude = null;
          longitude = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('❌ This image does not contain location info!')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error reading image metadata: $e')),
      );
    }
  }

  // Extract DMS values from IfdRatios
  List<double> _extractDMS(IfdTag? tag) {
    if (tag == null) {
      throw const FormatException("GPS tag is null.");
    }

    try {
      final raw = tag.printable; // e.g. "35/1, 12/1, 55/1"
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

  // Convert DMS to decimal
  double _convertToDecimal(List<double> dms, String ref) {
    double decimal = dms[0] + (dms[1] / 60.0) + (dms[2] / 3600.0);
    if (ref == 'S' || ref == 'W') decimal *= -1;
    return decimal;
  }

  // Upload observation
  Future<void> uploadObservation() async {
    if (selectedImage == null ||
        selectedOrganismType == null ||
        commonNameController.text.isEmpty ||
        speciesNameController.text.isEmpty ||
        latitude == null ||
        longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⚠️ Complete all fields')),
      );
      return;
    }

    setState(() => isUploading = true);

    try {
      final fileName = DateTime.now().millisecondsSinceEpoch.toString();
      final ref = FirebaseStorage.instance.ref().child('uploads/$fileName.jpg');
      await ref.putFile(selectedImage!);
      final imageUrl = await ref.getDownloadURL();

      await firestore.addObservation(
        organismType: selectedOrganismType!,
        commonName: commonNameController.text.trim(),
        speciesName: speciesNameController.text.trim(),
        latitude: latitude!,
        longitude: longitude!,
        imageUrl: imageUrl,
      );

      Navigator.of(context).pop(); // close modal
      resetForm();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Upload failed: $e')),
      );
    }

    setState(() => isUploading = false);
  }

  void resetForm() {
    selectedOrganismType = null;
    commonNameController.clear();
    speciesNameController.clear();
    selectedImage = null;
    latitude = null;
    longitude = null;
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
                  child: Image.file(selectedImage!, height: 120),
                ),
              const SizedBox(height: 10),
              isUploading
                  ? const CircularProgressIndicator()
                  : ElevatedButton.icon(
                icon: const Icon(Icons.upload),
                label: const Text("Upload"),
                onPressed: uploadObservation,
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const MyDrawer(),
      appBar: AppBar(
        title: const Text("Observations"),
        centerTitle: true,
      ),
      body: StreamBuilder(
        stream: firestore.getObservationsStream(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final data = snapshot.data!.docs;
          if (data.isEmpty) {
            return const Center(child: Text("No observations uploaded yet."));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: data.length,
            itemBuilder: (context, index) {
              final obs = data[index];

              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(12),
                  title: Text("${obs['CommonName']} (${obs['SpeciesName']})"),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Type: ${obs['OrganismType']}"),
                      Text("Uploaded by: ${obs['UserEmail']}"),
                      Text("Location: ${obs['Latitude']}, ${obs['Longitude']}"),
                      const SizedBox(height: 10),
                      Image.network(obs['ImageURL'], height: 150, fit: BoxFit.cover),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: showUploadForm,
        child: const Icon(Icons.add),
      ),
    );
  }
}*/
/*
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:exif/exif.dart';
import 'package:cubaankedua/components/my_drawer.dart';
import 'package:cubaankedua/services/firestore.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  final FirestoreService firestore = FirestoreService();
  final picker = ImagePicker();
  File? selectedImage;
  double? latitude;  // Store latitude as a double
  double? longitude; // Store longitude as a double

  String? selectedOrganismType;
  final TextEditingController commonNameController = TextEditingController();
  final TextEditingController speciesNameController = TextEditingController();
  bool isUploading = false;

  // Pick image and read EXIF location
  Future<void> pickImage() async {
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    final bytes = await picked.readAsBytes();
    final tags = await readExifFromBytes(bytes);

    print("EXIF GPSLatitude: ${tags['GPS GPSLatitude']?.values}");
    print("EXIF GPSLongitude: ${tags['GPS GPSLongitude']?.values}");

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
          latitude = lat; // Store latitude as double
          longitude = lon; // Store longitude as double
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('📍 Location found: $lat, $lon')),
        );
      } else {
        setState(() {
          selectedImage = null;
          latitude = null;
          longitude = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('❌ This image does not contain location info!')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error reading image metadata: $e')),
      );
    }
  }

  // Extract DMS values from IfdRatios
  List<double> _extractDMS(IfdTag? tag) {
    if (tag == null) {
      throw const FormatException("GPS tag is null.");
    }

    try {
      final raw = tag.printable; // e.g. "35/1, 12/1, 55/1"
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

  // Convert DMS to decimal
  double _convertToDecimal(List<double> dms, String ref) {
    double decimal = dms[0] + (dms[1] / 60.0) + (dms[2] / 3600.0);
    if (ref == 'S' || ref == 'W') decimal *= -1;
    return decimal;
  }

  Future<String> uploadImage(File image) async {
    try {
      // Upload image logic to Firebase Storage
      // For example, uploading to Firebase Storage and getting the URL
      final ref = FirebaseStorage.instance.ref().child('images/${DateTime.now().toString()}.jpg');
      final uploadTask = ref.putFile(image);
      final snapshot = await uploadTask.whenComplete(() => null);
      final imageUrl = await snapshot.ref.getDownloadURL();
      return imageUrl;
    } catch (e) {
      print('Error uploading image: $e');
      rethrow;
    }
  }


  // Upload observation
  Future<void> uploadObservation() async {
    if (selectedImage == null ||
        selectedOrganismType == null ||
        commonNameController.text.isEmpty ||
        speciesNameController.text.isEmpty ||
        latitude == null || longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⚠️ Complete all fields')),
      );
      return;
    }

    setState(() => isUploading = true);
    try {
      final fileName = DateTime.now().millisecondsSinceEpoch.toString();
      final ref = FirebaseStorage.instance.ref().child('uploads/$fileName.jpg');
      await ref.putFile(selectedImage!);
      final imageUrl = await ref.getDownloadURL();

      // Add observation only after image upload is successful
      await firestore.addObservation(
        organismType: selectedOrganismType!,
        commonName: commonNameController.text.trim(),
        speciesName: speciesNameController.text.trim(),
        latitude: latitude!,
        longitude: longitude!,
        imageUrl: imageUrl,
      );

      // Trigger UI update
      if (mounted) setState(() {});
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Upload failed: $e')),
      );
    }

    setState(() => isUploading = false);
  }

  void resetForm() {
    selectedOrganismType = null;
    commonNameController.clear();
    speciesNameController.clear();
    selectedImage = null;
    latitude = null;  // Reset latitude
    longitude = null; // Reset longitude
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
                  child: Image.file(selectedImage!, height: 120),
                ),
              const SizedBox(height: 10),
              isUploading
                  ? const CircularProgressIndicator()
                  : ElevatedButton.icon(
                icon: const Icon(Icons.upload),
                label: const Text("Upload"),
                onPressed: uploadObservation,
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const MyDrawer(),
      appBar: AppBar(
        title: const Text("Observations"),
        centerTitle: true,
      ),
      body: StreamBuilder(
        stream: firestore.getObservationsStream(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final data = snapshot.data!.docs;
          if (data.isEmpty) {
            return const Center(child: Text("No observations uploaded yet."));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: data.length,
            itemBuilder: (context, index) {
              final obs = data[index];
              final latitude = obs['Latitude'] as double?;
              final longitude = obs['Longitude'] as double?;

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
                          // Left: Image
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              obs['ImageURL'],
                              height: 150,
                              width: 150,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(width: 12),

                          // Right: Texts aligned vertically
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
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: showUploadForm,
        child: const Icon(Icons.add),
      ),
    );
  }
}
*/ //pop up change
/*
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:exif/exif.dart';
import 'package:cubaankedua/components/my_drawer.dart';
import 'package:cubaankedua/services/firestore.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  final FirestoreService firestore = FirestoreService();
  final picker = ImagePicker();
  File? selectedImage;
  double? latitude;
  double? longitude;

  String? selectedOrganismType;
  final TextEditingController commonNameController = TextEditingController();
  final TextEditingController speciesNameController = TextEditingController();
  bool isUploading = false;

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

  Future<String> uploadImage(File image) async {
    try {
      final ref = FirebaseStorage.instance.ref().child('images/${DateTime.now().toString()}.jpg');
      final uploadTask = ref.putFile(image);
      final snapshot = await uploadTask.whenComplete(() => null);
      final imageUrl = await snapshot.ref.getDownloadURL();
      return imageUrl;
    } catch (e) {
      print('Error uploading image: $e');
      rethrow;
    }
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

    setState(() => isUploading = true);
    try {
      final fileName = DateTime.now().millisecondsSinceEpoch.toString();
      final ref = FirebaseStorage.instance.ref().child('uploads/$fileName.jpg');
      await ref.putFile(selectedImage!);
      final imageUrl = await ref.getDownloadURL();

      await firestore.addObservation(
        organismType: selectedOrganismType!,
        commonName: commonNameController.text.trim(),
        speciesName: speciesNameController.text.trim(),
        latitude: latitude!,
        longitude: longitude!,
        imageUrl: imageUrl,
      );

      if (mounted) setState(() {});
    } catch (e) {
      showErrorDialog("Upload Failed", "❌ Upload failed. Please try again.\n\nDetails: $e");
    }

    setState(() => isUploading = false);
  }

  void resetForm() {
    selectedOrganismType = null;
    commonNameController.clear();
    speciesNameController.clear();
    selectedImage = null;
    latitude = null;
    longitude = null;
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
                  child: Image.file(selectedImage!, height: 120),
                ),
              const SizedBox(height: 10),
              isUploading
                  ? const CircularProgressIndicator()
                  : ElevatedButton.icon(
                icon: const Icon(Icons.upload),
                label: const Text("Upload"),
                onPressed: uploadObservation,
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const MyDrawer(),
      appBar: AppBar(
        title: const Text("Observations"),
        centerTitle: true,
      ),
      body: StreamBuilder(
        stream: firestore.getObservationsStream(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final data = snapshot.data!.docs;
          if (data.isEmpty) {
            return const Center(child: Text("No observations uploaded yet."));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: data.length,
            itemBuilder: (context, index) {
              final obs = data[index];
              final latitude = obs['Latitude'] as double?;
              final longitude = obs['Longitude'] as double?;

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
                            child: Image.network(
                              obs['ImageURL'],
                              height: 150,
                              width: 150,
                              fit: BoxFit.cover,
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
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: showUploadForm,
        child: const Icon(Icons.add),
      ),
    );
  }
}*/

// flagship code
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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
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

    // Show loading popup
    showDialog(
      context: context,
      barrierDismissible: false, // Prevent dismissing the dialog by tapping outside
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12)
          ),
          content: Row(
            children: const [

              CircularProgressIndicator(),
              SizedBox(width: 20),
              Text(
                  "Uploading...",
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold
                  ),
              ),
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
        Navigator.pop(context); // Close the loading popup
        Navigator.pop(context); // Close the upload form
      }
    } catch (e) {
      Navigator.pop(context); // Close the loading popup
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
                  child: Image.file(selectedImage!, height: 120),
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
