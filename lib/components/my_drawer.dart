/*
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class MyDrawer extends StatelessWidget {
  const MyDrawer({super.key});

  //logout user
  void logout(){
    FirebaseAuth.instance.signOut();
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Theme.of(context).colorScheme.surface,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            children: [
            DrawerHeader(
              child: Icon(
                Icons.favorite,
                color: Theme.of(context).colorScheme.inversePrimary,
              ),
            ),

            const SizedBox(height: 25),
            //home tile
            Padding(
              padding: const EdgeInsets.only(left: 25.0),
              child: ListTile(
                leading: Icon(
                  Icons.home,
                  color: Theme.of(context).colorScheme.inversePrimary,
                ),
                title: Text("H O M E"),
                onTap: (){
                  //this is already homepage so just pop drawer
                  Navigator.pop(context);
                },
              ),
            ),

            //profile tile
            Padding(
              padding: const EdgeInsets.only(left: 25.0),
              child: ListTile(
                leading: Icon(
                  Icons.person,
                  color: Theme.of(context).colorScheme.inversePrimary,
                ),
                title: const Text("P R O F I L E"),
                onTap: (){
                  //pop drawer
                  Navigator.pop(context);

                  //navigate to profile page
                  Navigator.pushNamed(context, '/profile_page');
                },
              ),
            ),

            //users tile
            Padding(
              padding: const EdgeInsets.only(left: 25.0),
              child: ListTile(
                leading: Icon(
                  Icons.group,
                  color: Theme.of(context).colorScheme.inversePrimary,
                ),
                title: const Text("U S E R S"),
                onTap: (){
                  //pop drawer
                  Navigator.pop(context);

                  // navigate to profile page
                  Navigator.pushNamed(context, '/users_page');

                },
              ),
            ),

          ],
          ),
          //drawer header

          //LOGOUT
          Padding(
            padding: const EdgeInsets.only(left: 25.0, bottom: 25.0),
            child: ListTile(
              leading: Icon(
                Icons.logout,
                color: Theme.of(context).colorScheme.inversePrimary,
              ),
              title: const Text("L O G O U T"),
              onTap: (){
                //pop drawer
                Navigator.pop(context);

                //logout
                logout();
              },
            ),
          ),
          

        ],
      ),
    );
  }
}
*/

/*
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cubaankedua/pages/all_observations_map_page.dart';

class MyDrawer extends StatelessWidget {
  const MyDrawer({super.key});



  //logout user
  void logout() {
    FirebaseAuth.instance.signOut();
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Theme.of(context).colorScheme.surface,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            children: [
              DrawerHeader(
                child: Icon(
                  Icons.favorite,
                  color: Theme.of(context).colorScheme.inversePrimary,
                ),
              ),

              const SizedBox(height: 25),
              //home tile
              Padding(
                padding: const EdgeInsets.only(left: 25.0),
                child: ListTile(
                  leading: Icon(
                    Icons.home,
                    color: Theme.of(context).colorScheme.inversePrimary,
                  ),
                  title: const Text("H O M E"),
                  onTap: () {
                    //this is already homepage so just pop drawer
                    Navigator.pop(context);
                  },
                ),
              ),

              //profile tile
              Padding(
                padding: const EdgeInsets.only(left: 25.0),
                child: ListTile(
                  leading: Icon(
                    Icons.person,
                    color: Theme.of(context).colorScheme.inversePrimary,
                  ),
                  title: const Text("P R O F I L E"),
                  onTap: () {
                    //pop drawer
                    Navigator.pop(context);

                    //navigate to profile page
                    Navigator.pushNamed(context, '/profile_page');
                  },
                ),
              ),

              //users tile
              Padding(
                padding: const EdgeInsets.only(left: 25.0),
                child: ListTile(
                  leading: Icon(
                    Icons.group,
                    color: Theme.of(context).colorScheme.inversePrimary,
                  ),
                  title: const Text("U S E R S"),
                  onTap: () {
                    //pop drawer
                    Navigator.pop(context);

                    // navigate to users page
                    Navigator.pushNamed(context, '/users_page');
                  },
                ),
              ),

              // NEW: Global Map tile
              Padding(
                padding: const EdgeInsets.only(left: 25.0),
                child: ListTile(
                  leading: Icon(
                    Icons.map,
                    color: Theme.of(context).colorScheme.inversePrimary,
                  ),
                  title: const Text("M A P"),
                  onTap: () {
                    // pop drawer
                    Navigator.pop(context);

                    // navigate to global map page
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AllObservationsMapPage(),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),

          //LOGOUT
          Padding(
            padding: const EdgeInsets.only(left: 25.0, bottom: 25.0),
            child: ListTile(
              leading: Icon(
                Icons.logout,
                color: Theme.of(context).colorScheme.inversePrimary,
              ),
              title: const Text("L O G O U T"),
              onTap: () {
                //pop drawer
                Navigator.pop(context);

                //logout
                logout();
              },
            ),
          ),
        ],
      ),
    );
  }
}*/

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cubaankedua/pages/all_observations_map_page.dart';
import 'package:cubaankedua/services/firestore.dart'; // NEW: Import FirestoreService

class MyDrawer extends StatefulWidget {
  const MyDrawer({super.key});

  @override
  State<MyDrawer> createState() => _MyDrawerState();
}

class _MyDrawerState extends State<MyDrawer> {
  // NEW: State variables for Admin check
  bool _isAdmin = false;
  final FirestoreService _firestore = FirestoreService();

  @override
  void initState() {
    super.initState();
    _checkAdminStatus();
  }

  // NEW: Fetch role from Firestore
  Future<void> _checkAdminStatus() async {
    bool adminStatus = await _firestore.isCurrentUserAdmin();
    if (mounted) {
      setState(() {
        _isAdmin = adminStatus;
      });
    }
  }

  // Logout user
  void logout() {
    FirebaseAuth.instance.signOut();
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Theme.of(context).colorScheme.surface,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            children: [
              DrawerHeader(
                child: Icon(
                  Icons.favorite,
                  color: Theme.of(context).colorScheme.inversePrimary,
                ),
              ),

              const SizedBox(height: 25),

              // HOME TILE
              Padding(
                padding: const EdgeInsets.only(left: 25.0),
                child: ListTile(
                  leading: Icon(
                    Icons.home,
                    color: Theme.of(context).colorScheme.inversePrimary,
                  ),
                  title: const Text("H O M E"),
                  onTap: () {
                    // this is already homepage so just pop drawer
                    Navigator.pop(context);
                  },
                ),
              ),

              // PROFILE TILE
              Padding(
                padding: const EdgeInsets.only(left: 25.0),
                child: ListTile(
                  leading: Icon(
                    Icons.person,
                    color: Theme.of(context).colorScheme.inversePrimary,
                  ),
                  title: const Text("P R O F I L E"),
                  onTap: () {
                    // pop drawer
                    Navigator.pop(context);

                    // navigate to profile page
                    Navigator.pushNamed(context, '/profile_page');
                  },
                ),
              ),

              // USERS TILE
              Padding(
                padding: const EdgeInsets.only(left: 25.0),
                child: ListTile(
                  leading: Icon(
                    Icons.group,
                    color: Theme.of(context).colorScheme.inversePrimary,
                  ),
                  title: const Text("U S E R S"),
                  onTap: () {
                    // pop drawer
                    Navigator.pop(context);

                    // navigate to users page
                    Navigator.pushNamed(context, '/users_page');
                  },
                ),
              ),

              // GLOBAL MAP TILE
              Padding(
                padding: const EdgeInsets.only(left: 25.0),
                child: ListTile(
                  leading: Icon(
                    Icons.map,
                    color: Theme.of(context).colorScheme.inversePrimary,
                  ),
                  title: const Text("M A P"),
                  onTap: () {
                    // pop drawer
                    Navigator.pop(context);

                    // navigate to global map page
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AllObservationsMapPage(),
                      ),
                    );
                  },
                ),
              ),

              // -----------------------------------------------------
              // NEW: ADMIN TOOLS SECTION
              // -----------------------------------------------------
              if (_isAdmin) ...[
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 25.0),
                  child: Divider(
                    color: Theme.of(context).colorScheme.inversePrimary.withOpacity(0.5),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 25.0, top: 10.0, bottom: 5.0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "A D M I N   T O O L S",
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.inversePrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 25.0),
                  child: ListTile(
                    leading: Icon(
                      Icons.download_for_offline,
                      color: Theme.of(context).colorScheme.inversePrimary,
                    ),
                    title: const Text("E X P O R T   C S V"),
                    onTap: () {
                      // 1. CAPTURE THE MESSENGER BEFORE CLOSING THE DRAWER
                      final scaffoldMessenger = ScaffoldMessenger.of(context);

                      // 2. Close the drawer
                      Navigator.pop(context);

                      // 3. Show Confirmation Dialog
                      showDialog(
                        context: context,
                        builder: (dialogContext) => AlertDialog(
                          title: const Text("Export Global Database?"),
                          content: const Text(
                              "This will compile every observation in the database into a single CSV file. This action consumes database reads.\n\nProceed?"
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(dialogContext), // Cancel
                              child: const Text("Cancel"),
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(context).colorScheme.primary,
                                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                              ),
                              onPressed: () async {
                                // Close dialog immediately
                                Navigator.pop(dialogContext);

                                // USE THE CAPTURED MESSENGER (Safe!)
                                scaffoldMessenger.showSnackBar(
                                  const SnackBar(content: Text("Compiling master dataset...")),
                                );

                                try {
                                  await _firestore.exportGlobalObservationsToCSV();
                                } catch (e) {
                                  scaffoldMessenger.showSnackBar(
                                    SnackBar(content: Text("Export failed: $e")),
                                  );
                                }
                              },
                              child: const Text("Export"),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ],
          ),

          // LOGOUT TILE
          Padding(
            padding: const EdgeInsets.only(left: 25.0, bottom: 25.0),
            child: ListTile(
              leading: Icon(
                Icons.logout,
                color: Theme.of(context).colorScheme.inversePrimary,
              ),
              title: const Text("L O G O U T"),
              onTap: () {
                // pop drawer
                Navigator.pop(context);

                // logout
                logout();
              },
            ),
          ),
        ],
      ),
    );
  }
}