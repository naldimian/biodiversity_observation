import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cubaankedua/helper/helper_functions.dart';
import 'package:flutter/material.dart';

import '../components/my_back_button.dart';

class UsersPage extends StatelessWidget {
  const UsersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      backgroundColor: Theme.of(context).colorScheme.surface,
      body: StreamBuilder(
          stream: FirebaseFirestore.instance.collection("Users").snapshots(),
          builder: (context, snapshot) {
            //any errors
            if (snapshot.hasError) {
              displayMessageToUser("Something went wrong", context);
            }

            //show loading circle
            if (snapshot.connectionState == ConnectionState.waiting){
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            if (snapshot.data == null){
              return const Text("No Data");
            }

            //get all users
            final users = snapshot.data!.docs;

            return Column(
              children: [

                //back button
                const Padding(
                  padding: EdgeInsets.only(
                    top: 50.0,
                    left: 25,
                  ),
                  child: Row(
                    children: [
                      MyBackButton(),
                    ],
                  ),
                ),

                const SizedBox(height: 25),

                //list of users
                Expanded(
                  child: ListView.builder(
                    itemCount: users.length,
                    padding: const EdgeInsets.all(0),
                    itemBuilder: (context, index) {
                      //get individual user
                      final user = users[index];
                  
                      return ListTile(
                        title: Text(user['username']),
                        subtitle: Text(user['email']),
                      );
                    },
                  ),
                ),
              ],
            );
          },
      ),
    );
  }
}
