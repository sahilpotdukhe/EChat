import 'package:echat/Models/UserModel.dart';
import 'package:echat/Provider/UserProvider.dart';
import 'package:echat/Resources/AuthMethods.dart';
import 'package:echat/Screens/LoginScreen.dart';
import 'package:echat/Utils/UniversalVariables.dart';
import 'package:echat/Widgets/EditProfile.dart';
import 'package:echat/Widgets/FullImageWidget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_styled_toast/flutter_styled_toast.dart';
import 'package:hexcolor/hexcolor.dart';
import 'package:provider/provider.dart';

class NewUserDetails extends StatefulWidget {
  const NewUserDetails({super.key});

  @override
  State<NewUserDetails> createState() => _NewUserDetailsState();
}

class _NewUserDetailsState extends State<NewUserDetails> {
  AuthMethods authMethods = AuthMethods();

  @override
  Widget build(BuildContext context) {
    UserProvider userProvider = Provider.of<UserProvider>(context);
    UserModel? userModel = userProvider.getUser;
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        // shrinkWrap: true,
        child:
          Container(
            height: MediaQuery.of(context).size.height,
            child: Stack(
              children: [
                Container(
                  height: 230,
                  decoration: BoxDecoration(
                    gradient: UniversalVariables.appGradient,
                    borderRadius: BorderRadius.only(
                        bottomRight: Radius.circular(100),
                        bottomLeft: Radius.circular(100)),
                  ),
                ),
                Center(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(height: 150),
                      GestureDetector(
                        onTap: (){
                          Navigator.push(context,
                              MaterialPageRoute(builder: (_) {
                                return FullImageWidget(
                                  imageUrl: userModel!.profilePhoto,
                                );
                              }));
                        },
                        child: CircleAvatar(
                          radius: 75,
                          child: CircleAvatar(
                            radius: 70,
                            backgroundColor: Colors.transparent,
                            backgroundImage: AssetImage('assets/user.jpg'),
                            foregroundImage: NetworkImage(userModel!.profilePhoto),
                          ),
                        ),
                      ),
                      SizedBox(
                        height: 10,
                      ),
                      Text(
                        userModel.name,
                        style: TextStyle(
                            color: Colors.black,
                            fontSize: 25,
                            fontWeight: FontWeight.bold),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            InkWell(
                              onTap: () {
                                Navigator.pushNamed(context, '/searchScreen');
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20),
                                  color: HexColor("3957ED"),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Row(
                                    children: const [
                                      Text(
                                        "Message Friend",
                                        style: TextStyle(fontSize:16,color: Colors.white),
                                      ),
                                      SizedBox(width: 8,),
                                      Icon(Icons.message,color: Colors.white,)
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            InkWell(
                              onTap: () {
                                Navigator.push(context, MaterialPageRoute(builder: (context)=>EditProfile()));
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20),
                                  color: HexColor("3957ED"),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child:  Row(
                                    children:const  [
                                      Text(
                                        "Edit Profile",
                                        style: TextStyle(fontSize:16,color: Colors.white),
                                      ),
                                      SizedBox(width: 8,),
                                      Icon(Icons.edit,color: Colors.white,)
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        height: 20,
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
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 20),
                              ),
                              Text(
                                userModel.name,
                                style: TextStyle(fontSize: 16),
                              ),
                              Divider(),
                              Text(
                                "Username",
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 20),
                              ),
                              Text(
                                userModel.username,
                                style: TextStyle(fontSize: 16),
                              ),
                              Divider(),
                              Text(
                                "Email",
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 20),
                              ),
                              Text(
                                userModel.email,
                                style: TextStyle(fontSize: 16),
                              ),
                              (userModel.phoneNumber=='')?Container()
                                  :Column(
                                children: [
                                  Divider(),
                                  Text(
                                    "Phone number",
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold, fontSize: 20),
                                  ),
                                  Text(
                                    userModel.phoneNumber,
                                    style: TextStyle(fontSize: 16),
                                  ),
                                ],
                              ),
                              (userModel.gender == "")?Container()
                                  :Column(
                                children: [
                                  Divider(),
                                  Text(
                                    "Gender",
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold, fontSize: 20),
                                  ),
                                  Text(
                                    userModel.gender,
                                    style: TextStyle(fontSize: 16),
                                  ),
                                ],
                              )
                            ],
                          ),
                        ),
                      ),
                      Spacer(),
                      InkWell(
                        onTap: () {
                          authMethods.googleLogOut();
                          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) {return LoginScreen();}));
                          showToast("Account Logout Successfully", backgroundColor: Colors.red, context: context);
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            color: HexColor("EE3427"),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child:  Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children:const  [
                                Text(
                                  "Logout",
                                  style: TextStyle(fontSize:16,color: Colors.white),
                                ),
                                SizedBox(width: 8,),
                                Icon(Icons.logout,color: Colors.white,)
                              ],
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 70,)
                    ],
                  ),
                )
              ],
            ),
          ),
      ),
    );
  }
}
