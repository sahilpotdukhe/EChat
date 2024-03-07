import 'package:echat/Models/UserModel.dart';
import 'package:echat/Resources/AuthMethods.dart';
import 'package:echat/Screens/ChatList/ChatListScreenWidgets/ChatListWidgets.dart';
import 'package:echat/Screens/ChatScreen/ChatScreen.dart';
import 'package:echat/Utils/UniversalVariables.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AvailableUsers extends StatefulWidget {
  const AvailableUsers({super.key});

  @override
  State<AvailableUsers> createState() => _AvailableUsersState();
}

class _AvailableUsersState extends State<AvailableUsers> {
  AuthMethods authMethods = AuthMethods();
  FirebaseAuth _auth = FirebaseAuth.instance;
  List<UserModel> userList = [];

  @override
  void initState() {
    authMethods.fetchAllUsers(_auth.currentUser!).then((List<UserModel> list) { // When you use the exclamation mark(!), you’re telling the Dart analyzer that you’re confident the value will not be null at runtime.
      setState(() {
        userList = list;
      });
    });
    // TODO: implement initState
    super.initState();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text("All Users",style: TextStyle(color: Colors.white),),
        backgroundColor: UniversalVariables.appThemeColor,
        iconTheme: IconThemeData(
          color: Colors.white
        ),
        centerTitle: true,
      ),
      body:(userList.length==0)?
      Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Colors.white,),
              SizedBox(height: 20,),
              Text("Users Loading ......",style: TextStyle(color: Colors.green,fontSize: 18,fontWeight: FontWeight.w500),)
            ],
          )
      )
      :ListView.builder(
        itemCount: userList.length,
        itemBuilder: (context, index) {
          return ChatCustomTile(
              leading:CircleAvatar(
                backgroundColor: Colors.grey,
                backgroundImage: NetworkImage(userList[index].profilePhoto),
              ),
              title: Text(
                userList[index].name,
                style: TextStyle(color: Colors.white,fontSize: 16),
              ),
              icon: Container(),
              subtitle: Text(
                userList[index].username,
                style: TextStyle(color: Colors.white60, fontWeight: FontWeight.bold),
              ),
              trailing: Icon(Icons.message,color: Colors.white,),
              margin: EdgeInsets.all(0),
              mini: false,
              onTap: (){
                Navigator.push(context, MaterialPageRoute(builder: (context) => ChatScreen(receiver: userList[index])));},
              onLongPress: () {}
          );
          return null;
        },
      ),
    );
  }
}
