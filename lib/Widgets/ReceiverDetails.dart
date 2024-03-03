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

class ReceiverDetails extends StatelessWidget {
  final UserModel? receiverModel;
  ReceiverDetails({super.key, this.receiverModel});

  AuthMethods authMethods = AuthMethods();

  @override
  Widget build(BuildContext context) {
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
                  foregroundImage: NetworkImage(receiverModel!.profilePhoto),
                ),
              ),
            ),
          ),
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
                    receiverModel!.name,
                    style: TextStyle(fontSize: 16),
                  ),
                  Divider(),
                  Text(
                    "Username",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                  ),
                  Text(
                    receiverModel!.username,
                    style: TextStyle(fontSize: 16),
                  ),
                  Divider(),
                  Text(
                    "Email",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                  ),
                  Text(
                    receiverModel!.email,
                    style: TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
