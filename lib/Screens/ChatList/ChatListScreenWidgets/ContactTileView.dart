import 'package:echat/ChatScreen/ChatScreen.dart';
import 'package:echat/Models/ContactModel.dart';
import 'package:echat/Models/UserModel.dart';
import 'package:echat/Provider/UserProvider.dart';
import 'package:echat/Resources/AuthMethods.dart';
import 'package:echat/Resources/ChatFirebaseMethods.dart';
import 'package:echat/Screens/ChatList/ChatListScreenWidgets/ChatListWidgets.dart';
import 'package:echat/Screens/ChatList/ChatListScreenWidgets/LastMessageContainer.dart';
import 'package:echat/Utils/UniversalVariables.dart';
import 'package:echat/Widgets/CachedChatImage.dart';
import 'package:echat/Widgets/OnlineDotIndicator.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ContactTileView extends StatelessWidget {
  final ContactModel contactModel;
  final AuthMethods _authMethods = AuthMethods();

  ContactTileView({super.key, required this.contactModel});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<UserModel>(
        future: _authMethods.getUserDetailsById(contactModel.uid),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            UserModel userModel = snapshot.data!;
            return ViewLayout(contactUserModel: userModel);
          }
          return Center(
            child: CircularProgressIndicator(),
          );
        });
  }
}

class ViewLayout extends StatelessWidget {
  final UserModel contactUserModel;
  final ChatFirebaseMethods chatFirebaseMethods = ChatFirebaseMethods();

  ViewLayout({super.key, required this.contactUserModel});

  @override
  Widget build(BuildContext context) {
    UserProvider userProvider = Provider.of<UserProvider>(context);
    return ChatCustomTile(
        leading: Container(
          constraints: BoxConstraints(maxHeight: 60, maxWidth: 60),
          child: Stack(
            children: [
              CachedChatImage(
                  imageUrl: contactUserModel?.profilePhoto ?? 'https://www.esm.rochester.edu/uploads/NoPhotoAvailable.jpg',
                  isRound: true,
                  radius: 80,
                  height: 0,
                  width: 0,
                  fit: BoxFit.cover),
             OnlineDotIndicator(uid: contactUserModel.uid)
            ],
          ),
        ),
        title: Text(
          contactUserModel.name ?? '..',
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
          style:
              TextStyle(color: Colors.white, fontFamily: "Arial", fontSize: 19),
        ),
        icon: Icon(
          Icons.person,
          color: Colors.white,
        ),
        subtitle: LastMessageContainer(stream: chatFirebaseMethods.fetchLastMessageBetween(senderId: userProvider.getUser!.uid, receiverId: contactUserModel.uid)),
        trailing: Icon(Icons.add),
        margin: EdgeInsets.all(0),
        mini: false,
        onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (context)=> ChatScreen(receiver:  contactUserModel)));
        },
        onLongPress: () {});
  }
}