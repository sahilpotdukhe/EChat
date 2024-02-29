import 'package:echat/Models/UserModel.dart';
import 'package:echat/Provider/UserProvider.dart';
import 'package:echat/Resources/AuthMethods.dart';
import 'package:echat/Screens/ChatList/ChatListScreenWidgets/ChatListWidgets.dart';
import 'package:echat/Screens/LoginScreen.dart';
import 'package:echat/Widgets/CachedChatImage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_styled_toast/flutter_styled_toast.dart';
import 'package:provider/provider.dart';

class UserDetails extends StatelessWidget {
  UserDetails({super.key});

  AuthMethods authMethods = AuthMethods();

  @override
  Widget build(BuildContext context) {
    UserProvider userProvider = Provider.of<UserProvider>(context);
    UserModel? userModel = userProvider.getUser;
    return Container(
      margin: EdgeInsets.only(top: 25),
      child: Column(
        children: [
          CustomAppBar(
              title: Text('Profile',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18
              ),
              ),
              actions: [
                IconButton(
                  icon: Icon(Icons.logout),
                  onPressed: () {
                    authMethods.googleLogOut();
                    Navigator.pushAndRemoveUntil(context,
                        MaterialPageRoute(builder: (context) {
                      return LoginScreen();
                    }),
                        (Route<dynamic> route) => false);
                    showToast("Account Logout Successfully",
                        backgroundColor: Colors.red, context: context);
                  },
                ),
              ],
              leading: IconButton(
                icon: Icon(
                  Icons.arrow_back,
                  color: Colors.white,
                ),
                onPressed: () => Navigator.maybePop(context),
              ),
              centerTitle: true),
          Container(
            padding: EdgeInsets.symmetric(vertical: 20, horizontal: 20),
            child: Row(
              children: [
                CachedChatImage(
                    imageUrl: userModel!.profilePhoto,
                    isRound: true,
                    radius: 50,
                    height: 0,
                    width: 0,
                    fit: BoxFit.cover
                ),
                SizedBox(width: 15,),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(userModel.name,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Colors.white
                    ),
                    ),
                    SizedBox(height: 10,),
                    Text(userModel.email,
                      style: TextStyle(
                          fontSize: 14,
                          color: Colors.white
                      ),
                    )
                  ],
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}
