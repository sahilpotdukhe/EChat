import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:echat/models/contact_model.dart';
import 'package:echat/providers/user_provider.dart';
import 'package:echat/resources/auth_methods.dart';
import 'package:echat/resources/chat_firebase_methods.dart';
import 'package:echat/screens/chat_list/widgets/chat_list_widgets.dart';
import 'package:echat/screens/chat_list/widgets/contact_tile_view.dart';
import 'package:echat/screens/chat_list/widgets/new_chat_button.dart';
import 'package:echat/screens/chat_list/widgets/quiet_box.dart';
import 'package:echat/screens/chat_list/widgets/user_circle.dart';
import 'package:echat/utils/scale_utils.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ChatListScreen extends StatelessWidget {
  final AuthMethods authMethods = AuthMethods();
  final ChatFirebaseMethods chatFirebaseMethods = ChatFirebaseMethods();

  @override
  Widget build(BuildContext context) {
    ScaleUtils.init(context);
    UserProvider userProvider = Provider.of<UserProvider>(context);
    return Scaffold(
      backgroundColor: Colors.black,
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
            onPressed: () async{
              // Navigator.push(context, MaterialPageRoute(builder: (context)=>SplashScreen()));
            },
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
