/*import 'package:cloud_firestore/cloud_firestore.dart';

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
}
