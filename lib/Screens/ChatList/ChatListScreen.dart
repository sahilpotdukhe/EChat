import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:echat/Models/ContactModel.dart';
import 'package:echat/Provider/UserProvider.dart';
import 'package:echat/Resources/AuthMethods.dart';
import 'package:echat/Resources/ChatFirebaseMethods.dart';
import 'package:echat/Screens/Call/PickupLayout.dart';
import 'package:echat/Screens/ChatList/ChatListScreenWidgets/ChatListWidgets.dart';
import 'package:echat/Screens/ChatList/ChatListScreenWidgets/ContactTileView.dart';
import 'package:echat/Screens/ChatList/ChatListScreenWidgets/NewChatButton.dart';
import 'package:echat/Screens/ChatList/ChatListScreenWidgets/QuietBox.dart';
import 'package:echat/Screens/ChatList/ChatListScreenWidgets/UserCircle.dart';
import 'package:flutter/material.dart';
import 'package:flutter_styled_toast/flutter_styled_toast.dart';
import 'package:echat/Screens/LoginScreen.dart';
import 'package:echat/Utils/UniversalVariables.dart';
import 'package:provider/provider.dart';

class ChatListScreen extends StatelessWidget {
  AuthMethods authMethods = AuthMethods();
  ChatFirebaseMethods chatFirebaseMethods = ChatFirebaseMethods();

  @override
  Widget build(BuildContext context) {
    UserProvider userProvider = Provider.of<UserProvider>(context);
    return Scaffold(
      backgroundColor: UniversalVariables.blackColor,
      appBar: CustomAppBar(
          title: UserCircle(),
          actions: <Widget>[
            IconButton(
              icon: Icon(
                Icons.search,
                color: Colors.white,
              ),
              onPressed: () {
                Navigator.pushNamed(context, '/searchScreen');
              },
            )
          ],
          leading: IconButton(
            icon: Icon(Icons.notifications),
            color: Colors.white,
            onPressed: () {},
          ),
          centerTitle: true),
      body: Container(
        child: StreamBuilder<QuerySnapshot>(
            stream: chatFirebaseMethods.fetchContacts(
                userId: userProvider.getUser!.uid),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                var docList = snapshot.data?.docs;
                if (docList!.isEmpty) {
                  return QuietBox(
                    screen: "ChatScreen",
                  );
                }
                return ListView.builder(
                    itemCount: docList.length,
                    itemBuilder: (context, index) {
                      ContactModel contactModel = ContactModel.fromMap(
                          docList[index].data() as Map<String, dynamic>);
                      return ContactTileView(contactModel: contactModel);
                    });
              }
              return Container();
            }),
      ),
      floatingActionButton: NewChatButton(),
    );
  }
}
