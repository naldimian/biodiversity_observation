import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cubaankedua/services/firestore.dart';
import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // Firestore
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
