import 'package:echat/Models/UserModel.dart';
import 'package:echat/Resources/AuthMethods.dart';
import 'package:echat/Utils/CallUtilities.dart';
import 'package:echat/Utils/UniversalVariables.dart';
import 'package:echat/Widgets/FullImageWidget.dart';
import 'package:flutter/material.dart';
import 'package:hexcolor/hexcolor.dart';


class ReceiverDetails extends StatelessWidget {
  final UserModel receiverModel;
  final UserModel senderModel;
  ReceiverDetails({super.key, required this.receiverModel, required this.senderModel});

  AuthMethods authMethods = AuthMethods();

  @override
  Widget build(BuildContext context) {
    return  Scaffold(
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
                                  imageUrl: receiverModel.profilePhoto,
                                );
                              }));
                        },
                        child: CircleAvatar(
                          radius: 75,
                          child: CircleAvatar(
                            radius: 70,
                            backgroundColor: Colors.transparent,
                            backgroundImage: AssetImage('assets/user.jpg'),
                            foregroundImage: NetworkImage(receiverModel.profilePhoto),
                          ),
                        ),
                      ),
                      SizedBox(
                        height: 10,
                      ),
                      Text(
                        receiverModel.name,
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
                                CallUtilities.dial(
                                    from_Caller: senderModel,
                                    to_receiver: receiverModel,
                                    context: context,
                                    callType: 'audioCall');
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
                                        "Voice Call",
                                        style: TextStyle(fontSize:16,color: Colors.white),
                                      ),
                                      SizedBox(width: 8,),
                                      Icon(Icons.call,color: Colors.white,)
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            InkWell(
                              onTap: () {
                                CallUtilities.dial(
                                    from_Caller: senderModel,
                                    to_receiver: receiverModel,
                                    context: context,
                                    callType: 'videoCall');
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
                                        "Video Call",
                                        style: TextStyle(fontSize:16,color: Colors.white),
                                      ),
                                      SizedBox(width: 8,),
                                      Icon(Icons.video_call,color: Colors.white,)
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
                                receiverModel.name,
                                style: TextStyle(fontSize: 16),
                              ),
                              Divider(),
                              Text(
                                "Username",
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 20),
                              ),
                              Text(
                                receiverModel.username,
                                style: TextStyle(fontSize: 16),
                              ),
                              Divider(),
                              Text(
                                "Email",
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 20),
                              ),
                              Text(
                                receiverModel.email,
                                style: TextStyle(fontSize: 16),
                              ),
                              (receiverModel.phoneNumber=='')?Container()
                                  :Column(
                                children: [
                                  Divider(),
                                  Text(
                                    "Phone number",
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold, fontSize: 20),
                                  ),
                                  Text(
                                    receiverModel.phoneNumber,
                                    style: TextStyle(fontSize: 16),
                                  ),
                                ],
                              ),
                              (receiverModel.gender == "")?Container()
                                  :Column(
                                children: [
                                  Divider(),
                                  Text(
                                    "Gender",
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold, fontSize: 20),
                                  ),
                                  Text(
                                    receiverModel.gender,
                                    style: TextStyle(fontSize: 16),
                                  ),
                                ],
                              )
                            ],
                          ),
                        ),
                      ),
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
