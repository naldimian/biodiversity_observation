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