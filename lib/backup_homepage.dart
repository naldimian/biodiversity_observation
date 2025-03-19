import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cubaankedua/services/firestore.dart';
import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {

  //firestore
  final FirestoreService firestoreService = FirestoreService();


  //text controller
  final TextEditingController textController = TextEditingController();

  //open a dialog box to add note
  void openNoteBox({String? docID}) {
    showDialog(
        context: context,
        builder: (context) => AlertDialog(
          content: TextField(
            controller: textController,
          ),
          actions: [
            //button to save
            ElevatedButton(
                onPressed: () {
                  //add a new note
                  if (docID == null){
                    firestoreService.addObservation(textController.text);
                  }

                  //update existing observation
                  else{
                    firestoreService.updateObservation(docID, textController.text);
                  }
                  //clear text controller
                  textController.clear();

                  //close dialog box
                  Navigator.pop(context);

                },
                child: Text("Add"),
            )
          ],
        ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: const Text("Observation"),
          backgroundColor: Colors.blue,
        ),
      floatingActionButton: FloatingActionButton(
          onPressed: openNoteBox,
          child: const Icon(Icons.add),
      ),
      body:StreamBuilder<QuerySnapshot>(
        stream: firestoreService.getObservationsStream(),
        builder: (context, snapshot) {
          //if have data, get all docs
          if (snapshot.hasData) {
            List observationsList = snapshot.data!.docs;

            //display a list
            return ListView.builder(
              itemCount: observationsList.length,
              itemBuilder: (context, index) {
                //get each individual doc
                DocumentSnapshot document = observationsList [index];
                String docID = document.id;

                //get note from each doc
                Map<String, dynamic> data =
                    document.data() as Map<String, dynamic>;
                String observationText = data['name'];

                //display as a list tile
                return ListTile(
                  title: Text(observationText),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      //update button
                      IconButton(
                        onPressed: () => openNoteBox(docID: docID),
                        icon: const Icon(Icons.edit),
                      ),

                      //delete button
                      IconButton(
                        onPressed: () => firestoreService.deleteObservation(docID),
                        icon: const Icon(Icons.delete),
                      ),
                    ],
                  )
                );
              },
            );
          }
          //if no data, return nothing
          else{
            return const Text("No observations..");
          }
        },
      )
    );
  }
}
