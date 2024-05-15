import 'package:echat/Models/UserModel.dart';
import 'package:echat/Resources/AuthMethods.dart';
import 'package:echat/Utils/CallUtilities.dart';
import 'package:echat/Utils/ScreenDimensions.dart';
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
    ScaleUtils.init(context);
    return  Scaffold(
        backgroundColor: Colors.white,
        body: SingleChildScrollView(
          child: Container(
            child: Stack(
              children: [
                Container(
                  height: 200*ScaleUtils.verticalScale,
                  decoration: BoxDecoration(
                    gradient: UniversalVariables.appGradient,
                    borderRadius: BorderRadius.only(
                        bottomRight: Radius.circular(80*ScaleUtils.scaleFactor),
                        bottomLeft: Radius.circular(80*ScaleUtils.scaleFactor)),
                  ),
                ),
                Center(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(height: 110*ScaleUtils.verticalScale),
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
                          radius: 75*ScaleUtils.scaleFactor,
                          child: CircleAvatar(
                            radius: 70*ScaleUtils.scaleFactor,
                            backgroundColor: Colors.transparent,
                            backgroundImage: AssetImage('assets/user.jpg'),
                            foregroundImage: NetworkImage(receiverModel.profilePhoto),
                          ),
                        ),
                      ),
                      SizedBox(
                        height: 10*ScaleUtils.verticalScale,
                      ),
                      Text(
                        receiverModel.name,
                        style: TextStyle(
                            color: Colors.black,
                            fontSize: 25*ScaleUtils.scaleFactor,
                            fontWeight: FontWeight.bold),
                      ),
                      Padding(
                        padding: EdgeInsets.all(8.0*ScaleUtils.scaleFactor),
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
                                  borderRadius: BorderRadius.circular(20*ScaleUtils.scaleFactor),
                                  color: HexColor("3957ED"),
                                ),
                                child: Padding(
                                  padding:  EdgeInsets.all(12.0*ScaleUtils.scaleFactor),
                                  child: Row(
                                    children:  [
                                      Text(
                                        "Voice Call",
                                        style: TextStyle(fontSize:16*ScaleUtils.scaleFactor,color: Colors.white),
                                      ),
                                      SizedBox(width: 8*ScaleUtils.horizontalScale,),
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
                                  borderRadius: BorderRadius.circular(20*ScaleUtils.scaleFactor),
                                  color: HexColor("3957ED"),
                                ),
                                child: Padding(
                                  padding:  EdgeInsets.all(12.0*ScaleUtils.scaleFactor),
                                  child:  Row(
                                    children:  [
                                      Text(
                                        "Video Call",
                                        style: TextStyle(fontSize:16*ScaleUtils.scaleFactor,color: Colors.white),
                                      ),
                                      SizedBox(width: 8*ScaleUtils.horizontalScale,),
                                      Icon(Icons.video_call,color: Colors.white,)
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding:  EdgeInsets.symmetric(horizontal: 10*ScaleUtils.horizontalScale,vertical: 20*ScaleUtils.verticalScale),
                        child: Container(
                          decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(30*ScaleUtils.scaleFactor),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.5),
                                  spreadRadius: 5,
                                  blurRadius: 7,
                                  offset: Offset(0, 3), // changes position of shadow
                                ),
                              ]),
                          child: Padding(
                            padding:  EdgeInsets.all(18.0*ScaleUtils.scaleFactor),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  "Name",
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold, fontSize: 18*ScaleUtils.scaleFactor),
                                ),
                                Text(
                                  receiverModel.name,
                                  style: TextStyle(fontSize: 16*ScaleUtils.scaleFactor),
                                ),
                                Divider(),
                                Text(
                                  "Username",
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold, fontSize: 18*ScaleUtils.scaleFactor),
                                ),
                                Text(
                                  receiverModel.username,
                                  style: TextStyle(fontSize: 16*ScaleUtils.scaleFactor),
                                ),
                                Divider(),
                                Text(
                                  "Email",
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold, fontSize: 18*ScaleUtils.scaleFactor),
                                ),
                                Text(
                                  receiverModel.email,
                                  style: TextStyle(fontSize: 16*ScaleUtils.scaleFactor),
                                ),
                                (receiverModel.phoneNumber=='')?Container()
                                    :Column(
                                  children: [
                                    Divider(),
                                    Text(
                                      "Phone number",
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold, fontSize: 18*ScaleUtils.scaleFactor),
                                    ),
                                    Text(
                                      receiverModel.phoneNumber,
                                      style: TextStyle(fontSize: 16*ScaleUtils.scaleFactor),
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
                                          fontWeight: FontWeight.bold, fontSize: 18*ScaleUtils.scaleFactor),
                                    ),
                                    Text(
                                      receiverModel.gender,
                                      style: TextStyle(fontSize: 16*ScaleUtils.scaleFactor),
                                    ),
                                  ],
                                )
                              ],
                            ),
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
