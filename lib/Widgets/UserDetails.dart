import 'package:echat/Models/UserModel.dart';
import 'package:echat/Provider/UserProvider.dart';
import 'package:echat/Resources/AuthMethods.dart';
import 'package:echat/Screens/ChatList/ChatListScreenWidgets/ChatListWidgets.dart';
import 'package:echat/Screens/ChatList/ChatListScreenWidgets/UserCircle.dart';
import 'package:echat/Screens/LoginScreen.dart';
import 'package:echat/Utils/utilities.dart';
import 'package:echat/Widgets/CachedChatImage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_styled_toast/flutter_styled_toast.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';

class UserDetails extends StatelessWidget {
  UserDetails({super.key});

  AuthMethods authMethods = AuthMethods();

  @override
  Widget build(BuildContext context) {
    UserProvider userProvider = Provider.of<UserProvider>(context);
    UserModel? userModel = userProvider.getUser;
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          Container(
            height: 200,
            decoration: BoxDecoration(
                color: Colors.blue,
                borderRadius: BorderRadius.only(
                    bottomRight: Radius.circular(50),
                    bottomLeft: Radius.circular(50))),
            child: Center(
              child: CircleAvatar(
                radius: 55,
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.transparent,
                  backgroundImage: AssetImage('assets/user.jpg'),
                  foregroundImage: NetworkImage(userModel!.profilePhoto),
                ),
              ),
            ),
          ),
          Spacer(),
          Container(
            width: 400,
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.5),
                    spreadRadius: 5,
                    blurRadius: 7,
                    offset: Offset(0, 3), // changes position of shadow
                  ),
                ]),
            child: Padding(
              padding: const EdgeInsets.all(18.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    "Name",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                  ),
                  Text(
                    userModel.name,
                    style: TextStyle(fontSize: 16),
                  ),
                  Divider(),
                  Text(
                    "Username",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                  ),
                  Text(
                    userModel.username,
                    style: TextStyle(fontSize: 16),
                  ),
                  Divider(),
                  Text(
                    "Email",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                  ),
                  Text(
                    userModel.email,
                    style: TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ),
          ),
          Spacer(),
          Container(
            decoration: BoxDecoration(
                color: Colors.blue,
                borderRadius: BorderRadius.only(
                    topRight: Radius.circular(50),
                    topLeft: Radius.circular(50))),
            height: 200,
            child: Center(
                child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: Icon(Icons.logout, size: 30),
                  color: Colors.white,
                  onPressed: () {
                    authMethods.googleLogOut();
                    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) {return LoginScreen();}));
                    showToast("Account Logout Successfully", backgroundColor: Colors.red, context: context);
                  },
                ),
                SizedBox(
                  height: 10,
                ),
                Text(
                  "LogOut",
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 20),
                ),
              ],
            )),
          )
        ],
      ),
    );
  }
}
