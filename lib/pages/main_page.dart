import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cubaankedua/components/my_drawer.dart';
import 'package:cubaankedua/components/my_list_tile.dart';
import 'package:cubaankedua/components/my_post_button.dart';
import 'package:cubaankedua/components/my_textfield.dart';
import 'package:cubaankedua/services/firestore.dart';
import 'package:flutter/material.dart';

class MainPage extends StatelessWidget {
  MainPage({super.key});

  // firestore access
  final FirestoreService database = FirestoreService();

  //TEXT CONTROLLER
  final TextEditingController newPostController = TextEditingController();

  // post message
  void postMessage(){
    if(newPostController.text.isNotEmpty){
      String message = newPostController.text;
      database.addPost(message);
    }

    // clear the controller
    newPostController.clear();
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: Text(
          "H O M E",
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        foregroundColor: Theme.of(context).colorScheme.inversePrimary,
        elevation: 0,

      ),
      drawer: const MyDrawer(),
      body: Column(
        children: [
          //TEXTFIELD BOX FOR USER TO TYPE
          Padding(
            padding: const EdgeInsets.all(25.0),
            child: Row(
              children: [
                //text field
                Expanded(
                  child: MyTextfield(
                      hintText: "Upload something..",
                      obscureText: false,
                      controller: newPostController,
                  ),
                ),
                
                // post button
                PostButton(
                  onTap: postMessage,
                )
              ],
            ),
          ),

          //OBSERVATIONS
          StreamBuilder(
              stream: database.getPostsStream(),
              builder: (context, snapshot) {
                // show loading circle
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(),
                  );
                }

                // get all posts
                  final posts = snapshot.data!.docs;

                // no data?
                if (snapshot.data == null || posts.isEmpty) {
                  return const Center(
                    child: Padding(
                        padding: EdgeInsets.all(25),
                        child: Text("No posts.. Upload something"),

                    ),
                  );
                }

                // return as a list
                return Expanded(
                    child: ListView.builder(
                      itemCount: posts.length,
                        itemBuilder: (context, index){
                        // get each individual post
                          final post = posts[index];

                          // get data from each post
                          String message = post['PostMessage'];
                          String userEmail = post['UserEmail'];
                          Timestamp timestamp = post['Timestamp'];
                          
                          //return as list tile
                          return MyListTile(title: message, subTitle: userEmail);
                        },
                    )
                );

                // return as a list
              },
          )
        ],
      ),
    );
  }
}
