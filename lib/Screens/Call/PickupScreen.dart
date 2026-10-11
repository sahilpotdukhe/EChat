import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:echat/Models/CallLogModel.dart';
import 'package:echat/Models/UserModel.dart';
import 'package:echat/Resources/AuthMethods.dart';
import 'package:echat/Resources/CallMethods.dart';
import 'package:echat/Models/CallModel.dart';
import 'package:echat/Resources/Repository/LogRepository.dart';
import 'package:echat/Screens/Call/CallScreen.dart';
import 'package:echat/Screens/Call/AudioCallScreen.dart';
import 'package:echat/Screens/ChatScreen/ChatScreen.dart';
import 'package:echat/Utils/ScreenDimensions.dart';
import 'package:echat/Utils/UniversalVariables.dart';
import 'package:flutter/material.dart';
import 'package:hexcolor/hexcolor.dart';

class PickupScreen extends StatefulWidget {
  final CallModel callModel;

  const PickupScreen({super.key, required this.callModel});

  @override
  State<PickupScreen> createState() => _PickupScreenState();
}

class _PickupScreenState extends State<PickupScreen> {
  bool isCallMissed = true;
  final AuthMethods authMethods = AuthMethods();
  String callerEmail = "";
  UserModel? callerModel;
  final CallMethods callMethods = CallMethods();
  Timer? _ringTimer;
  static const Duration _ringTimeout = Duration(seconds: 45);

  // initializes and adds log to db
  addToLocalStorage({required String callStatus}) {
    CallLogModel callLogModel = CallLogModel(
        callerName: widget.callModel.callerName,
        callerPic: widget.callModel.callerPic,
        receiverName: widget.callModel.receiverName,
        receiverPic: widget.callModel.receiverPic,
        callStatus: callStatus,
        timestamp: DateTime.now().toString(),
        callType: widget.callModel.callType
    );
    LogRepository.addLogs(callLogModel); // adds the data to database
  }
  @override
  void initState() {
    // TODO: implement initState
    getUser();
    super.initState();
    _startRinging();
  }

  @override
  void didUpdateWidget(covariant PickupScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // A new call replaced an old one while this screen was showing.
    if (oldWidget.callModel.channelId != widget.callModel.channelId) {
      _startRinging();
    }
  }

  // Rings for at most 45 seconds. A call that is already older than that
  // (caller's app died, or this app was opened much later) is ended right away.
  // createdAt is null for calls from old app builds: the timer covers those.
  void _startRinging() {
    _ringTimer?.cancel();
    Timestamp? createdAt = widget.callModel.createdAt;
    if (createdAt != null &&
        DateTime.now().difference(createdAt.toDate()) > _ringTimeout) {
      callMethods.endCall(callModel: widget.callModel);
      return;
    }
    _ringTimer = Timer(_ringTimeout, () {
      // Nobody answered. Deleting the docs closes this screen, and dispose()
      // logs the missed call.
      if (isCallMissed) callMethods.endCall(callModel: widget.callModel);
    });
  }

  getUser() async{
      callerModel = await authMethods.getUserDetailsById(widget.callModel.callerId);
     if (!mounted || callerModel == null) return;
     setState(() {
       callerEmail = callerModel!.email;
     });
  }

  @override
  void dispose() {
    // TODO: implement dispose
    _ringTimer?.cancel();
    super.dispose();
    if(isCallMissed){
      addToLocalStorage(callStatus: "missed");
    }
  }


  @override
  Widget build(BuildContext context) {
    ScaleUtils.init(context);
    return  Scaffold(
      backgroundColor: UniversalVariables.blackColor,
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Padding(
              padding:  EdgeInsets.all(8.0*ScaleUtils.scaleFactor),
              child: Text("Incoming call",
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 18*ScaleUtils.scaleFactor
                ),
              ),
            ),
            SizedBox(height: 60*ScaleUtils.verticalScale,),
            Text(widget.callModel.callerName,
              style: TextStyle(
                  color: UniversalVariables.appThemeColor,
                  fontSize: 30*ScaleUtils.scaleFactor,
                  fontWeight: FontWeight.bold
              ),
            ),
            Text(callerEmail,
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 16*ScaleUtils.scaleFactor
              ),
            ),
            SizedBox(height: 30*ScaleUtils.verticalScale,),
            CircleAvatar(
              radius: 75*ScaleUtils.scaleFactor,
              child: CircleAvatar(
                radius: 70*ScaleUtils.scaleFactor,
                backgroundColor: Colors.transparent,
                backgroundImage: AssetImage('assets/user.jpg'),
                foregroundImage: NetworkImage(widget.callModel.callerPic),
              ),
            ),
            Spacer(),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20*ScaleUtils.scaleFactor),
                color: HexColor("3957ED"),
              ),
              child:
              Padding(
                padding:  EdgeInsets.fromLTRB(18*ScaleUtils.horizontalScale,10*ScaleUtils.verticalScale,18*ScaleUtils.horizontalScale,10*ScaleUtils.verticalScale),
                child: Text(
                  "Chat with ${widget.callModel.callerName}",
                  style: TextStyle(fontSize:16*ScaleUtils.scaleFactor,color: Colors.white),
                ),
              ),
            ),
            InkWell(
              onTap: (){
                // Caller's profile still loading (or gone): nothing to open yet.
                if (callerModel == null) return;
                _ringTimer?.cancel();
                isCallMissed = false;
                addToLocalStorage(callStatus: "received");
                callMethods.endCall(callModel: widget.callModel);
                Navigator.push(context, MaterialPageRoute(builder: (context)=> ChatScreen(receiver: callerModel!)));
              },
              child: Padding(
                padding:  EdgeInsets.all(8.0*ScaleUtils.scaleFactor),
                child: Container(
                  height: 56*ScaleUtils.verticalScale,
                  width: 56*ScaleUtils.horizontalScale,
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: UniversalVariables.appThemeColor
                  ),
                  child: Icon(Icons.chat,color: Colors.white,size: 30,),
                ),
              ),
            ),
            Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                InkWell(
                  onTap: (){
                    _ringTimer?.cancel();
                    isCallMissed = false;
                    addToLocalStorage(callStatus: "received");
                    callMethods.endCall(callModel: widget.callModel);
                  },
                  child: Container(
                    height: 70*ScaleUtils.verticalScale,
                    width: 70*ScaleUtils.horizontalScale,
                    decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white
                    ),
                    child: Icon(Icons.call_end,color: Colors.red,size: 36,),
                  ),
                ),
                InkWell(
                  onTap: (){
                    _ringTimer?.cancel();
                    isCallMissed = false;
                    addToLocalStorage(callStatus: "received");
                    // Tells the caller (and the server rules) this call is live.
                    callMethods.markAccepted(callModel: widget.callModel);
                    if(widget.callModel.callType=="videoCall"){
                      Navigator.push(context, MaterialPageRoute(builder: (context) => CallScreen(callModel: widget.callModel,),),);
                    }else if(widget.callModel.callType=="audioCall"){
                    Navigator.push(context, MaterialPageRoute(builder: (context) => AudioCallScreen(callModel: widget.callModel,),),);
                    }
                  },
                  child: Container(
                    height: 70*ScaleUtils.verticalScale,
                    width: 70*ScaleUtils.horizontalScale,
                    decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white
                    ),
                    child: Icon(Icons.call,color: Colors.green,size: 36,),
                  ),
                ),
              ],
            ),
            Spacer()
          ],
        ),
      ),
    );
      // Scaffold(
      //   body: Container(
      //     alignment: Alignment.center,
      //     padding: EdgeInsets.symmetric(vertical: 100),
      //     child: Column(
      //       mainAxisAlignment: MainAxisAlignment.center,
      //       children: [
      //         Text('Incoming...', style: TextStyle(fontSize: 30),),
      //         SizedBox(height: 50),
      //         CachedChatImage(imageUrl: widget.callModel.callerPic,
      //           height: 100,
      //           width: 100,
      //           radius: 10,
      //           isRound: false,
      //           fit: BoxFit.cover,),
      //         Text(widget.callModel.callerName,
      //           style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),),
      //         SizedBox(height: 75),
      //         Row(
      //           mainAxisAlignment: MainAxisAlignment.center,
      //           children: [
      //             Container(
      //               decoration: BoxDecoration(
      //                   color: Colors.black,
      //                   shape: BoxShape.circle
      //               ),
      //               child: IconButton(
      //                   icon: Icon(Icons.call_end, size: 40,),
      //                   color: Colors.redAccent,
      //                   onPressed: () {
      //                       isCallMissed = false;
      //                     addToLocalStorage(callStatus: "received");
      //                     callMethods.endCall(callModel: widget.callModel);
      //                   }),
      //             ),
      //             SizedBox(width: 50),
      //             Container(
      //               decoration: BoxDecoration(
      //                   color: Colors.black,
      //                   shape: BoxShape.circle
      //               ),
      //               child: IconButton(
      //                   icon: Icon(Icons.call, size: 40,),
      //                   color: Colors.green,
      //                   onPressed: () {
      //                       isCallMissed = false;
      //                     addToLocalStorage(callStatus: "received");
      //                       if(widget.callModel.callType=="videoCall"){
      //                         Navigator.push(context, MaterialPageRoute(
      //                           builder: (context) => CallScreen(callModel: widget.callModel,),),);
      //                       }else if(widget.callModel.callType=="audioCall"){
      //                       Navigator.push(context, MaterialPageRoute(
      //                       builder: (context) => AudioCallScreen(callModel: widget.callModel,),),);
      //                       }
      //                   }),
      //             ),
      //           ],
      //         )
      //       ],
      //     ),
      //   ),
      // );
  }
}
