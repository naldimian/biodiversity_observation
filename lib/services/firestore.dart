/* 1ST
import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService{

  //get collection of notes
  final CollectionReference observations =
      FirebaseFirestore.instance.collection('observations');

  //CREATE
  Future<void> addObservation(String name){
    return observations.add({
      'name': name,
      'timestamp': Timestamp.now(),


    });
  }
  //READ
  Stream<QuerySnapshot> getObservationsStream() {
    final observationStream =
        observations.orderBy('timestamp', descending: true).snapshots();

    return observationStream;
  }

  //UPDATE
  Future<void> updateObservation(String docID, String newObservation){
    return observations.doc(docID).update({
    'name': newObservation,
    'timestamp': Timestamp.now(),
    });
  }

  //DELETE
  Future<void> deleteObservation(String docID) {
    return observations.doc(docID).delete();
  }

}
*/


/* 2ND
import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final CollectionReference observations =
  FirebaseFirestore.instance.collection('observations');

  Future<void> addObservation(String name, String location, String? imageUrl) async {
    try {
      await observations.add({
        'name': name,
        'location': location,
        'image': imageUrl ?? "No image",  // ✅ Prevent null values
        'timestamp': FieldValue.serverTimestamp(),
      });
      print("Added: Name=$name, Location=$location, Image=$imageUrl");
    } catch (e) {
      print("Error adding observation: $e");
    }
  }



  Future<void> updateObservation(
      String docID, String name, String location, String? imageUrl) {
    return observations.doc(docID).update({
      'name': name,
      'location': location,
      if (imageUrl != null) 'image': imageUrl,  // ✅ Only update 'image' if it's not null
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  Stream<QuerySnapshot> getObservationsStream() {
    return observations.orderBy('timestamp', descending: true).snapshots();
  }

  Future<void> deleteObservation(String docID) {
    return observations.doc(docID).delete();
  }
}*/

/* original
// each post contains the logged in user, user email and timestamp
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreService{

  // current logged in user
  User? user = FirebaseAuth.instance.currentUser;

  // get collection of posts from firebase
  final CollectionReference posts =
      FirebaseFirestore.instance.collection('Posts');


  // post a message
Future<void> addPost (String message){
  return posts.add({
    'UserEmail' : user!.email,
    'PostMessage' : message,
    'Timestamp' : Timestamp.now(),

  });
}

  // read posts from database
Stream<QuerySnapshot> getPostsStream() {
  final postsStream = FirebaseFirestore.instance
      .collection('Posts')
      .orderBy('Timestamp', descending: true)
      .snapshots();

  return postsStream;
}

  //addition
  final CollectionReference observations =
  FirebaseFirestore.instance.collection('observations');

  // Add Observation
  Future<void> addObservation(String name, String location, String? imageUrl) async {
    try {
      await observations.add({
        'name': name,
        'location': location,
        'image': imageUrl ?? "No image",  // ✅ Prevent null values
        'timestamp': FieldValue.serverTimestamp(),
      });
      print("Added: Name=$name, Location=$location, Image=$imageUrl");
    } catch (e) {
      print("Error adding observation: $e");
    }
  }



  Future<void> updateObservation(
      String docID, String name, String location, String? imageUrl) {
    return observations.doc(docID).update({
      'name': name,
      'location': location,
      if (imageUrl != null) 'image': imageUrl,  // ✅ Only update 'image' if it's not null
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  Stream<QuerySnapshot> getObservationsStream() {
    return observations.orderBy('timestamp', descending: true).snapshots();
  }

  Future<void> deleteObservation(String docID) {
    return observations.doc(docID).delete();
  }







// end of addition

}
*/
/*
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreService {
  // Current user
  final User? user = FirebaseAuth.instance.currentUser;

  final CollectionReference observations =
  FirebaseFirestore.instance.collection('observations');

  // Add observation
  Future<void> addObservation({
    required String organismType,
    required String commonName,
    required String speciesName,
    required double latitude,
    required double longitude,
    required String imageUrl,
  }) async {
    await observations.add({
      'UserEmail': user?.email ?? 'Unknown',
      'OrganismType': organismType,
      'CommonName': commonName,
      'SpeciesName': speciesName,
      'Latitude': latitude,
      'Longitude': longitude,
      'ImageURL': imageUrl,
      'Timestamp': FieldValue.serverTimestamp(),
    });
  }

  // Stream of observations
  Stream<QuerySnapshot> getObservationsStream() {
    return observations.orderBy('Timestamp', descending: true).snapshots();
  }

  // Update observation
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

  // Delete
  Future<void> deleteObservation(String docID) async {
    await observations.doc(docID).delete();
  }
}

*/

// important
/*
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreService {
  // Current user
  final User? user = FirebaseAuth.instance.currentUser;

  final CollectionReference observations =
  FirebaseFirestore.instance.collection('observations');

  // Add observation
  Future<void> addObservation({
    required String organismType,
    required String commonName,
    required String speciesName,
    required double latitude,  // Store latitude as double
    required double longitude, // Store longitude as double
    required String imageUrl,
  }) async {
    await observations.add({
      'UserEmail': user?.email ?? 'Unknown',
      'OrganismType': organismType,
      'CommonName': commonName,
      'SpeciesName': speciesName,
      'Latitude': latitude, // Store latitude
      'Longitude': longitude, // Store longitude
      'ImageURL': imageUrl,
      'Timestamp': FieldValue.serverTimestamp(),
    });
  }

  Stream<QuerySnapshot> getObservationsStream() {
    return observations.orderBy('Timestamp', descending: true).snapshots();
  }

  // Update observation
  Future<void> updateObservation({
    required String docID,
    String? organismType,
    String? commonName,
    String? speciesName,
    double? latitude, // Updating latitude
    double? longitude, // Updating longitude
    String? imageUrl,
  }) {
    Map<String, dynamic> data = {
      if (organismType != null) 'OrganismType': organismType,
      if (commonName != null) 'CommonName': commonName,
      if (speciesName != null) 'SpeciesName': speciesName,
      if (latitude != null) 'Latitude': latitude, // Updating latitude
      if (longitude != null) 'Longitude': longitude, // Updating longitude
      if (imageUrl != null) 'ImageURL': imageUrl,
      'Timestamp': FieldValue.serverTimestamp(),
    };

    return observations.doc(docID).update(data);
  }

  // Delete observation
  Future<void> deleteObservation(String docID) async {
    await observations.doc(docID).delete();
  }
}
*/

//previous
/*
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreService {
  final User? user = FirebaseAuth.instance.currentUser;

  final CollectionReference observations =
  FirebaseFirestore.instance.collection('observations');

  Future<void> addObservation({
    required String organismType,
    required String commonName,
    required String speciesName,
    required double latitude,
    required double longitude,
    required String imageUrl,
  }) async {
    await observations.add({
      'UserEmail': user?.email ?? 'Unknown',
      'OrganismType': organismType,
      'CommonName': commonName,
      'SpeciesName': speciesName,
      'Latitude': latitude,
      'Longitude': longitude,
      'ImageURL': imageUrl,
      'Timestamp': FieldValue.serverTimestamp(),
    });
  }

  // Optimized: Fetch only required fields for better performance
  Stream<QuerySnapshot> getObservationsStream() {
    return observations
        .orderBy('Timestamp', descending: true)
        .limit(5) // Limit number of documents to improve speed
        .snapshots();
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

  Future<void> deleteObservation(String docID) async {
    await observations.doc(docID).delete();
  }
}
*/

/*
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreService {
  final User? user = FirebaseAuth.instance.currentUser;

  final CollectionReference observations =
  FirebaseFirestore.instance.collection('observations');

  Future<void> addObservation({
    required String organismType,
    required String commonName,
    required String speciesName,
    required double latitude,
    required double longitude,
    required String imageUrl,
  }) async {
    await observations.add({
      'UserEmail': user?.email ?? 'Unknown',
      'OrganismType': organismType,
      'CommonName': commonName,
      'SpeciesName': speciesName,
      'Latitude': latitude,
      'Longitude': longitude,
      'ImageURL': imageUrl,
      'Timestamp': FieldValue.serverTimestamp(),
    });
  }

  // Optimized stream by filtering OrganismType
  Stream<QuerySnapshot> getObservationsByType(String organismType) {
    return observations
        .where('OrganismType', isEqualTo: organismType)
        .orderBy('Timestamp', descending: true)
        .limit(20)
        .snapshots();
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

  Future<void> deleteObservation(String docID) async {
    await observations.doc(docID).delete();
  }
}
*/


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

  Stream<QuerySnapshot> getObservationsByType(String organismType) {
    return observations
        .where('OrganismType', isEqualTo: organismType)
        .orderBy('Timestamp', descending: true)
        .limit(20)
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
      rank = 'Newcomer';
    }

    // Update the rank in Firestore
    await users.doc(user?.email).update({
      'rank': rank,
      'observationCount': observationCount, // Optional: track observation count in user's document
    });
  }
}
