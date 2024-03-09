import 'package:echat/Models/CallLogModel.dart';
import 'package:echat/Models/UserModel.dart';
import 'package:echat/Resources/AuthMethods.dart';
import 'package:echat/Resources/CallMethods.dart';
import 'package:echat/Models/CallModel.dart';
import 'package:echat/Resources/Repository/LogRepository.dart';
import 'package:echat/Screens/Call/CallScreen.dart';
import 'package:echat/Screens/Call/AudioCallScreen.dart';
import 'package:echat/Screens/ChatScreen/ChatScreen.dart';
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
  }

  getUser() async{
      callerModel = await authMethods.getUserDetailsById(widget.callModel.callerId);
     setState(() {
       callerEmail = callerModel!.email;
     });
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    if(isCallMissed){
      addToLocalStorage(callStatus: "missed");
    }
  }


  @override
  Widget build(BuildContext context) {
    CallMethods callMethods = CallMethods();
    return  Scaffold(
      backgroundColor: UniversalVariables.blackColor,
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text("Incoming call",
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 18
                ),
              ),
            ),
            SizedBox(height: 60,),
            Text(widget.callModel.callerName,
              style: TextStyle(
                  color: UniversalVariables.appThemeColor,
                  fontSize: 30,
                  fontWeight: FontWeight.bold
              ),
            ),
            Text(callerEmail,
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 16
              ),
            ),
            SizedBox(height: 30,),
            CircleAvatar(
              radius: 75,
              child: CircleAvatar(
                radius: 70,
                backgroundColor: Colors.transparent,
                backgroundImage: AssetImage('assets/user.jpg'),
                foregroundImage: NetworkImage(widget.callModel.callerPic),
              ),
            ),
            Spacer(),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: HexColor("3957ED"),
              ),
              child:
              Padding(
                padding: const EdgeInsets.fromLTRB(18,10,18,10),
                child: Text(
                  "Chat with ${widget.callModel.callerName}",
                  style: TextStyle(fontSize:16,color: Colors.white),
                ),
              ),
            ),
            InkWell(
              onTap: (){
                isCallMissed = false;
                addToLocalStorage(callStatus: "received");
                callMethods.endCall(callModel: widget.callModel);
                Navigator.push(context, MaterialPageRoute(builder: (context)=> ChatScreen(receiver: callerModel!)));
              },
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Container(
                  height: 56,
                  width: 56,
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
                    isCallMissed = false;
                    addToLocalStorage(callStatus: "received");
                    callMethods.endCall(callModel: widget.callModel);
                  },
                  child: Container(
                    height: 70,
                    width: 70,
                    decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white
                    ),
                    child: Icon(Icons.call_end,color: Colors.red,size: 36,),
                  ),
                ),
                InkWell(
                  onTap: (){
                    isCallMissed = false;
                    addToLocalStorage(callStatus: "received");
                    if(widget.callModel.callType=="videoCall"){
                      Navigator.push(context, MaterialPageRoute(builder: (context) => CallScreen(callModel: widget.callModel,),),);
                    }else if(widget.callModel.callType=="audioCall"){
                    Navigator.push(context, MaterialPageRoute(builder: (context) => AudioCallScreen(callModel: widget.callModel,),),);
                    }
                  },
                  child: Container(
                    height: 70,
                    width: 70,
                    decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white
                    ),
                    child: Icon(Icons.call,color: Colors.green,size: 36,),
                  ),
                ),
              ],
            ),
            SizedBox(height: 100,),
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
