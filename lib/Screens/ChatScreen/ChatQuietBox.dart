import 'package:echat/Utils/ScreenDimensions.dart';
import 'package:echat/Utils/UniversalVariables.dart';
import 'package:flutter/material.dart';

class ChatQuietBox extends StatelessWidget {
  final screen;
  const ChatQuietBox({super.key, this.screen});

  @override
  Widget build(BuildContext context) {
    ScaleUtils.init(context);
    return ListView(
      children: [
        SizedBox(height: 70*ScaleUtils.verticalScale,),
        Center(
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
                  (screen=="ChatScreen")?Image.asset('assets/chatscreen.png'):Image.asset('assets/search.jpg'),
                  Text(
                    (screen=="ChatScreen")?"No Message":"Search",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 25*ScaleUtils.scaleFactor),
                  ),
                  SizedBox(height: 10*ScaleUtils.verticalScale),
                  Text(
                    (screen=="ChatScreen")?"Transform silence into connection,\nExplore video calls, voice calls, image and video sharing, and more."
                        :"Discover, connect, and chat with friends and family,Search for connections, and let the conversations begin.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.normal,
                        fontSize: 15*ScaleUtils.scaleFactor),
                  ),
                  SizedBox(height: 25*ScaleUtils.verticalScale),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: UniversalVariables.appThemeColor),
                    child: Text((screen=="ChatScreen")?'Message':'Search',style: TextStyle(color: Colors.white),),
                    onPressed: (){
                      // Navigator.push(context, MaterialPageRoute(builder: (context)=> SearchScreen()));
                    },
                  )
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
