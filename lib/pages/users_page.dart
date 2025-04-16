/*import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cubaankedua/components/my_list_tile.dart';
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

                //list of users
                Expanded(
                  child: ListView.builder(
                    itemCount: users.length,
                    padding: const EdgeInsets.all(0),
                    itemBuilder: (context, index) {
                      //get individual user
                      final user = users[index];

                      // get data from each user
                      String username = user['username'];
                      String email = user['email'];
                  
                      return MyListTile(
                          title: username,
                          subTitle: email
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
*/

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cubaankedua/components/my_list_tile.dart';
import 'package:cubaankedua/helper/helper_functions.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../components/my_back_button.dart';

class UsersPage extends StatelessWidget {
  const UsersPage({super.key});

  // Determine user rank
  String getRank(int totalObservations) {
    if (totalObservations >= 20) return 'Gold';
    if (totalObservations >= 15) return 'Silver';
    if (totalObservations >= 10) return 'Bronze';
    return 'Newcomer';
  }

  // Get crown color based on rank
  Color? getCrownColor(String rank) {
    switch (rank) {
      case 'Gold':
        return Colors.amber[700];
      case 'Silver':
        return Colors.grey;
      case 'Bronze':
        return Colors.brown;
      default:
        return null;
    }
  }

  // Fetch observation count for a user
  Future<int> getObservationCount(String email) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('observations')
        .where('UserEmail', isEqualTo: email)
        .get();

    return snapshot.docs.length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: StreamBuilder(
        stream: FirebaseFirestore.instance.collection("Users").snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            displayMessageToUser("Something went wrong", context);
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.data == null) {
            return const Text("No Data");
          }

          final users = snapshot.data!.docs;

          return Column(
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 50.0, left: 25),
                child: Row(children: [MyBackButton()]),
              ),

              // User List
              Expanded(
                child: ListView.builder(
                  itemCount: users.length,
                  padding: const EdgeInsets.all(0),
                  itemBuilder: (context, index) {
                    final user = users[index];
                    final username = user['username'];
                    final email = user['email'];

                    return FutureBuilder<int>(
                      future: getObservationCount(email),
                      builder: (context, obsSnapshot) {
                        if (!obsSnapshot.hasData) {
                          return const SizedBox.shrink(); // loading state
                        }

                        int count = obsSnapshot.data!;
                        String rank = getRank(count);
                        Color? crownColor = getCrownColor(rank);

                        return MyListTile(
                          titleWidget: Row(
                            children: [
                              Text(username),
                              if (crownColor != null) ...[
                                const SizedBox(width: 8),
                                Icon(
                                  FontAwesomeIcons.crown,
                                  color: crownColor,
                                  size: 16,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  rank,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: crownColor,
                                  ),
                                )
                              ],
                            ],
                          ),
                          subTitle: email,
                        );
                      },
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

