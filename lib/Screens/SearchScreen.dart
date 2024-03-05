import 'package:echat/Resources/AuthMethods.dart';
import 'package:echat/Screens/ChatList/ChatListScreenWidgets/ChatListWidgets.dart';
import 'package:echat/Screens/ChatScreen/ChatQuietBox.dart';
import 'package:echat/Screens/ChatScreen/ChatScreen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:echat/Models/UserModel.dart';
import 'package:echat/Utils/UniversalVariables.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  AuthMethods authMethods = AuthMethods();
  List<UserModel> userList = [];
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String query = "";
  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    User? currentUser = _auth.currentUser;
    authMethods.fetchAllUsers(currentUser!).then((List<UserModel> list) {// When you use the exclamation mark(!), you’re telling the Dart analyzer that you’re confident the value will not be null at runtime.
      setState(() {
        userList = list;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: UniversalVariables.appThemeColor,
          iconTheme: IconThemeData(
            color: Colors.white, //change your color here
          ),
          title: TextField(
            style: TextStyle(color: Colors.white),
            controller: searchController,
            textInputAction: TextInputAction.search,

            decoration: InputDecoration(
                hintText: 'Search',
                border: InputBorder.none,
                hintStyle: TextStyle(fontSize: 18.0, color: Colors.white),

            ),
            onChanged: (val) {
              setState(() {
                query = val;
                print(query);
              });
            },
          ),
          actions: [
            IconButton(
                icon: Icon(
                Icons.close,
                  color: Colors.white,
                ),
                onPressed: () {
                  WidgetsBinding.instance.addPostFrameCallback((_) => searchController.clear());
                  setState(() {
                    query="";
                  });
                },
               )
          ],
        ),
        body:(query=="")?ChatQuietBox(screen: "search",) :Container(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: buildSuggestions(query),
        ));
  }

  buildSuggestions(String query) {
    final List<UserModel> suggestionList = query.isEmpty
        ? []
        //this block of code filters the userList based on whether either the username or the name of each UserModel object contains the query string. It returns a list of UserModel objects that match the criteria.
        :userList.where((UserModel usermodel) { // userlist contains list of type UserModel
            // these returns true when any of the user's username or name matches with the query and add it to list
            String getUsername = usermodel.username.toLowerCase();
            String getName = usermodel.name.toLowerCase();
            String query0 = query.toLowerCase();
            bool matchesUsername = getUsername.contains(query0);
            bool matchesName = getName.contains(query0);
            return (matchesUsername || matchesName);
          }).toList();//This line closes the where method call and converts the filtered elements into a list. The toList() method is called on the result of the where operation, which returns a list containing only the elements that satisfy the condition specified in the anonymous function.

    return ListView.builder(
      itemCount: suggestionList.length,
      itemBuilder: (context, index) {
        UserModel searchedUser = UserModel(
            uid: suggestionList[index].uid,
            name: suggestionList[index].name,
            email: suggestionList[index].email,
            username: suggestionList[index].username,
            status: suggestionList[index].status,
            state: suggestionList[index].state,
            profilePhoto: suggestionList[index].profilePhoto,
            gender: suggestionList[index].gender,
            phoneNumber: suggestionList[index].phoneNumber
        );

        return ChatCustomTile(
            leading: CircleAvatar(
              backgroundColor: Colors.grey,
              backgroundImage: NetworkImage(searchedUser.profilePhoto),
            ),
            title:Text(
              searchedUser.name,
              style: TextStyle(color: Colors.white,fontSize: 16),
            ),

            icon: Container(),
            subtitle:   Text(
              searchedUser.username,
              style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
            ),
            trailing: Icon(Icons.message,color: Colors.white,),
            margin: EdgeInsets.all(0),
            mini: false,
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => ChatScreen(receiver: searchedUser)));
            },
            onLongPress: () {});
      },
    );
  }
}
