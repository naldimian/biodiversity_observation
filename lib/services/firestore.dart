/*
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreService {
  final User? user = FirebaseAuth.instance.currentUser;
  final CollectionReference observations =
  FirebaseFirestore.instance.collection('observations');
  final CollectionReference users =
  FirebaseFirestore.instance.collection('Users');

  // Helper function to return observation data
  Map<String, dynamic> _getObservationData({
    required String organismType,
    required String commonName,
    required String speciesName,
    required double latitude,
    required double longitude,
    required String imageUrl,
  }) {
    return {
      'UserEmail': user?.email ?? 'Unknown',
      'OrganismType': organismType,
      'CommonName': commonName,
      'SpeciesName': speciesName,
      'Latitude': latitude,
      'Longitude': longitude,
      'ImageURL': imageUrl,
      'Timestamp': FieldValue.serverTimestamp(),
    };
  }

  Future<void> addObservation({
    required String organismType,
    required String commonName,
    required String speciesName,
    required double latitude,
    required double longitude,
    required String imageUrl,
  }) async {
    await observations.add(_getObservationData(
      organismType: organismType,
      commonName: commonName,
      speciesName: speciesName,
      latitude: latitude,
      longitude: longitude,
      imageUrl: imageUrl,
    ));

    // Update the user's rank after adding an observation
    await updateUserRank();
  }

  Future<void> updateObservation({
    required String docID,
    String? organismType,
    String? commonName,
    String? speciesName,
    double? latitude,
    double? longitude,
    String? imageUrl,
  }) {
    Map<String, dynamic> data = {
      if (organismType != null) 'OrganismType': organismType,
      if (commonName != null) 'CommonName': commonName,
      if (speciesName != null) 'SpeciesName': speciesName,
      if (latitude != null) 'Latitude': latitude,
      if (longitude != null) 'Longitude': longitude,
      if (imageUrl != null) 'ImageURL': imageUrl,
      'Timestamp': FieldValue.serverTimestamp(),
    };

    return observations.doc(docID).update(data);
  }


  Stream<QuerySnapshot> getObservationsByType(String type, String searchText) {
    final search = searchText.isEmpty ? "" : searchText;
    return FirebaseFirestore.instance
        .collection('observations')
        .where('OrganismType', isEqualTo: type)
        .where('SpeciesName', isGreaterThanOrEqualTo: search)
        .where('SpeciesName', isLessThanOrEqualTo: search + '\uf8ff')
        .orderBy('Timestamp', descending: true)
        .limit(5)
        .snapshots();
  }




  Future<void> deleteObservation(String docID) async {
    await observations.doc(docID).delete();
  }

  // Fetch observation count for the current user
  Future<int> getObservationCount() async {
    final querySnapshot = await observations.where('UserEmail', isEqualTo: user?.email).get();
    return querySnapshot.docs.length; // Returns the number of observations
  }

  // Update the user's rank based on observation count
  Future<void> updateUserRank() async {
    int observationCount = await getObservationCount();

    String rank;
    if (observationCount >= 20) {
      rank = 'Gold';
    } else if (observationCount >= 15) {
      rank = 'Silver';
    } else if (observationCount >= 10) {
      rank = 'Bronze';
    } else {
      rank = 'Newbie';
    }

    // Update the rank in Firestore
    await users.doc(user?.email).update({
      'rank': rank,
      'observationCount': observationCount, // Optional: track observation count in user's document
    });
  }
}*/

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:csv/csv.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class FirestoreService {
  final User? user = FirebaseAuth.instance.currentUser;
  final CollectionReference observations =
  FirebaseFirestore.instance.collection('observations');
  final CollectionReference users =
  FirebaseFirestore.instance.collection('Users');

  // Helper function to return observation data
  Map<String, dynamic> _getObservationData({
    required String organismType,
    required String commonName,
    required String speciesName,
    required double latitude,
    required double longitude,
    required String imageUrl,
    required int count, // NEW
    required String notes, // NEW
    required String classificationMethod, // NEW
  }) {
    return {
      'UserEmail': user?.email ?? 'Unknown',
      'OrganismType': organismType,
      'CommonName': commonName,
      'SpeciesName': speciesName,
      'Latitude': latitude,
      'Longitude': longitude,
      'ImageURL': imageUrl,
      'Count': count, // NEW
      'Notes': notes, // NEW
      'ClassificationMethod': classificationMethod, // NEW
      'Timestamp': FieldValue.serverTimestamp(),
    };
  }

  Future<void> addObservation({
    required String organismType,
    required String commonName,
    required String speciesName,
    required double latitude,
    required double longitude,
    required String imageUrl,
    required int count, // NEW
    required String notes, // NEW
    required String classificationMethod, // NEW
  }) async {
    await observations.add(_getObservationData(
      organismType: organismType,
      commonName: commonName,
      speciesName: speciesName,
      latitude: latitude,
      longitude: longitude,
      imageUrl: imageUrl,
      count: count, // NEW
      notes: notes, // NEW
      classificationMethod: classificationMethod, // NEW
    ));

    // Update the user's rank after adding an observation
    await updateUserRank();
  }

  Future<void> updateObservation({
    required String docID,
    String? organismType,
    String? commonName,
    String? speciesName,
    double? latitude,
    double? longitude,
    String? imageUrl,
  }) {
    Map<String, dynamic> data = {
      if (organismType != null) 'OrganismType': organismType,
      if (commonName != null) 'CommonName': commonName,
      if (speciesName != null) 'SpeciesName': speciesName,
      if (latitude != null) 'Latitude': latitude,
      if (longitude != null) 'Longitude': longitude,
      if (imageUrl != null) 'ImageURL': imageUrl,
      'Timestamp': FieldValue.serverTimestamp(),
    };

    return observations.doc(docID).update(data);
  }

  Stream<QuerySnapshot> getObservationsByType(String type, String searchText) {
    final search = searchText.isEmpty ? "" : searchText;
    return FirebaseFirestore.instance
        .collection('observations')
        .where('OrganismType', isEqualTo: type)
        .where('SpeciesName', isGreaterThanOrEqualTo: search)
        .where('SpeciesName', isLessThanOrEqualTo: search + '\uf8ff')
        .orderBy('Timestamp', descending: true)
        .limit(5)
        .snapshots();
  }

  Future<void> deleteObservation(String docID) async {
    await observations.doc(docID).delete();
  }

  // Fetch observation count for the current user
  Future<int> getObservationCount() async {
    final querySnapshot = await observations.where('UserEmail', isEqualTo: user?.email).get();
    return querySnapshot.docs.length; // Returns the number of observations
  }

  // Update the user's rank based on observation count
  Future<void> updateUserRank() async {
    int observationCount = await getObservationCount();

    String rank;
    if (observationCount >= 20) {
      rank = 'Gold';
    } else if (observationCount >= 15) {
      rank = 'Silver';
    } else if (observationCount >= 10) {
      rank = 'Bronze';
    } else {
      rank = 'Newbie';
    }

    // Update the rank in Firestore
    await users.doc(user?.email).update({
      'rank': rank,
      'observationCount': observationCount, // Optional: track observation count in user's document
    });
  }

  // UPDATED: Global Export (Admins Only)
  Future<void> exportGlobalObservationsToCSV() async {
    try {
      // 1. Verify admin status before allowing the massive download
      bool isAdmin = await isCurrentUserAdmin();
      if (!isAdmin) {
        throw Exception("Unauthorized: You do not have permission to export the global dataset.");
      }

      // 2. Fetch ALL observations in the database (Notice we removed the .where() filter!)
      final querySnapshot = await observations.get();

      List<List<dynamic>> rows = [];
      rows.add([
        "Date", "Time", "Observer Email", "Latitude", "Longitude", "Organism Type",
        "Common Name", "Species Name", "Count", "Classification Method", "Notes", "Image URL"
      ]);

      for (var doc in querySnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;

        String dateStr = "";
        String timeStr = "";
        if (data['Timestamp'] != null && data['Timestamp'] is Timestamp) {
          DateTime dt = (data['Timestamp'] as Timestamp).toDate();
          dateStr = "${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}";
          timeStr = "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
        }

        rows.add([
          dateStr,
          timeStr,
          data['UserEmail'] ?? "Unknown", // Added Observer Email to track who found what
          data['Latitude'] ?? "",
          data['Longitude'] ?? "",
          data['OrganismType'] ?? "",
          data['CommonName'] ?? "",
          data['SpeciesName'] ?? "",
          data['Count'] ?? 1,
          data['ClassificationMethod'] ?? "Manual",
          data['Notes'] ?? "",
          data['ImageURL'] ?? "",
        ]);
      }

      String csvData = const ListToCsvConverter().convert(rows);
      final directory = await getTemporaryDirectory();
      final path = "${directory.path}/GLOBAL_biodiversity_data.csv";
      final file = File(path);
      await file.writeAsString(csvData);

      // THE FIX: Explicitly tell Android this is a safe text/csv file
      final xFile = XFile(path, mimeType: 'text/csv');

      // Trigger the share sheet
      await Share.shareXFiles(
        [xFile],
        subject: 'Global Master Observation Data', // Email clients require a subject
      );

    } catch (e) {
      print("Error exporting CSV: $e");
      rethrow;
    }
      /*
      String csvData = const ListToCsvConverter().convert(rows);
      final directory = await getTemporaryDirectory();
      final path = "${directory.path}/GLOBAL_biodiversity_data.csv";
      final file = File(path);
      await file.writeAsString(csvData);

      await Share.shareXFiles([XFile(path)], text: 'Global Master Observation Data');

    } catch (e) {
      print("Error exporting CSV: $e");
      // Optional: You could throw this error to show it in a dialog in the UI
      rethrow;
    }*/
  }

  /*
  // NEW: Export to CSV for Spatial Analysis (QGIS/ArcGIS)
  Future<void> exportObservationsToCSV() async {
    try {
      final querySnapshot = await observations.where('UserEmail', isEqualTo: user?.email).get();

      List<List<dynamic>> rows = [];
      rows.add([
        "Date", "Time", "Latitude", "Longitude", "Organism Type",
        "Common Name", "Species Name", "Count", "Classification Method", "Notes"
      ]);

      for (var doc in querySnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;

        String dateStr = "";
        String timeStr = "";
        if (data['Timestamp'] != null && data['Timestamp'] is Timestamp) {
          DateTime dt = (data['Timestamp'] as Timestamp).toDate();
          dateStr = "${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}";
          timeStr = "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
        }

        rows.add([
          dateStr,
          timeStr,
          data['Latitude'] ?? "",
          data['Longitude'] ?? "",
          data['OrganismType'] ?? "",
          data['CommonName'] ?? "",
          data['SpeciesName'] ?? "",
          data['Count'] ?? 1,
          data['ClassificationMethod'] ?? "Manual",
          data['Notes'] ?? "",
        ]);
      }

      String csvData = const ListToCsvConverter().convert(rows);
      final directory = await getTemporaryDirectory();
      final path = "${directory.path}/biodiversity_data.csv";
      final file = File(path);
      await file.writeAsString(csvData);

      await Share.shareXFiles([XFile(path)], text: 'My Observation Spatial Data');

    } catch (e) {
      print("Error exporting CSV: $e");
    }
  }*/

  // NEW: Check if the current user is an Admin
  Future<bool> isCurrentUserAdmin() async {
    if (user?.email == null) return false;

    try {
      final doc = await users.doc(user?.email).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        return data['role'] == 'admin';
      }
      return false;
    } catch (e) {
      print("Error checking admin status: $e");
      return false;
    }
  }
}