import 'package:echat/models/contact_model.dart';
import 'package:echat/models/user_model.dart';
import 'package:echat/providers/user_provider.dart';
import 'package:echat/resources/auth_methods.dart';
import 'package:echat/resources/chat_firebase_methods.dart';
import 'package:echat/screens/chat_list/widgets/chat_list_widgets.dart';
import 'package:echat/screens/chat_list/widgets/last_message_container.dart';
import 'package:echat/screens/chat/chat_screen.dart';
import 'package:echat/utils/scale_utils.dart';
import 'package:echat/widgets/cached_chat_image.dart';
import 'package:echat/widgets/online_dot_indicator.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ContactTileView extends StatelessWidget {
  final ContactModel contactModel;
  final AuthMethods _authMethods = AuthMethods();

  ContactTileView({super.key, required this.contactModel});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<UserModel?>(
        future: _authMethods.getUserDetailsById(contactModel.uid),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            UserModel userModel = snapshot.data!;
            return ViewLayout(contactUserModel: userModel);
          }
          // Contact's profile no longer exists, or failed to load: hide the row
          // instead of spinning forever.
          if (snapshot.connectionState == ConnectionState.done) {
            return const SizedBox.shrink();
          }
          return Container(
              height: 80,
              //constraints: BoxConstraints(maxHeight: 68, maxWidth: 60),
              child: Center(
                  child: Padding(
                    padding:  EdgeInsets.fromLTRB(8,8,8,0),
                    child: Column(
                      children:const [
                        Padding(
                          padding:  EdgeInsets.fromLTRB(8,8,8,0),
                          child: CircularProgressIndicator(),
                        ),
                        Divider(
                          color: Colors.white,
                          thickness: 0.2,
                        )
                      ],
                    ),
              )));
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
                  imageUrl: contactUserModel.profilePhoto,
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
          contactUserModel.name,
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
          style:
              TextStyle(color: Colors.white, fontFamily: "Arial", fontSize: 16*ScaleUtils.scaleFactor),
        ),
        icon: Container(),
        subtitle: LastMessageContainer(
            position: "subtitle",
            stream: chatFirebaseMethods.fetchLastMessageBetween(
                senderId: userProvider.getUser!.uid,
                receiverId: contactUserModel.uid)),
        trailing: LastMessageContainer(position: "trailing",stream: chatFirebaseMethods.fetchLastMessageBetween(senderId: userProvider.getUser!.uid, receiverId: contactUserModel.uid)),
        margin: EdgeInsets.all(0),
        mini: false,
        onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => ChatScreen(receiver: contactUserModel)));
        },
        onLongPress: () {}
    );
  }
}
