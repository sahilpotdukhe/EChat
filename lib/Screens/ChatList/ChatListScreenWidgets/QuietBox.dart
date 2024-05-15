import 'package:echat/Screens/SearchScreen.dart';
import 'package:echat/Utils/ScreenDimensions.dart';
import 'package:echat/Utils/UniversalVariables.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

class QuietBox extends StatelessWidget {
  final screen;
  const QuietBox({super.key, this.screen});

  @override
  Widget build(BuildContext context) {
    ScaleUtils.init(context);
    return Center(
      child: SingleChildScrollView(
        child: Center(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 30*ScaleUtils.horizontalScale),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(50*ScaleUtils.scaleFactor),
                color: Colors.white,
              ),
              padding: EdgeInsets.symmetric(vertical: 25*ScaleUtils.verticalScale, horizontal: 25*ScaleUtils.horizontalScale),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  (screen == "ChatScreen")?Image.asset('assets/nomessage.png'):Image.asset("assets/logs.png"),
                  Text((screen =="ChatScreen")?
                    "No Conversations":"All the logs will be displayed here",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 25*ScaleUtils.scaleFactor),
                  ),
                  SizedBox(height: 10*ScaleUtils.verticalScale),
                  Text((screen =="ChatScreen")?
                    "Search for your family and friends to start calling or chatting with them":"Have a video call with your family and friends to get engage",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.normal,
                        fontSize: 16*ScaleUtils.scaleFactor),
                  ),
                  SizedBox(height: 25*ScaleUtils.verticalScale),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: UniversalVariables.appThemeColor),
                    child: Text((screen =="ChatScreen")?'Find Friends':'Call Friends',style: TextStyle(color: Colors.white,fontSize: 16*ScaleUtils.scaleFactor),),
                    onPressed: (){
                      Navigator.push(context, MaterialPageRoute(builder: (context)=> SearchScreen()));
                    },
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
