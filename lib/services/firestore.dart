
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
}