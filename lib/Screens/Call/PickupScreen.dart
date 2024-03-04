import 'package:echat/Models/CallLogModel.dart';
import 'package:echat/Resources/CallMethods.dart';
import 'package:echat/Models/CallModel.dart';
import 'package:echat/Resources/Repository/LogRepository.dart';
import 'package:echat/Screens/Call/CallScreen.dart';
import 'package:echat/Screens/Call/PickupLayout.dart';
import 'package:echat/Screens/Call/AudioCallScreen.dart';
import 'package:echat/Widgets/CachedChatImage.dart';
import 'package:flutter/material.dart';

class PickupScreen extends StatefulWidget {
  final CallModel callModel;

  const PickupScreen({super.key, required this.callModel});

  @override
  State<PickupScreen> createState() => _PickupScreenState();
}

class _PickupScreenState extends State<PickupScreen> {
  bool isCallMissed = true;

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
        body: Container(
          alignment: Alignment.center,
          padding: EdgeInsets.symmetric(vertical: 100),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Incoming...', style: TextStyle(fontSize: 30),),
              SizedBox(height: 50),
              CachedChatImage(imageUrl: widget.callModel.callerPic,
                height: 100,
                width: 100,
                radius: 10,
                isRound: false,
                fit: BoxFit.cover,),
              Text(widget.callModel.callerName,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),),
              SizedBox(height: 75),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    decoration: BoxDecoration(
                        color: Colors.black,
                        shape: BoxShape.circle
                    ),
                    child: IconButton(
                        icon: Icon(Icons.call_end, size: 40,),
                        color: Colors.redAccent,
                        onPressed: () {
                            isCallMissed = false;
                          addToLocalStorage(callStatus: "received");
                          callMethods.endCall(callModel: widget.callModel);
                        }),
                  ),
                  SizedBox(width: 50),
                  Container(
                    decoration: BoxDecoration(
                        color: Colors.black,
                        shape: BoxShape.circle
                    ),
                    child: IconButton(
                        icon: Icon(Icons.call, size: 40,),
                        color: Colors.green,
                        onPressed: () {
                            isCallMissed = false;
                          addToLocalStorage(callStatus: "received");
                            if(widget.callModel.callType=="videoCall"){
                              Navigator.push(context, MaterialPageRoute(
                                builder: (context) => CallScreen(callModel: widget.callModel,),),);
                            }else if(widget.callModel.callType=="audioCall"){
                            Navigator.push(context, MaterialPageRoute(
                            builder: (context) => AudioCallScreen(callModel: widget.callModel,),),);
                            }
                        }),
                  ),
                ],
              )
            ],
          ),
        ),
      );
  }
}
