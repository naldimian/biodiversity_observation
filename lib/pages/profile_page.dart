/*import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../components/my_back_button.dart';

class ProfilePage extends StatelessWidget {
  ProfilePage({super.key});

  //current logged in user
  final User? currentUser = FirebaseAuth.instance.currentUser;

  //future to fetch user details
  Future<DocumentSnapshot<Map<String, dynamic>>> getUserDetails() async{
    return await FirebaseFirestore.instance
        .collection("Users")
        .doc(currentUser!.email)
        .get();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      backgroundColor: Theme.of(context).colorScheme.surface,
        body: FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          future: getUserDetails(),
          builder: (context, snapshot){
            //loading..
            if (snapshot.connectionState == ConnectionState.waiting){
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            //error
            else if (snapshot.hasError) {
              return Text("Error: ${snapshot.error}");
            }

            //data received
            else if (snapshot.hasData) {
              //extract data
              Map<String, dynamic>? user = snapshot.data!.data();
              
              return Center(
                child: Column(
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

                    // profile pic
                    Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      padding: const EdgeInsets.all(25.0),
                      child: const Icon(
                          Icons.person,
                          size: 64,
                      ),
                    ),

                    const SizedBox(height: 25),

                    //username
                    Text(
                        user! ['username'],
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                    ),

                    const SizedBox(height: 10),

                    // email
                    Text(
                        user['email'],
                        style: TextStyle(
                          color: Colors.grey[600],
                        ),
                    ),
                  ],
                ),
              );
            } else {
              return const Text("No data");
            }
          },
        ),
    );
  }
}
*/
/*
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:pie_chart/pie_chart.dart';
import '../components/my_back_button.dart';

class ProfilePage extends StatelessWidget {
  ProfilePage({super.key});

  final User? currentUser = FirebaseAuth.instance.currentUser;

  Future<DocumentSnapshot<Map<String, dynamic>>> getUserDetails() async {
    return await FirebaseFirestore.instance
        .collection("Users")
        .doc(currentUser!.email)
        .get();
  }

  Future<Map<String, double>> getObservationCountsByType() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('observations')
        .where('UserEmail', isEqualTo: currentUser?.email)
        .get();

    Map<String, double> counts = {};
    for (var doc in snapshot.docs) {
      String type = doc['OrganismType'] ?? 'Unknown';
      counts[type] = (counts[type] ?? 0) + 1;
    }
    return counts;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: FutureBuilder<Map<String, double>>(
        future: getObservationCountsByType(),
        builder: (context, countsSnapshot) {
          return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            future: getUserDetails(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting ||
                  countsSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError || countsSnapshot.hasError) {
                return Text("Error: ${snapshot.error ?? countsSnapshot.error}");
              } else if (snapshot.hasData && countsSnapshot.hasData) {
                Map<String, dynamic>? user = snapshot.data!.data();
                Map<String, double> counts = countsSnapshot.data!;

                // Format the counts for the pie chart
                Map<String, String> labeledCounts = {};
                counts.forEach((type, count) {
                  labeledCounts[type] = "$type (${count.toInt()})"; // Integer count
                });

                return SingleChildScrollView(
                  child: Column(
                    children: [
                      const SizedBox(height: 50),

                      const Padding(
                        padding: EdgeInsets.only(left: 25),
                        child: Row(children: [MyBackButton()]),
                      ),

                      const SizedBox(height: 25),

                      // Profile Picture
                      Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        padding: const EdgeInsets.all(25.0),
                        child: const Icon(Icons.person, size: 64),
                      ),

                      const SizedBox(height: 25),

                      // Username
                      Text(
                        user!['username'],
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 10),

                      // Email
                      Text(
                        user['email'],
                        style: TextStyle(color: Colors.grey[600]),
                      ),

                      const SizedBox(height: 30),

                      // Observation Breakdown Card
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          elevation: 4,
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              children: [
                                const Text(
                                  'Observation Breakdown',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                PieChart(
                                  dataMap: counts,
                                  chartRadius:
                                  MediaQuery.of(context).size.width / 2.0,
                                  legendOptions: LegendOptions(
                                    showLegends: true,
                                    legendPosition: LegendPosition.right,
                                    legendTextStyle: const TextStyle(
                                      fontSize: 14,
                                    ),
                                  ),
                                  chartValuesOptions: const ChartValuesOptions(
                                    showChartValuesInPercentage: true,
                                  ),
                                  colorList: [
                                    Colors.blue,
                                    Colors.red,
                                    Colors.orange,
                                    Colors.purple
                                  ], // Customize the color list if needed
                                ),
                                const SizedBox(height: 10),
                                // Display the breakdown next to the legend
                                Wrap(
                                  spacing: 15,
                                  runSpacing: 5,
                                  children: counts.entries.map((entry) {
                                    return Chip(
                                      label: Text(
                                          "${entry.key} (${entry.value.toInt()})"), // Integer count
                                      backgroundColor:
                                      Theme.of(context).colorScheme.primary,
                                    );
                                  }).toList(),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 30),
                    ],
                  ),
                );
              } else {
                return const Text("No data");
              }
            },
          );
        },
      ),
    );
  }
}
*/

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:pie_chart/pie_chart.dart';
import '../components/my_back_button.dart';
import '../components/rank_info_button.dart';

class ProfilePage extends StatelessWidget {
  ProfilePage({super.key});

  final User? currentUser = FirebaseAuth.instance.currentUser;

  // Fetch both user data and observation counts together for better performance
  Future<Map<String, dynamic>> fetchProfileData() async {
    final userDoc = await FirebaseFirestore.instance
        .collection("Users")
        .doc(currentUser!.email)
        .get();

    final obsSnapshot = await FirebaseFirestore.instance
        .collection('observations')
        .where('UserEmail', isEqualTo: currentUser?.email)
        .get();

    Map<String, double> counts = {};
    for (var doc in obsSnapshot.docs) {
      String type = doc['OrganismType'] ?? 'Unknown';
      counts[type] = (counts[type] ?? 0) + 1;
    }

    return {
      'user': userDoc.data(),
      'counts': counts,
    };
  }

  // Helper to get rank color
  Color getRankColor(String rank) {
    switch (rank) {
      case 'Gold':
        return Colors.amber[700]!;
      case 'Silver':
        return Colors.grey;
      case 'Bronze':
        return Colors.brown;
      case 'Newcomer':
      default:
        return Colors.blueGrey;
    }
  }

  // Helper to determine rank dynamically based on observation count
  String getRank(Map<String, double> counts) {
    int totalObservations = counts.values.fold<int>(0, (sum, val) => sum + val.toInt());

    if (totalObservations >= 20) {
      return 'Gold';
    } else if (totalObservations >= 15) {
      return 'Silver';
    } else if (totalObservations >= 10) {
      return 'Bronze';
    } else {
      return 'Newcomer';
    }
  }

  // Helper to get icon color based on rank
  Color getIconColor(String rank) {
    switch (rank) {
      case 'Gold':
        return Colors.amber[700]!;
      case 'Silver':
        return Colors.grey;
      case 'Bronze':
        return Colors.brown;
      case 'Newcomer':
      default:
        return Colors.blueGrey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: FutureBuilder<Map<String, dynamic>>(
        future: fetchProfileData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          } else if (!snapshot.hasData || snapshot.data!['user'] == null) {
            return const Center(child: Text("No data found."));
          }

          final user = snapshot.data!['user'];
          final counts = snapshot.data!['counts'] as Map<String, double>;

          // Get rank based on observation count
          String rank = getRank(counts);

          return SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 50),
                 Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 25),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const MyBackButton(),
                      buildRankInfoButton(context), // Info button added here
                    ],
                  ),
                ),

                const SizedBox(height: 25),

                // Profile Picture with color based on rank
                Container(
                  decoration: BoxDecoration(
                    color: getIconColor(rank),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  padding: const EdgeInsets.all(25.0),
                  child: const Icon(Icons.person, size: 64, color: Colors.white),
                ),

                const SizedBox(height: 25),

                // Username with Rank Name and Star Icon colored according to the rank
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      FontAwesomeIcons.crown,
                      color: getIconColor(rank),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      user['username'] ?? 'Unknown User',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // Rank name placed under the username with border around it
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: getRankColor(rank), // Border color according to rank
                        width: 1.5,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      rank,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: getRankColor(rank),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                // Email
                Text(
                  user['email'] ?? '',
                  style: TextStyle(color: Colors.grey[600]),
                ),

                const SizedBox(height: 30),

                // Observation Breakdown Card
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          const Text(
                            'Observation Breakdown',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 20),
                          PieChart(
                            dataMap: counts,
                            chartRadius: MediaQuery.of(context).size.width / 2.0,
                            legendOptions: const LegendOptions(
                              showLegends: true,
                              legendPosition: LegendPosition.right,
                              legendTextStyle: TextStyle(fontSize: 14),
                            ),
                            chartValuesOptions: const ChartValuesOptions(
                              showChartValuesInPercentage: true,
                            ),
                            colorList: [
                              Colors.blue,
                              Colors.red,
                            ],
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 15,
                            runSpacing: 5,
                            children: counts.entries.map((entry) {
                              return Chip(
                                label: Text(
                                    "${entry.key} (${entry.value.toInt()})"
                                ),
                                backgroundColor: Theme.of(context).colorScheme.primary,
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 30),
              ],
            ),
          );
        },
      ),
    );
  }
}
